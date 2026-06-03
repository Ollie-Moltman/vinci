import 'dart:io';
import 'package:http/http.dart' as http;

/// Progress info for one file download.
class ModelDownloadProgress {
  final String fileName;
  final int downloadedBytes;
  final int totalBytes;
  final int fileIndex; // 1-based
  final int totalFiles;

  ModelDownloadProgress({
    required this.fileName,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.fileIndex,
    required this.totalFiles,
  });

  double get fraction => totalBytes > 0 ? downloadedBytes / totalBytes : 0;
  double get overallFraction {
    final done = fileIndex - 1 + fraction;
    return done / totalFiles;
  }

  String get downloadedMB => (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
  String get totalMB => (totalBytes / (1024 * 1024)).toStringAsFixed(1);
  String get overallMB {
    final done = (fileIndex - 1) * totalBytes + downloadedBytes;
    final total = totalFiles * totalBytes;
    return '${(done / (1024 * 1024)).toStringAsFixed(1)} / ${(total / (1024 * 1024)).toStringAsFixed(1)}';
  }
}

/// Streams download of MobileCLIP TFLite model files from HuggingFace.
/// Uses HTTP range requests for progress tracking and streams to disk.
class ModelDownloadService {
  /// URLs for MobileCLIP-S2 TFLite models from plainhub mirror.
  static const modelFiles = [
    (
      name: 'mobileclip_s2_image.tflite',
      url:
          'https://huggingface.co/plainhub/mobileclip-s2-tflite/resolve/main/mobileclip_s2_image.tflite',
      size: 144120668,
    ),
    (
      name: 'mobileclip_s2_text.tflite',
      url:
          'https://huggingface.co/plainhub/mobileclip-s2-tflite/resolve/main/mobileclip_s2_text.tflite',
      size: 253874828,
    ),
  ];

  final String _targetDir;

  ModelDownloadService(this._targetDir);

  /// Stream-download all model files, reporting progress via callback.
  /// Throws on any download failure.
  Future<void> downloadAll({
    required void Function(ModelDownloadProgress) onProgress,
  }) async {
    for (var i = 0; i < modelFiles.length; i++) {
      final file = modelFiles[i];
      final destPath = '$_targetDir/${file.name}';

      // Skip if already exists with correct size
      final destFile = File(destPath);
      if (await destFile.exists()) {
        final stat = await destFile.stat();
        if (stat.size == file.size) {
          onProgress(ModelDownloadProgress(
            fileName: file.name,
            downloadedBytes: file.size,
            totalBytes: file.size,
            fileIndex: i + 1,
            totalFiles: modelFiles.length,
          ));
          continue;
        }
      }

      await _downloadFile(
        url: file.url,
        destPath: destPath,
        fileName: file.name,
        fileIndex: i + 1,
        totalSize: file.size,
        onProgress: onProgress,
      );
    }
  }

  Future<void> _downloadFile({
    required String url,
    required String destPath,
    required String fileName,
    required int fileIndex,
    required int totalSize,
    required void Function(ModelDownloadProgress) onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode} for $fileName');
      }

      final sink = File(destPath).openWrite();
      var received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(ModelDownloadProgress(
          fileName: fileName,
          downloadedBytes: received,
          totalBytes: totalSize,
          fileIndex: fileIndex,
          totalFiles: modelFiles.length,
        ));
      }

      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Check if all model files exist with correct sizes.
  Future<bool> modelsReady() async {
    for (final file in modelFiles) {
      final f = File('$_targetDir/${file.name}');
      if (!await f.exists()) return false;
      final stat = await f.stat();
      if (stat.size != file.size) return false;
    }
    return true;
  }

  /// Target directory where models should be stored.
  String get targetDir => _targetDir;
}