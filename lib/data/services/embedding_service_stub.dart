// Stub — should never be selected at runtime.
// Provided for compile-time type-checking in cases where neither
// the FFI nor web conditional branch is taken.
class EmbeddingServiceStub {
  Future<void> initialize() async {}
  Future<List<double>> embedText(String query) async => [];
  Future<List<double>> embedImage(List<int> bytes) async => [];
}