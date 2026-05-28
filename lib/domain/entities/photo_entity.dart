/// Entity representing a photo on the device.
class PhotoEntity {
  final String id;
  final String path;
  final DateTime createdAt;
  final int width;
  final int height;
  final String? location;

  PhotoEntity({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.width,
    required this.height,
    this.location,
  });

  factory PhotoEntity.fromAsset(dynamic asset) {
    return PhotoEntity(
      id: asset.id,
      path: '',
      createdAt: asset.createDateTime,
      width: asset.width,
      height: asset.height,
      location: asset.latitude != null
          ? '${asset.latitude}, ${asset.longitude}'
          : null,
    );
  }

  PhotoEntity copyWith({
    String? id,
    String? path,
    DateTime? createdAt,
    int? width,
    int? height,
    String? location,
  }) {
    return PhotoEntity(
      id: id ?? this.id,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
      location: location ?? this.location,
    );
  }
}
