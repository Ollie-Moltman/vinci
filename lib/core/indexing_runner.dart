import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../providers/providers.dart';
import '../data/services/vector_store.dart';
import '../data/services/embedding_service.dart';
import '../data/services/indexer_service.dart';
import '../data/repositories/photo_repository.dart';

/// Error holder so indexing failures surface to the UI.
final indexingErrorProvider = StateProvider<String?>((ref) => null);

/// Run a full library indexing pass, updating Riverpod state as we go.
/// Uses a stream-based approach so progress updates after every photo.
Future<void> runIndexing(WidgetRef ref) async {
  final embeddingService = ref.read(embeddingServiceProvider);
  final vectorStore = ref.read(vectorStoreProvider);
  final photoRepo = ref.read(photoRepositoryProvider);

  // Clear any previous error
  ref.read(indexingErrorProvider.notifier).state = null;

  // IMPORTANT: initialize the embedding service before indexing
  try {
    await embeddingService.initialize();
  } catch (e) {
    ref.read(indexingErrorProvider.notifier).state =
        'Failed to initialize AI model: $e';
    return;
  }

  // Load existing index from disk first
  try {
    await vectorStore.loadIndex();
  } catch (e) {
    // Corrupt index — clear it and start fresh
    await vectorStore.clearIndex();
  }

  // Skip if already indexed
  if (vectorStore.indexedCount > 0) {
    ref.read(indexedCountProvider.notifier).state = vectorStore.indexedCount;
    ref.read(lastIndexedProvider.notifier).state = DateTime.now();
    return;
  }

  ref.read(isIndexingProvider.notifier).state = true;

  try {
    final indexer = IndexerService(embeddingService, vectorStore);

    // Get total count with error handling
    int total;
    try {
      total = await photoRepo.getTotalPhotoCount();
    } catch (e) {
      ref.read(indexingErrorProvider.notifier).state =
          'Could not access photo library: $e';
      return;
    }

    if (total == 0) {
      // No photos on device — not an error, just nothing to index
      ref.read(indexProgressProvider.notifier).state = (0, 0);
      return;
    }

    ref.read(indexProgressProvider.notifier).state = (0, total);

    int page = 0;
    const size = 20;
    int runningTotal = 0;

    while (true) {
      List<AssetEntity> assets;
      try {
        assets = await photoRepo.loadAssetEntities(page: page, size: size);
      } catch (e) {
        ref.read(indexingErrorProvider.notifier).state =
            'Failed to load photos (page $page): $e';
        break;
      }

      if (assets.isEmpty) break;

      // Use stream to get per-photo progress updates
      try {
        await for (final count in indexer.indexAssetEntitiesStream(assets)) {
          runningTotal = count;
          ref.read(indexProgressProvider.notifier).state = (runningTotal, total);
          ref.read(indexedCountProvider.notifier).state = runningTotal;
        }
      } catch (e) {
        ref.read(indexingErrorProvider.notifier).state =
            'Failed to index a photo: $e';
        break;
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

  // Load index with error handling — corrupt files are cleared
  try {
    await vectorStore.loadIndex();
  } catch (e) {
    await vectorStore.clearIndex();
  }

  if (vectorStore.indexedCount > 0) {
    ref.read(indexedCountProvider.notifier).state = vectorStore.indexedCount;
  }
}