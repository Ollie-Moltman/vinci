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

  /// Index a batch of photos, returns number successfully indexed.
  Future<int> indexPhotos(List<dynamic> photos) async {
    int indexed = 0;
    for (final photo in photos) {
      try {
        final file = await (photo as AssetEntity).file;
        if (file == null) continue;

        final bytes = await file.readAsBytes();
        final embedding = await _embeddingService.embedImage(bytes);

        await _vectorStore.indexPhoto(
          photoId: photo.id,
          path: file.path,
          embedding: embedding.toList(),
          createdAt: photo.createDateTime,
          location: photo.latitude != null
              ? '${photo.latitude}, ${photo.longitude}'
              : null,
        );
        indexed++;
      } catch (e) {
        // Skip problematic photos
        continue;
      }
    }
    return indexed;
  }

  /// Index all photos from the device in pages.
  /// Calls [onProgress] after each page with (indexedCount, totalCount).
  Future<void> indexAllPhotos({
    required Future<int> Function(int page, int size) loadPage,
    required Future<int> Function() getTotal,
    required void Function(int done, int total) onProgress,
  }) async {
    int page = 0;
    const size = 50;
    int total = await getTotal();

    while (true) {
      final photos = await loadPage(page, size);
      if (photos == 0) break;

      await indexPhotos(photos);
      final done = _vectorStore.indexedCount;
      onProgress(done, total);

      if (photos < size) break;
      page++;
    }

    await _vectorStore.saveIndex();
  }
}
