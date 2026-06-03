import 'package:flutter_riverpod/flutter_riverpod.dart';

// Minimal web-compatible providers that don't import any native-only packages
// (no tflite_flutter, photo_manager, path_provider, etc.)

final isIndexingProvider = StateProvider<bool>((ref) => false);
final indexedCountProvider = StateProvider<int>((ref) => 3); // server pre-seeded
final indexProgressProvider = StateProvider<(int, int)>((ref) => (0, 0));
final searchQueryProvider = StateProvider<String>((ref) => '');
final hasPermissionProvider = StateProvider<bool>((ref) => true); // always granted on web