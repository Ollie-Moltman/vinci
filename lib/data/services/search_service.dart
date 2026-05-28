import '../../domain/entities/search_result.dart';
import 'embedding_service.dart';
import 'vector_store.dart';

/// High-level search service:
/// 1. Embed user text query
/// 2. Search vector store for nearest image embeddings
/// 3. Return ranked results with similarity scores
class SearchService {
  final EmbeddingService _embeddingService;
  final VectorStore _vectorStore;

  SearchService(this._embeddingService, this._vectorStore);

  /// Search for photos matching a text query.
  Future<List<SearchResult>> search(String query, {int limit = 20}) async {
    // 1. Embed the text query
    final queryEmbedding = await _embeddingService.embedText(query);

    // 2. Search vector store
    final hits = await _vectorStore.searchKnn(
      queryEmbedding.toList(),
      k: limit,
    );

    // 3. Map to SearchResult entities
    return hits.map((hit) {
      return SearchResult(
        photo: _photoFromMetadata(hit.metadata),
        similarityScore: hit.similarity,
      );
    }).toList();
  }

  dynamic _photoFromMetadata(dynamic metadata) {
    // Simple conversion from metadata to PhotoEntity
    return metadata;
  }
}
