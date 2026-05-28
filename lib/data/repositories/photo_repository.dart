import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/photo_entity.dart';
import '../services/thumbnail_loader.dart';

/// Repository for accessing photos from the device's photo library.
class PhotoRepository {
  final _thumbLoader = ThumbnailLoader();

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

    final album = albums.first;
    final assets = await album.getAssetListPaged(page: page, size: size);

    final photos = <PhotoEntity>[];
    for (final asset in assets) {
      photos.add(PhotoEntity.fromAsset(asset));
    }

    return photos;
  }

  /// Get total photo count across all albums.
  Future<int> getTotalPhotoCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (albums.isEmpty) return 0;
    final allAssets = await albums.first.getAssetList();
    return allAssets.length;
  }

  /// Load a single asset by ID.
  Future<AssetEntity?> getAssetById(String id) async {
    return await AssetEntity.fromId(id);
  }
}
