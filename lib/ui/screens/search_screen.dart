import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/vinci_theme.dart';
import '../../core/indexing_runner.dart';
import '../../providers/providers.dart';
import 'results_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;
  bool _indexChecked = false;

  final _quickQueries = [
    'Photos with my family',
    'Beach vacations',
    'Birthday celebrations',
    'Food photography',
    'Nature and scenery',
  ];

  @override
  void initState() {
    super.initState();
    // On first entry: load persisted state, then auto-index if needed
    Future.microtask(() async {
      // Load existing index and initialize embedding service
      await loadPersistedState(ref);

      // Auto-index if library is empty
      final count = ref.read(indexedCountProvider);
      if (count == 0) {
        await runIndexing(ref);
      }
    });
  }

  void _startSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    ref.read(searchQueryProvider.notifier).state = query;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(query: query),
      ),
    ).then((_) => setState(() => _isSearching = false));
  }

  void _useQuickQuery(String query) {
    _controller.text = query;
    _startSearch();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VinciTheme.backgroundMain, VinciTheme.backgroundLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    const Text(
                      'Vinci',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: VinciTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: VinciTheme.textPrimary),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/settings');
                      },
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Describe the photo you\'re looking for...',
                    hintStyle: const TextStyle(color: VinciTheme.textSecondary),
                    prefixIcon:
                        const Icon(Icons.search, color: VinciTheme.primary),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: VinciTheme.textSecondary),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _startSearch(),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              const SizedBox(height: 16),

              // Quick search chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQueries.map((q) {
                      return GestureDetector(
                        onTap: () => _useQuickQuery(q),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: VinciTheme.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            q,
                            style: const TextStyle(
                              fontSize: 13,
                              color: VinciTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const Spacer(),

              // Index status banner
              Consumer(
                builder: (_, ref, __) {
                  final isIndexing = ref.watch(isIndexingProvider);
                  final progress = ref.watch(indexProgressProvider);
                  final count = ref.watch(indexedCountProvider);
                  if (isIndexing) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: VinciTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Indexing ${progress.$1}/${progress.$2} photos...',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  if (count > 0) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '$count photos indexed',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 12),

              // Search button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _startSearch,
                    child: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Search Photos'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
