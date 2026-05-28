import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Downloads MobileCLIP TFLite model files from HuggingFace into app assets dir.
///
/// Place model files in assets/models/ before building for production.
/// This utility handles dev-time downloads for testing.
class ModelDownloader {
  // MobileCLIP-S2 on-device model — HuggingFace mirror
  // These URLs point to the raw .tflite model files
  static const _modelFiles = [
    (
      name: 'mobileclip_image_embedding.tflite',
      url:
          'https://huggingface.co/apple/MobileCLIP-S2-OpenCLIP/resolve/main/mobileclip_s2_image_embedding_INT8.tflite',
    ),
    (
      name: 'mobileclip_text_embedding.tflite',
      url:
          'https://huggingface.co/apple/MobileCLIP-S2-OpenCLIP/resolve/main/mobileclip_s2_text_embedding_INT8.tflite',
    ),
  ];

  /// Download all model files to the given directory.
  /// Returns list of downloaded file paths.
  Future<List<String>> downloadAll({
    required String toDirectory,
    void Function(String file, int downloaded, int total)? onProgress,
  }) async {
    final downloaded = <String>[];
    for (var i = 0; i < _modelFiles.length; i++) {
      final file = _modelFiles[i];
      final destPath = '$toDirectory/${file.name}';

      try {
        final response = await http.get(Uri.parse(file.url));
        if (response.statusCode == 200) {
          await File(destPath).writeAsBytes(response.bodyBytes);
          downloaded.add(destPath);
          onProgress?.call(file.name, i + 1, _modelFiles.length);
        }
      } catch (e) {
        // Continue with other files on failure
      }
    }
    return downloaded;
  }

  /// Returns where assets/models/ should be placed in the project.
  String get projectAssetsPath {
    return 'assets/models';
  }
}
