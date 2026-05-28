import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/vinci_theme.dart';
import '../../core/indexing_runner.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoIndex = true;
  int _indexedCount = 0;
  String _indexSize = '0 MB';
  DateTime? _lastIndexed;

  @override
  void initState() {
    super.initState();
    // Sync providers → local state
    Future.microtask(() {
      _indexedCount = ref.read(indexedCountProvider);
      _lastIndexed = ref.read(lastIndexedProvider);
    });
  }

  void _syncFromProviders() {
    final count = ref.read(indexedCountProvider);
    final last = ref.read(lastIndexedProvider);
    setState(() {
      _indexedCount = count;
      _lastIndexed = last;
    });
  }

  Future<void> _reindexLibrary() async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Consumer(
              builder: (_, ref, __) {
                final progress = ref.watch(indexProgressProvider);
                return Text(
                  'Indexing ${progress.$1}/${progress.$2}...',
                  style: const TextStyle(fontSize: 14),
                );
              },
            ),
          ],
        ),
      ),
    );

    try {
      await runIndexing(ref);
      _syncFromProviders();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Indexing failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [VinciTheme.primary, VinciTheme.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 18),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: VinciTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Indexing section
                    _SectionHeader('Indexing'),
                    const SizedBox(height: 12),
                    _SettingsCard([
                      _ToggleRow(
                        icon: Icons.auto_fix_high,
                        title: 'Auto-index new photos',
                        subtitle: 'Run when device is charging',
                        value: ref.watch(autoIndexEnabledProvider),
                        onChanged: (v) {
                          ref.read(autoIndexEnabledProvider.notifier).state = v;
                          setState(() => _autoIndex = v);
                        },
                      ),
                      const Divider(height: 1),
                      _ActionRow(
                        icon: Icons.refresh,
                        title: 'Re-index Library',
                        subtitle: 'Rescan all photos',
                        onTap: _reindexLibrary,
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Library stats
                    _SectionHeader('Library Stats'),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (_, ref, __) {
                        return _SettingsCard([
                          _InfoRow(
                              label: 'Photos indexed',
                              value: '${ref.watch(indexedCountProvider)}'),
                          const Divider(height: 1),
                          _InfoRow(
                            label: 'Index size',
                            value: _indexedCount > 0 ? _indexSize : '0 MB',
                          ),
                          const Divider(height: 1),
                          _InfoRow(
                            label: 'Last indexed',
                            value: _lastIndexed != null
                                ? '${_lastIndexed!.day}/${_lastIndexed!.month}/${_lastIndexed!.year}'
                                : 'Never',
                          ),
                        ]);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Data & Privacy
                    _SectionHeader('Data & Privacy'),
                    const SizedBox(height: 12),
                    _SettingsCard([
                      const _InfoRow(label: 'Photo source', value: 'Device storage'),
                      const Divider(height: 1),
                      _InfoRow(label: 'Privacy policy', value: 'View →'),
                    ]),

                    const SizedBox(height: 24),

                    // About
                    _SectionHeader('About'),
                    const SizedBox(height: 12),
                    _SettingsCard([
                      const _InfoRow(label: 'Version', value: '1.0.0'),
                      const Divider(height: 1),
                      _InfoRow(label: 'Vinci', value: 'AI Photo Search'),
                    ]),

                    const SizedBox(height: 32),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: VinciTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard(this.children);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VinciTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VinciTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: VinciTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 15, color: VinciTheme.textPrimary)),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: VinciTheme.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: VinciTheme.primary,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: VinciTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: VinciTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, color: VinciTheme.textPrimary)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: VinciTheme.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: VinciTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 15, color: VinciTheme.textPrimary)),
          Text(value,
              style: const TextStyle(fontSize: 15, color: VinciTheme.textSecondary)),
        ],
      ),
    );
  }
}
