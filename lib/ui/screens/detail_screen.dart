import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/vinci_theme.dart';
import '../../data/repositories/photo_repository.dart';
import '../../domain/entities/search_result.dart';
import '../../ui/screens/results_screen.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final SearchResult result;
  final String query;

  const DetailScreen({
    super.key,
    required this.result,
    required this.query,
  });

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  Uint8List? _fullBytes;

  @override
  void initState() {
    super.initState();
    _loadFullImage();
  }

  Future<void> _loadFullImage() async {
    final asset =
        await PhotoRepository().getAssetById(widget.result.photo.id);
    if (asset != null && mounted) {
      // Load a larger thumbnail for detail view
      final bytes = await asset.thumbnailDataWithSize(
        const ThumbnailSize(1200, 1200),
        quality: 95,
      );
      if (mounted && bytes != null) {
        setState(() => _fullBytes = bytes);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _sharePhoto() async {
    final asset =
        await PhotoRepository().getAssetById(widget.result.photo.id);
    if (asset == null) return;
    final file = await asset.file;
    if (file == null) return;
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.result.photo;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: VinciTheme.backgroundMain,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    // Gradient back button
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [VinciTheme.primary, VinciTheme.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 18),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Match badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [VinciTheme.primary, VinciTheme.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(widget.result.similarityScore * 100).toInt()}% match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        widget.result.isFavorited
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.result.isFavorited
                            ? Colors.red
                            : VinciTheme.textPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          widget.result.isFavorited =
                              !widget.result.isFavorited;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert,
                          color: VinciTheme.textPrimary),
                      onPressed: () {
                        // TODO: more options
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Photo
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: _fullBytes != null
                                ? Image.memory(
                                    _fullBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: VinciTheme.backgroundLight,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Info panel
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: VinciTheme.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Matched Query',
                              style: TextStyle(
                                fontSize: 11,
                                color: VinciTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '"${widget.query}"',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: VinciTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 16, color: VinciTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(photo.createdAt),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: VinciTheme.textSecondary),
                                ),
                              ],
                            ),
                            if (photo.location != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: VinciTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      photo.location!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: VinciTheme.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                                child: _ActionBtn(
                                    icon: Icons.share, label: 'Share', onTap: _sharePhoto)),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: _ActionBtn(
                                    icon: Icons.add, label: 'Add to Library')),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: _ActionBtn(
                                    icon: Icons.folder, label: 'View in Gallery')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom nav
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _NavItem(
                        icon: Icons.search, label: 'Search', active: false),
                    _NavItem(
                        icon: Icons.settings, label: 'Settings', active: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionBtn(
      {required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VinciTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: VinciTheme.primary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: VinciTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: active ? VinciTheme.primary : VinciTheme.textSecondary,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? VinciTheme.primary : VinciTheme.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
