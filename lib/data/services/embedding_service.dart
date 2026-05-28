import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

/// MobileCLIP-based embedding service using TFLite.
///
/// Embeds images and text into a shared 512-dim vector space.
/// Cosine similarity between text embedding and image embedding = match score.
class EmbeddingService {
  Interpreter? _imageInterpreter;
  Interpreter? _textInterpreter;
  bool _isInitialized = false;

  static const int _embeddingDim = 512;

  /// Initialize the TFLite interpreters from assets.
  /// Falls back gracefully if model files are not yet present.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _imageInterpreter = await tflite_flutter.createInterpreter(
        'assets/models/mobileclip_image_embedding.tflite',
      );
      _imageInterpreter?.invoke();

      _textInterpreter = await tflite_flutter.createInterpreter(
        'assets/models/mobileclip_text_embedding.tflite',
      );
      _textInterpreter?.invoke();

      _isInitialized = true;
    } catch (e) {
      // Models not yet downloaded — stay in prototype mode
      _isInitialized = false;
    }
  }

  /// Generate a text embedding for a search query.
  Future<Float32List> embedText(String query) async {
    if (_isInitialized && _textInterpreter != null) {
      return _runTextEmbedding(query);
    }
    // Prototype fallback — deterministic from text hash
    return _fakeEmbedding(query.hashCode);
  }

  /// Generate an image embedding from raw image bytes (JPEG/PNG).
  Future<Float32List> embedImage(Uint8List imageBytes) async {
    if (_isInitialized && _imageInterpreter != null) {
      return _runImageEmbedding(imageBytes);
    }
    // Prototype fallback — deterministic from image size
    return _fakeEmbedding(imageBytes.length);
  }

  // -------------------------------------------------------------------------
  // Real inference paths
  // -------------------------------------------------------------------------

  Float32List _runTextEmbedding(String text) {
    // Tokenize text → run through text encoder TFLite model
    // Output: Float32List[512]
    final input = _tokenize(text);
    final output = Float32List(_embeddingDim);

    _textInterpreter?.run(input, output);
    _normalize(output);
    return output;
  }

  Float32List _runImageEmbedding(Uint8List bytes) {
    // Decode image → resize to model input (e.g. 224x224) → normalize
    // Run through image encoder TFLite model
    // Output: Float32List[512]
    final image = img.decodeImage(bytes);
    if (image == null) return _fakeEmbedding(bytes.length);

    final resized = img.copyResize(image, width: 224, height: 224);
    final input = _prepareImageInput(resized);
    final output = Float32List(_embeddingDim);

    _imageInterpreter?.run(input, output);
    _normalize(output);
    return output;
  }

  /// Simple word-level tokenization + embedding lookup.
  /// In production: use proper MobileCLIP tokenizer (SVG character-level).
  List<List<double>> _tokenize(String text) {
    final words = text.toLowerCase().split(RegExp(r'\\s+'));
    // Create a sequence of int IDs from word hash (deterministic)
    // Shape for TFLite: [1, seq_len]
    final seqLen = 16;
    final ids = List.generate(seqLen, (i) {
      if (i < words.length) {
        return (words[i].hashCode.abs() % 30000).toDouble();
      }
      return 0.0;
    });
    return [ids];
  }

  /// Convert decoded image to NCHW Float32 tensor.
  List<List<List<List<double>>>> _prepareImageInput(img.Image image) {
    // Shape: [1, 3, 224, 224]
    final input = List.generate(
      1,
      (_) => List.generate(
        3,
        (_) => List.generate(
          224,
          (_) => List.generate(224, (_) => 0.0),
        ),
      ),
    );

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final px = image.getPixel(x, y);
        input[0][0][y][x] = px.r / 255.0;
        input[0][1][y][x] = px.g / 255.0;
        input[0][2][y][x] = px.b / 255.0;
      }
    }
    return input;
  }

  void _normalize(Float32List vec) {
    double norm = 0;
    for (var i = 0; i < vec.length; i++) {
      norm += vec[i] * vec[i];
    }
    norm = math.sqrt(norm);
    if (norm > 0) {
      for (var i = 0; i < vec.length; i++) {
        vec[i] /= norm;
      }
    }
  }

  /// Deterministic fallback embedding — for use before model files are downloaded.
  Float32List _fakeEmbedding(int seed) {
    final rng = math.Random(seed.toUnsigned(32));
    final vec = Float32List(_embeddingDim);
    for (var i = 0; i < _embeddingDim; i++) {
      vec[i] = (rng.nextDouble() * 2) - 1;
    }
    _normalize(vec);
    return vec;
  }

  /// Compute cosine similarity between two normalized embeddings.
  double cosineSimilarity(Float32List a, Float32List b) {
    double dot = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}
