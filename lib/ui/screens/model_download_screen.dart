import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/model_download_service.dart';

/// Full-screen download experience shown on first launch
/// while AI models are fetched from the network.
class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ModelDownloadScreen({super.key, required this.onComplete});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen>
    with SingleTickerProviderStateMixin {
  late final ModelDownloadService _downloadService;
  String _statusText = 'Initializing…';
  ModelDownloadProgress? _progress;
  String? _errorMessage;
  bool _done = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initDownload();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initDownload() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = '${appDir.path}/.vinci/models';
    _downloadService = ModelDownloadService(modelDir);

    // Check if already downloaded
    if (await _downloadService.modelsReady()) {
      setState(() {
        _statusText = 'Models ready!';
        final totalSize = ModelDownloadService.modelFiles
            .fold<int>(0, (sum, f) => sum + f.size);
        _progress = ModelDownloadProgress(
          fileName: 'All files ready',
          downloadedBytes: totalSize,
          totalBytes: totalSize,
          fileIndex: ModelDownloadService.modelFiles.length,
          totalFiles: ModelDownloadService.modelFiles.length,
          totalDownloadedBytes: totalSize,
          totalSizeBytes: totalSize,
        );
        _done = true;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      widget.onComplete();
      return;
    }

    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await _downloadService.downloadAll(onProgress: (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            _statusText = 'Downloading ${progress.fileName}';
          });
        }
      });

      if (mounted) {
        setState(() {
          _done = true;
          _statusText = 'Ready to explore!';
        });
        await Future.delayed(const Duration(milliseconds: 600));
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Download failed: ${e.toString()}\n\nPlease check your internet connection and try again.';
          _statusText = 'Download failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // App icon / logo
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'DaVinci',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Preparing your AI experience…',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),

              const Spacer(flex: 2),

              // Progress card
              if (_progress != null) ...[
                _ProgressCard(
                  progress: _progress!,
                  statusText: _statusText,
                  errorMessage: _errorMessage,
                  onRetry: _errorMessage != null ? _startDownload : null,
                ),
              ],

              const Spacer(flex: 3),

              // Bottom note
              Text(
                'Models are downloaded once · ~380 MB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[400],
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ModelDownloadProgress progress;
  final String statusText;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _ProgressCard({
    required this.progress,
    required this.statusText,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = errorMessage != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // File name + overall percent
          Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.description_outlined,
                size: 18,
                color: isError ? Colors.red[400] : Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isError ? Colors.red[400] : Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red[50]
                      : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${progress.overallPercent}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isError ? Colors.red[400] : colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Overall progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isError ? 0 : progress.overallFraction,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                isError ? Colors.red[300]! : colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // MB downloaded / total + file counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${progress.overallDownloadedMB} / ${progress.overallTotalMB} MB',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Downloaded',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'File ${progress.fileIndex} of ${progress.totalFiles}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${progress.downloadedMB} / ${progress.totalMB} MB',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Error + retry
          if (errorMessage != null) ...[
            const SizedBox(height: 20),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}