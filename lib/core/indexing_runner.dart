import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/providers.dart';
import '../data/services/vector_store.dart';
import '../data/services/embedding_service.dart';
import '../data/services/indexer_service.dart';
import '../data/repositories/photo_repository.dart';

/// Run a full library indexing pass, updating Riverpod state as we go.
Future<void> runIndexing(WidgetRef ref) async {
  final embeddingService = ref.read(embeddingServiceProvider);
  final vectorStore = ref.read(vectorStoreProvider);
  final photoRepo = ref.read(photoRepositoryProvider);

  // Initialize vectors — load existing index from disk
  await vectorStore.loadIndex();

  // If we already have photos indexed, don't re-index from scratch
  if (vectorStore.indexedCount > 0) {
    ref.read(indexedCountProvider.notifier).state = vectorStore.indexedCount;
    return;
  }

  ref.read(isIndexingProvider.notifier).state = true;
  ref.read(indexProgressProvider.notifier).state = (0, 1);

  try {
    final indexer = IndexerService(embeddingService, vectorStore);
    final total = await photoRepo.getTotalPhotoCount();
    ref.read(indexProgressProvider.notifier).state = (0, total);

    int page = 0;
    const size = 50;

    while (true) {
      final photos = await photoRepo.loadPhotos(page: page, size: size);
      if (photos.isEmpty) break;

      await indexer.indexPhotos(photos);
      final done = vectorStore.indexedCount;
      ref.read(indexProgressProvider.notifier).state = (done, total);
      ref.read(indexedCountProvider.notifier).state = done;

      if (photos.length < size) break;
      page++;
    }

    // Persist to disk
    await vectorStore.saveIndex();
    ref.read(lastIndexedProvider.notifier).state = DateTime.now();
  } finally {
    ref.read(isIndexingProvider.notifier).state = false;
  }
}

/// Load persisted index state on app startup (call once at app launch).
Future<void> loadPersistedState(WidgetRef ref) async {
  final vectorStore = ref.read(vectorStoreProvider);
  await vectorStore.loadIndex();

  if (vectorStore.indexedCount > 0) {
    ref.read(indexedCountProvider.notifier).state = vectorStore.indexedCount;
  }
}
