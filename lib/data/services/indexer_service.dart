import 'dart:io';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'embedding_service.dart';
import 'vector_store.dart';

/// Coordinates background indexing of photos:
/// 1. Loads photos from device via PhotoRepository
/// 2. Generates embeddings via EmbeddingService
/// 3. Stores vectors in VectorStore
class IndexerService {
  final EmbeddingService _embeddingService;
  final VectorStore _vectorStore;

  IndexerService(this._embeddingService, this._vectorStore);

  /// Index assets directly (used during real indexing from photo_manager).
  /// Yields after each asset so the caller can update progress UI.
  Stream<int> indexAssetEntitiesStream(List<AssetEntity> assets) async* {
    int indexed = 0;
    for (final asset in assets) {
      try {
        final file = await asset.file;
        if (file == null) continue;

        final bytes = await file.readAsBytes();
        final embedding = await _embeddingService.embedImage(bytes);

        await _vectorStore.indexPhoto(
          photoId: asset.id,
          path: file.path,
          embedding: embedding.toList(),
          createdAt: asset.createDateTime,
          location: asset.latitude != null
              ? '${asset.latitude}, ${asset.longitude}'
              : null,
        );
        indexed++;
        yield indexed; // Yield after each photo so UI can update
      } catch (e) {
        continue;
      }
    }
  }

  /// Non-stream version for batch calls.
  Future<int> indexAssetEntities(List<AssetEntity> assets) async {
    int indexed = 0;
    await for (final count in indexAssetEntitiesStream(assets)) {
      indexed = count;
    }
    return indexed;
  }
}