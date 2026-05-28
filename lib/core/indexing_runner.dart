import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../providers/providers.dart';

/// Triggers a full library indexing pass.
Future<void> runIndexing(WidgetRef ref) async {
  final indexer = ref.read(indexerServiceProvider);
  final repo = ref.read(photoRepositoryProvider);
  final vectorStore = ref.read(vectorStoreProvider);

  // Load existing index
  await vectorStore.loadIndex();

  ref.read(isIndexingProvider.notifier).state = true;
  ref.read(indexProgressProvider.notifier).state = (0, 1);

  try {
    await indexer.indexAllPhotos(
      loadPage: (page, size) async {
        final photos = await repo.loadPhotos(page: page, size: size);
        await indexer.indexPhotos(photos.cast<AssetEntity>());
        return photos.length;
      },
      getTotal: () => repo.getTotalPhotoCount(),
      onProgress: (done, total) {
        ref.read(indexProgressProvider.notifier).state = (done, total);
        ref.read(indexedCountProvider.notifier).state = done;
      },
    );

    ref.read(lastIndexedProvider.notifier).state = DateTime.now();
  } finally {
    ref.read(isIndexingProvider.notifier).state = false;
  }
}
