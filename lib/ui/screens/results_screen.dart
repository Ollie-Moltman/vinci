import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/vinci_theme.dart';
import '../../providers/providers.dart';
import 'detail_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final String query;

  const ResultsScreen({super.key, required this.query});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    // Set search query in provider
    Future.microtask(() {
      ref.read(searchQueryProvider.notifier).state = widget.query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              VinciTheme.backgroundLight,
              VinciTheme.backgroundGradientEnd
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              VinciTheme.primary,
                              VinciTheme.primaryDark
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        '"${widget.query}"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: VinciTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Results
              Expanded(
                child: resultsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text('Error: $err',
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  data: (results) {
                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text(
                              'No results yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: VinciTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Index some photos first\nor try a different query',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: VinciTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final result = results[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  result: result,
                                  query: widget.query,
                                ),
                              ),
                            );
                          },
                          child: _ResultCard(result: result),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatefulWidget {
  final dynamic result;

  const _ResultCard({required this.result});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final photo = result.photo;
    // final path = photo.path;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 155,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0F2F8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.08 : 0.06),
              blurRadius: _hovered ? 24 : 20,
              offset: Offset(0, _hovered ? 6 : 4),
            ),
          ],
          transform:
              _hovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
        ),
        child: Row(
          children: [
            // Photo
            Expanded(
              flex: 9,
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: VinciTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  image: photo.path.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(File(photo.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photo.path.isEmpty
                    ? const Center(
                        child: Icon(Icons.photo,
                            color: VinciTheme.textSecondary, size: 40),
                      )
                    : null,
              ),
            ),

            // Icon panel
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFAFBFF),
                      Color(0xFFF5F7FC),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Share
                    _IconBtn(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () {
                        // TODO: implement share
                      },
                    ),
                    const SizedBox(height: 8),
                    // Save / Favorite
                    _IconBtn(
                      icon: result.isFavorited
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: 'Save',
                      onTap: () {
                        // TODO: implement favorite toggle
                      },
                    ),
                    const SizedBox(height: 8),
                    // View in folder / gallery
                    _IconBtn(
                      icon: Icons.folder_outlined,
                      label: 'Folder',
                      onTap: () {
                        // TODO: open in gallery app
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _active = true),
      onTapUp: (_) {
        setState(() => _active = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _active = false),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _active
              ? const LinearGradient(
                  colors: [VinciTheme.primary, VinciTheme.primaryDark],
                )
              : Colors.white,
          gradient: _active
              ? const LinearGradient(
                  colors: [VinciTheme.primary, VinciTheme.primaryDark],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: _active
                  ? Colors.transparent
                  : VinciTheme.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: 18,
          color: _active
              ? Colors.white
              : VinciTheme.textSecondary,
        ),
      ),
    );
  }
}
