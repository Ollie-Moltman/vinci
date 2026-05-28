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
final vectorStoreProvider = Provider((ref) {
  return VectorStore('${ref.watch(indexDirProvider)}/vectors');
});
final searchServiceProvider = Provider((ref) {
  return SearchService(
    ref.watch(embeddingServiceProvider),
    ref.watch(vectorStoreProvider),
  );
});
final indexerServiceProvider = Provider((ref) {
  return IndexerService(
    ref.watch(embeddingServiceProvider),
    ref.watch(vectorStoreProvider),
  );
});
final photoRepositoryProvider = Provider((_) => PhotoRepository());

// App state providers
final hasPermissionProvider = StateProvider<bool>((ref) => false);
final isIndexingProvider = StateProvider<bool>((ref) => false);
final indexProgressProvider = StateProvider<(int, int)>((ref) => (0, 0));
final indexedCountProvider = StateProvider<int>((ref) => 0);
final lastIndexedProvider = StateProvider<DateTime?>((ref) => null);
final indexDirProvider = Provider<String>((ref) {
  // Provided by app setup — for now placeholder
  return '/data/user/0/com.vinci.app';
});

// Search state
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final searchService = ref.read(searchServiceProvider);
  return await searchService.search(query);
});

// Auto-index toggle
final autoIndexEnabledProvider = StateProvider<bool>((ref) => true);
