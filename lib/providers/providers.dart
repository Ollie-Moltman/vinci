import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/permission_service.dart';
import '../../data/services/embedding_service.dart';
import '../../data/services/vector_store.dart';
import '../../data/services/search_service.dart';
import '../../data/services/indexer_service.dart';
import '../../data/repositories/photo_repository.dart';
import '../../domain/entities/search_result.dart';

// Services
final permissionServiceProvider = Provider((_) => PermissionService());
final embeddingServiceProvider = Provider((_) => EmbeddingService());

final vectorStoreProvider = Provider<VectorStore>((ref) {
  final dir = ref.watch(indexDirProvider);
  return VectorStore('$dir/vectors');
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(
    ref.watch(embeddingServiceProvider),
    ref.watch(vectorStoreProvider),
  );
});

final indexerServiceProvider = Provider<IndexerService>((ref) {
  return IndexerService(
    ref.watch(embeddingServiceProvider),
    ref.watch(vectorStoreProvider),
  );
});

final photoRepositoryProvider = Provider((_) => PhotoRepository());

// App state
final hasPermissionProvider = StateProvider<bool>((ref) => false);
final isIndexingProvider = StateProvider<bool>((ref) => false);
final indexProgressProvider = StateProvider<(int, int)>((ref) => (0, 0));
final indexedCountProvider = StateProvider<int>((ref) => 0);
final lastIndexedProvider = StateProvider<DateTime?>((ref) => null);
final indexDirProvider = StateProvider<String>((ref) => '');
final autoIndexEnabledProvider = StateProvider<bool>((ref) => true);

// Search
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final searchService = ref.read(searchServiceProvider);
  return await searchService.search(query);
});

// Embedding initialization
final embeddingInitializedProvider = FutureProvider<void>((ref) async {
  final svc = ref.read(embeddingServiceProvider);
  await svc.initialize();
});
