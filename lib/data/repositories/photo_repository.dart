import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/photo_entity.dart';

/// Repository for accessing photos from the device's photo library.
class PhotoRepository {
  /// Load all photos from the device, most recent first.
  Future<List<PhotoEntity>> loadPhotos({int page = 0, int size = 50}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) return [];

    // Get the "Recent" or first album
    final album = albums.first;
    final assets = await album.getAssetListPaged(page: page, size: size);

    final photos = <PhotoEntity>[];
    for (final asset in assets) {
      final file = await asset.file;
      final entity = PhotoEntity.fromAsset(asset).copyWith(
        path: file?.path ?? '',
      );
      photos.add(entity);
    }

    return photos;
  }

  /// Get total photo count across all albums.
  Future<int> getTotalPhotoCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (albums.isEmpty) return 0;
    return albums.first.assetCount;
  }
}
