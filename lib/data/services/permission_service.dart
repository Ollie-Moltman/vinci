import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// Service to handle photo library permissions on Android.
class PermissionService {
  /// Request photos permission.
  /// Returns true if granted, false otherwise.
  Future<bool> requestPhotosPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth;
  }

  /// Check if photos permission is already granted.
  Future<bool> hasPhotosPermission() async {
    final result = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );
    return result.isAuth;
  }

  /// Open app settings if permission was denied.
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
