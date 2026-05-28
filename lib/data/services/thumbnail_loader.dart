import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

/// Loads photo thumbnails from the device using photo_manager's AssetEntity API.
/// Works directly from AssetEntity — no file paths needed.
///
/// On Android 13+ photo_manager's getThumbnail returns a Uint8List that can be
/// loaded directly into an Image widget via MemoryImage.
class ThumbnailLoader {
  static const _thumbSize = 300;

  /// Load a thumbnail for an asset.
  /// Returns null if permission denied or asset unavailable.
  Future<Uint8List?> loadThumbnail(AssetEntity asset) async {
    return await asset.thumbnailDataWithSize(
      const ThumbnailSize(_thumbSize, _thumbSize),
      quality: 85,
    );
  }

  /// Load multiple thumbnails in batch.
  Future<Map<String, Uint8List>> loadBatch(List<AssetEntity> assets) async {
    final results = <String, Uint8List>{};
    for (final asset in assets) {
      final thumb = await loadThumbnail(asset);
      if (thumb != null) {
        results[asset.id] = thumb;
      }
    }
    return results;
  }
}
