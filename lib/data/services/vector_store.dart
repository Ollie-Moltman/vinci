import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Lightweight in-memory vector store backed by JSON file.
///
/// For v1: stores embeddings as JSON on disk (no native chromadb dependency needed).
/// Future: swap to chromadb package for better performance.
class VectorStore {
  final String _indexDir;
  final Map<String, List<double>> _imageEmbeddings = {};
  final Map<String, _PhotoMetadata> _metadata = {};

  /// Guard: if path is empty at construction time, throw a clear error
  /// rather than silently failing loadIndex() later.
  VectorStore(this._indexDir) {
    if (_indexDir.isEmpty) {
      throw StateError('VectorStore created with empty path — '
          'indexDirProvider was not set before provider creation. '
          'Fix: set indexDirProvider in main() before runApp().');
    }
  }

  /// Index a photo's embedding vector.
  Future<void> indexPhoto({
    required String photoId,
    required String path,
    required List<double> embedding,
    required DateTime createdAt,
    String? location,
  }) async {
    _imageEmbeddings[photoId] = embedding;
    _metadata[photoId] = _PhotoMetadata(
      photoId: photoId,
      path: path,
      createdAt: createdAt,
      location: location,
    );
  }

  /// Search for the k most similar photos to a text embedding.
  Future<List<_SearchHit>> searchKnn(List<double> queryEmbedding, {int k = 20}) async {
    final hits = <_SearchHit>[];

    for (final entry in _imageEmbeddings.entries) {
      final photoId = entry.key;
      final embedding = entry.value;
      final similarity = _cosineSimilarity(queryEmbedding, embedding);

      hits.add(_SearchHit(
        photoId: photoId,
        similarity: similarity,
        metadata: _metadata[photoId]!,
      ));
    }

    hits.sort((a, b) => b.similarity.compareTo(a.similarity));
    return hits.take(k).toList();
  }

  /// Persist index to disk.
  Future<void> saveIndex() async {
    final dir = Directory(_indexDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final data = {
      'embeddings': _imageEmbeddings.map((k, v) => MapEntry(k, v)),
      'metadata': _metadata.map((k, v) => MapEntry(k, {
        'photoId': v.photoId,
        'path': v.path,
        'createdAt': v.createdAt.toIso8601String(),
        'location': v.location,
      })),
    };

    final file = File('$_indexDir/vectors.json');
    await file.writeAsString(jsonEncode(data));
  }

  /// Load index from disk.
  Future<void> loadIndex() async {
    final file = File('$_indexDir/vectors.json');
    if (!await file.exists()) return;

    final data = jsonDecode(await file.readAsString());
    final embeddings = (data['embeddings'] as Map).cast<String, List<double>>();
    final metadata = (data['metadata'] as Map).cast<String, Map<String, dynamic>>();

    _imageEmbeddings.clear();
    _metadata.clear();

    for (final e in embeddings.entries) {
      _imageEmbeddings[e.key] = (e.value as List).map((x) => (x as num).toDouble()).toList();
    }
    for (final e in metadata.entries) {
      _metadata[e.key] = _PhotoMetadata(
        photoId: e.value['photoId'],
        path: e.value['path'],
        createdAt: DateTime.parse(e.value['createdAt']),
        location: e.value['location'],
      );
    }
  }

  /// Get how many photos are currently indexed.
  int get indexedCount => _imageEmbeddings.length;

  /// Clear all indexed data.
  Future<void> clearIndex() async {
    _imageEmbeddings.clear();
    _metadata.clear();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}

class _PhotoMetadata {
  final String photoId;
  final String path;
  final DateTime createdAt;
  final String? location;

  _PhotoMetadata({
    required this.photoId,
    required this.path,
    required this.createdAt,
    this.location,
  });
}

class _SearchHit {
  final String photoId;
  final double similarity;
  final _PhotoMetadata metadata;

  _SearchHit({
    required this.photoId,
    required this.similarity,
    required this.metadata,
  });
}
