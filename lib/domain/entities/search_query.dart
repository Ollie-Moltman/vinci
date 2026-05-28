/// Entity representing a text search query.
class SearchQuery {
  final String text;
  final DateTime createdAt;

  SearchQuery({
    required this.text,
    required this.createdAt,
  });
}
