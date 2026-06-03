import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

/// Web-compatible embedding service that calls the Vinci Test Server API.
/// This mirrors the real EmbeddingService interface but uses the HTTP API
/// instead of native TFLite. Used for Flutter Web builds.
class WebEmbeddingService {
  /// Web-compatible embedding service that calls the Vinci Test Server API.
  /// Uses relative URLs so it works both locally (port 8080) and via cloudflared tunnel.
  /// The e2e_server.py proxies /api/* -> localhost:8765/*.
  static const String _defaultBase = '';

  final String baseUrl;
  WebEmbeddingService({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBase;

  /// Embed a text query string into a 512-dim vector.
  Future<Float32List> embedText(String query) async {
    final uri = Uri.parse('$baseUrl/embed_text?q=${Uri.encodeComponent(query)}');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('embed_text failed: ${resp.body}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final vecList = (data['embedding'] as List).cast<num>();
    return Float32List.fromList(vecList.map((e) => e.toDouble()).toList());
  }

  /// Index an image from file bytes. Saves to server temp and returns embedding.
  Future<String> indexImage(Uint8List bytes, String filename) async {
    final uri = Uri.parse('$baseUrl/index_bytes');
    final b64 = base64Encode(bytes);
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': b64, 'name': filename}),
    );
    if (resp.statusCode != 200) throw Exception('index_bytes failed: ${resp.body}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// Search indexed images by text query.
  Future<List<SearchResult>> search(String query, {int topK = 10}) async {
    final uri = Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('search failed: ${resp.body}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = data['results'] as List;
    return results.map((r) => SearchResult(
      id: r['id'] as String,
      path: r['path'] as String,
      score: (r['score'] as num).toDouble(),
    )).toList();
  }

  /// Get server health / indexed count.
  Future<int> indexedCount() async {
    final resp = await http.get(Uri.parse('$baseUrl/health'));
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['images_indexed'] as int;
  }

  /// List indexed images.
  Future<List<IndexedImage>> listIndexed() async {
    final resp = await http.get(Uri.parse('$baseUrl/indexed'));
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final images = data['images'] as List;
    return images.map((img) => IndexedImage(
      id: img['id'] as String,
      path: img['path'] as String,
    )).toList();
  }

  /// Compute cosine similarity between two normalized embeddings.
  double cosineSimilarity(Float32List a, Float32List b) {
    double dot = 0;
    for (var i = 0; i < a.length; i++) dot += a[i] * b[i];
    return dot;
  }
}

class SearchResult {
  final String id;
  final String path;
  final double score;
  SearchResult({required this.id, required this.path, required this.score});
}

class IndexedImage {
  final String id;
  final String path;
  IndexedImage({required this.id, required this.path});
}