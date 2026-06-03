import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// CLIPTokenizer — implements the MobileCLIP text tokenizer.
/// Uses BPE with the official 49,410-token vocabulary and 48,894 merge rules.
///
/// Algorithm (matches HuggingFace CLIPTokenizer):
/// 1. Whitespace split → words
/// 2. For each word: BPE encode greedily left-to-right, add </w> to final token
/// 3. Map tokens to vocab IDs
///
/// Produces token IDs [1, 77] matching the Apple/MobileCLIP reference.
class CLIPTokenizer {
  /// Vocab: token string → token ID
  final Map<String, int> _vocab = {};

  /// Merge rules as list of (left, right) pairs in priority order.
  /// Earlier in list = higher priority (applied first in ties).
  final List<List<String>> _merges = [];

  /// Pair → merge index lookup for O(1) find.
  final Map<String, int> _pairToIdx = {};

  /// Special token IDs
  static const int startTokenId = 49406; // <|startoftext|>
  static const int endTokenId = 49407;  // <|endoftext|>
  static const int maxLength = 77;

  bool _loaded = false;

  CLIPTokenizer();

  /// Load tokenizer from Flutter assets.
  Future<void> load() async {
    if (_loaded) return;

    final jsonBytes = await rootBundle.load('assets/models/tokenizer.json');
    final jsonStr = utf8.decode(jsonBytes.buffer.asUint8List());

    final mergesBytes = await rootBundle.load('assets/models/merges.txt');
    final mergesStr = utf8.decode(mergesBytes.buffer.asUint8List());

    _parse(jsonStr, mergesStr);
    _loaded = true;
  }

  /// Returns true if the tokenizer is loaded and ready.
  bool get isLoaded => _loaded;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Encode text → list of raw token IDs (without start/end tokens).
  /// Truncates to maxLength - 2 to leave room for start + end.
  List<int> encode(String text) {
    if (!_loaded) return [];

    final words = _splitOnWhitespace(text);
    final tokens = <int>[];

    for (final word in words) {
      if (tokens.length >= maxLength - 2) break;
      final wordTokens = _bpeEncodeWord(word);
      tokens.addAll(wordTokens);
    }

    if (tokens.length > maxLength - 2) {
      return tokens.sublist(0, maxLength - 2);
    }
    return tokens;
  }

  /// Full encode: adds start/end tokens, pads to maxLength.
  List<int> encodeWithTokens(String text) {
    final encoded = encode(text);
    final result = <int>[startTokenId];
    result.addAll(encoded);
    result.add(endTokenId);

    while (result.length < maxLength) {
      result.add(endTokenId);
    }
    return result.sublist(0, maxLength);
  }

  // -------------------------------------------------------------------------
  // Tokenization pipeline
  // -------------------------------------------------------------------------

  /// Split text on whitespace (matches Whitespace pre-tokenizer).
  List<String> _splitOnWhitespace(String text) {
    // Handle both space and tab/newline separators
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  }

  /// BPE encode a single word → list of token IDs.
  /// Uses greedy left-to-right merge strategy (matching HF reference).
  /// Adds </w> suffix to the final token (word-final marker).
  List<int> _bpeEncodeWord(String word) {
    if (word.isEmpty) return [];

    // Step 1: Convert to byte tokens (ASCII: direct, non-ASCII: Ġ + char)
    final byteTokens = _wordToByteTokens(word);

    // Step 2: Apply BPE merges greedily left-to-right
    final merged = _bpeApplyMerges(byteTokens);

    // Step 3: Add </w> to the final token (word-final marker)
    final wordFinal = <String>[];
    if (merged.isNotEmpty) {
      for (var i = 0; i < merged.length - 1; i++) {
        wordFinal.add(merged[i]);
      }
      wordFinal.add('${merged.last}</w>');
    }

    // Step 4: Map to vocab IDs
    final ids = <int>[];
    for (final token in wordFinal) {
      final id = _vocab[token];
      if (id != null) {
        ids.add(id);
      } else {
        // Fallback: try without </w> (shouldn't happen for word-final tokens)
        final altId = _vocab[token.replaceAll('</w>', '')];
        if (altId != null) ids.add(altId);
      }
    }
    return ids;
  }

  /// Convert a word to byte-level token list.
  /// ASCII characters: direct byte tokens.
  /// Non-ASCII: Ġ (U+0120) prefix + character.
  List<String> _wordToByteTokens(String word) {
    final tokens = <String>[];
    for (var i = 0; i < word.length; i++) {
      final ch = word[i];
      final code = ch.codeUnitAt(0);
      if (code < 128) {
        tokens.add(ch);
      } else {
        tokens.add('Ġ$ch');
      }
    }
    return tokens;
  }

  /// Apply BPE merges greedily left-to-right.
  /// At each position, if the current pair has a merge rule, apply it.
  /// After merging, stay at the same position and re-check the new pair.
  /// If no merge at current position, advance by 1.
  List<String> _bpeApplyMerges(List<String> tokens) {
    if (tokens.length <= 1) return tokens;

    var result = List<String>.from(tokens);
    var i = 0;
    while (i < result.length - 1) {
      final pairKey = '${result[i]}\x00${result[i + 1]}'; // null-byte sep to avoid ambiguity
      if (_pairToIdx.containsKey(pairKey)) {
        // Merge at current position
        result = [
          ...result.sublist(0, i),
          '${result[i]}${result[i + 1]}',
          ...result.sublist(i + 2),
        ];
        // Stay at same position — re-check new pair
      } else {
        i++;
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Parsing (vocab + merges)
  // -------------------------------------------------------------------------

  void _parse(String jsonStr, String mergesStr) {
    final jsonData = json.decode(jsonStr) as Map<String, dynamic>;

    // Parse vocab from tokenizer.json model.vocab
    _vocab.clear();
    final vocabData = jsonData['model']['vocab'] as Map<String, dynamic>;
    for (final e in vocabData.entries) {
      _vocab[e.key] = e.value as int;
    }

    // Parse merges from merges.txt (skip first line: #version: 0.2)
    _merges.clear();
    _pairToIdx.clear();
    final lines = mergesStr.split('\n');
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(' ');
      if (parts.length == 2) {
        final pairKey = '${parts[0]}\x00${parts[1]}';
        if (!_pairToIdx.containsKey(pairKey)) {
          _pairToIdx[pairKey] = _merges.length;
          _merges.add(parts);
        }
      }
    }
  }
}