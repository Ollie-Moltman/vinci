import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart';

/// On-device embedding service using MobileCLIP for text-image similarity.
///
/// MobileCLIP embeds both images and text into a shared vector space.
/// Cosine similarity between text embedding and image embedding = match score.
class EmbeddingService {
  static const int _embeddingDim = 512;

  /// Generate a text embedding for a search query.
  Future<Float32List> embedText(String query) async {
    // MobileCLIP text embedding
    // In production: load MobileCLIP model and run inference
    // For v1 prototype: generate deterministic fake embedding based on text hash
    // to demonstrate the search flow without requiring model files
    final hash = query.hashCode;
    final rng = math.Random(hash.toUnsigned(32));
    final embedding = Float32List(_embeddingDim);
    for (var i = 0; i < _embeddingDim; i++) {
      embedding[i] = (rng.nextDouble() * 2) - 1;
    }
    _normalize(embedding);
    return embedding;
  }

  /// Generate an image embedding from raw image bytes.
  Future<Float32List> embedImage(Uint8List imageBytes) async {
    // MobileCLIP image embedding
    // In production: decode image, resize to model input size, run through vision塔
    // For v1 prototype: generate fake embedding
    final hash = imageBytes.length;
    final rng = math.Random(hash);
    final embedding = Float32List(_embeddingDim);
    for (var i = 0; i < _embeddingDim; i++) {
      embedding[i] = (rng.nextDouble() * 2) - 1;
    }
    _normalize(embedding);
    return embedding;
  }

  /// Compute cosine similarity between two embeddings.
  double cosineSimilarity(Float32List a, Float32List b) {
    double dot = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot; // already normalized
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
}
