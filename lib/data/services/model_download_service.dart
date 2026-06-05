import 'dart:io';
import 'package:http/http.dart' as http;

/// Progress info for one file download.
class ModelDownloadProgress {
  final String fileName;
  final int downloadedBytes; // bytes received so far for current file
  final int totalBytes;      // total size of current file
  final int fileIndex;       // 1-based
  final int totalFiles;
  /// Cumulative bytes downloaded across ALL files (for overall progress)
  final int totalDownloadedBytes;
  /// Total size of ALL files combined
  final int totalSizeBytes;

  ModelDownloadProgress({
    required this.fileName,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.fileIndex,
    required this.totalFiles,
    required this.totalDownloadedBytes,
    required this.totalSizeBytes,
  });

  /// Fraction complete for CURRENT file (0.0 to 1.0)
  double get fileFraction =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0;

  /// Overall fraction across ALL files (0.0 to 1.0)
  double get overallFraction =>
      totalSizeBytes > 0 ? totalDownloadedBytes / totalSizeBytes : 0;

  /// Current file MB received
  String get downloadedMB =>
      (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);

  /// Current file total MB
  String get totalMB =>
      (totalBytes / (1024 * 1024)).toStringAsFixed(1);

  /// Cumulative MB downloaded (all files so far)
  String get overallDownloadedMB =>
      (totalDownloadedBytes / (1024 * 1024)).toStringAsFixed(1);

  /// Total MB across all files
  String get overallTotalMB =>
      (totalSizeBytes / (1024 * 1024)).toStringAsFixed(1);

  /// Overall percentage as integer string
  String get overallPercent =>
      (overallFraction * 100).toStringAsFixed(0);
}

/// Streams download of MobileCLIP TFLite model files from GitHub releases.
/// Uses HTTP streaming to disk.
class ModelDownloadService {
  /// URLs for MobileCLIP-S2 TFLite models from GitHub releases.
  static const modelFiles = [
    (
      name: 'mobileclip_s2_image.tflite',
      url:
          'https://github.com/Ollie-Moltman/vinci/releases/download/v1.0.2/mobileclip_s2_image.tflite',
      size: 396881784,
    ),
    (
      name: 'mobileclip_s2_text.tflite',
      url:
          'https://github.com/Ollie-Moltman/vinci/releases/download/v1.0.2/mobileclip_s2_text.tflite',
      size: 396881784,
    ),
  ];

  final String _targetDir;

  ModelDownloadService(this._targetDir);

  /// Stream-download all model files, reporting progress via callback.
  /// Throws on any download failure.
  Future<void> downloadAll({
    required void Function(ModelDownloadProgress) onProgress,
  }) async {
    // Ensure the target directory exists before downloading
    final dir = Directory(_targetDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Precompute total size across all files
    int totalSizeAll = 0;
    for (final f in modelFiles) {
      totalSizeAll += f.size;
    }

    for (var i = 0; i < modelFiles.length; i++) {
      final file = modelFiles[i];
      final destPath = '$_targetDir/${file.name}';

      // Skip if already exists with correct size
      final destFile = File(destPath);
      if (await destFile.exists()) {
        final stat = await destFile.stat();
        if (stat.size == file.size) {
          // Report skipped file as already complete
          int skipCumulative = 0;
          for (var j = 0; j <= i; j++) skipCumulative += modelFiles[j].size;
          onProgress(ModelDownloadProgress(
            fileName: file.name,
            downloadedBytes: file.size,
            totalBytes: file.size,
            fileIndex: i + 1,
            totalFiles: modelFiles.length,
            totalDownloadedBytes: skipCumulative,
            totalSizeBytes: totalSizeAll,
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
        totalSizeAll: totalSizeAll,
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
    required int totalSizeAll,
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
          totalDownloadedBytes: (fileIndex - 1) * totalSize + received,
          totalSizeBytes: totalSizeAll,
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
