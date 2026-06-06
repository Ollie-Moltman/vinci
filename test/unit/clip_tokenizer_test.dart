import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinci/data/services/clip_tokenizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CLIPTokenizer tokenizer;

  setUpAll(() async {
    tokenizer = CLIPTokenizer();
    await tokenizer.load();
  });

  test('CLIPTokenizer loads successfully', () {
    expect(tokenizer.isLoaded, isTrue);
  });

  test('encodeWithTokens returns list of token IDs', () {
    final tokens = tokenizer.encodeWithTokens('hello world');
    expect(tokens, isA<List<int>>());
    expect(tokens.length, greaterThan(0));
    expect(tokens.length, lessThanOrEqualTo(77)); // max tokens
    // First token is SOT (start of text), last is EOT (end of text)
    expect(tokens[0], equals(49406)); // SOT token
  });

  test('encodeWithTokens pads to maxTokens', () {
    final tokens = tokenizer.encodeWithTokens('short');
    expect(tokens.length, equals(77)); // padded to max
    // Last non-padding token should be EOT
    final nonPadding = tokens.where((t) => t != 0).toList();
    expect(nonPadding.last, equals(49407)); // EOT token
  });

  test('encodeWithTokens is deterministic', () {
    final tokens1 = tokenizer.encodeWithTokens('test photo search');
    final tokens2 = tokenizer.encodeWithTokens('test photo search');
    expect(tokens1, equals(tokens2));
  });

  test('empty string still returns valid token list', () {
    final tokens = tokenizer.encodeWithTokens('');
    expect(tokens, isA<List<int>>());
    expect(tokens.length, equals(77));
  });
}
