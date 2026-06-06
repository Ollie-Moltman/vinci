import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinci/data/services/vector_store.dart';

void main() {
  late Directory tempDir;
  late String storePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vinci_test_');
    storePath = '${tempDir.path}/vectors';
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('VectorStore initializes and indexes a photo', () async {
    final store = VectorStore(storePath);
    await store.indexPhoto(
      photoId: 'photo1',
      path: '/test/photo1.jpg',
      embedding: [0.1, 0.2, 0.3, 0.4, 0.5],
      createdAt: DateTime.now(),
    );
    expect(store.indexedCount, 1);
  });

  test('VectorStore saves and loads index correctly', () async {
    final store1 = VectorStore(storePath);
    await store1.indexPhoto(
      photoId: 'photo1',
      path: '/test/photo1.jpg',
      embedding: [0.1, 0.2, 0.3, 0.4, 0.5],
      createdAt: DateTime.now(),
    );
    await store1.indexPhoto(
      photoId: 'photo2',
      path: '/test/photo2.jpg',
      embedding: [0.5, 0.4, 0.3, 0.2, 0.1],
      createdAt: DateTime.now(),
    );
    await store1.saveIndex();

    final store2 = VectorStore(storePath);
    await store2.loadIndex();
    expect(store2.indexedCount, 2);
  });

  test('VectorStore searchKnn returns correct top results', () async {
    final store = VectorStore(storePath);
    await store.indexPhoto(
      photoId: 'photo1',
      path: '/test/photo1.jpg',
      embedding: [1.0, 0.0, 0.0, 0.0],
      createdAt: DateTime.now(),
    );
    await store.indexPhoto(
      photoId: 'photo2',
      path: '/test/photo2.jpg',
      embedding: [0.0, 1.0, 0.0, 0.0],
      createdAt: DateTime.now(),
    );
    await store.indexPhoto(
      photoId: 'photo3',
      path: '/test/photo3.jpg',
      embedding: [0.0, 0.0, 1.0, 0.0],
      createdAt: DateTime.now(),
    );

    final results = await store.searchKnn([1.0, 0.0, 0.0, 0.0], k: 2);
    expect(results.length, 2);
    expect(results[0].photoId, 'photo1'); // closest to itself
  });

  test('VectorStore throws StateError with empty path', () {
    expect(
      () => VectorStore(''),
      throwsA(isA<StateError>()),
    );
  });
}
