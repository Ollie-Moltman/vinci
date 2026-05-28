import 'photo_entity.dart';

/// Entity representing a search result — a photo matched to a query.
class SearchResult {
  final PhotoEntity photo;
  final double similarityScore; // 0.0 to 1.0

  SearchResult({
    required this.photo,
    required this.similarityScore,
  });
}
