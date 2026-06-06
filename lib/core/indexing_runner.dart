import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/providers.dart';
import '../data/services/vector_store.dart';
import '../data/services/embedding_service.dart';
import '../data/services/indexer_service.dart';
import '../data/repositories/photo_repository.dart';

/// Run a full library indexing pass, updating Riverpod state as we go.
/// Uses a stream-based approach so progress updates after every photo.
Future<void> runIndexing(WidgetRef ref) async {
  final embeddingService = ref.read(embeddingServiceProvider);
  final vectorStore = ref.read(vectorStoreProvider);
  final photoRepo = ref.read(photoRepositoryProvider);

  // IMPORTANT: initialize the embedding service before indexing
  await embeddingService.initialize();

  // Load existing index from disk first
  await vectorStore.loadIndex();

  // Skip if already indexed
  if (vectorStore.indexedCount > 0) {
    ref.read(indexedCountProvider.notifier).state = vectorStore.indexedCount;
    ref.read(lastIndexedProvider.notifier).state = DateTime.now();
    return;
  }

  ref.read(isIndexingProvider.notifier).state = true;

  try {
    final indexer = IndexerService(embeddingService, vectorStore);
    final total = await photoRepo.getTotalPhotoCount();

    if (total == 0) {
      ref.read(indexProgressProvider.notifier).state = (0, 0);
      return;
    }

    ref.read(indexProgressProvider.notifier).state = (0, total);

    int page = 0;
    const size = 20; // Smaller batches to stay responsive
    int runningTotal = 0;

    while (true) {
      final assets = await photoRepo.loadAssetEntities(page: page, size: size);
      if (assets.isEmpty) break;

      // Use stream to get per-photo progress updates
      int pageIndexed = 0;
      await for (final count in indexer.indexAssetEntitiesStream(assets)) {
        pageIndexed = count - runningTotal;
        runningTotal = count;
        ref.read(indexProgressProvider.notifier).state = (runningTotal, total);
        ref.read(indexedCountProvider.notifier).state = runningTotal;
      }

      if (assets.length < size) break;
      page++;
    }

    // Persist to disk
    await vectorStore.saveIndex();
    ref.read(lastIndexedProvider.notifier).state = DateTime.now();
  } finally {
    ref.read(isIndexingProvider.notifier).state = false;
  }
}

/// Load persisted index state on app startup.
Future<void> loadPersistedState(WidgetRef ref) async {
  final embeddingService = ref.read(embeddingServiceProvider);

  // Initialize embedding service at startup
  await embeddingService.initialize();

  final vectorStore = ref.read(vectorStoreProvider);

  // Set the index directory path before loading
  final dir = await getApplicationDocumentsDirectory();
  ref.read(indexDirProvider.notifier).state = dir.path;
  await vectorStore.loadIndex();

  if (vectorStore.indexedCount > 0) {
    ref.read(indexedCountProvider.notifier).state = vectorStore.indexedCount;
  }
}