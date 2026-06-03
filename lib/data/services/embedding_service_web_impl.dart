// Stub embedding service — used only on Flutter Web where FFI packages are unavailable.
// On mobile (dart:io available), the real embedding_service.dart is used instead.
import 'dart:typed_data';

class EmbeddingService {
  Future<void> initialize() async {}
  Future<Float32List> embedText(String query) async => Float32List(512);
  Future<Float32List> embedImage(Uint8List bytes) async => Float32List(512);
  double cosineSimilarity(Float32List a, Float32List b) {
    double dot = 0;
    for (var i = 0; i < a.length; i++) dot += a[i] * b[i];
    return dot;
  }
}

class Float32List {
  final List<double> _list;
  Float32List(int length) : _list = List.filled(length, 0.0);
  double operator [](int i) => _list[i];
  void operator []=(int i, double v) { _list[i] = v; }
  int get length => _list.length;
  List<double> get list => _list;
}