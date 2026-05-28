import 'package:flutter/material.dart';
import '../theme/vinci_theme.dart';
import '../../domain/entities/search_result.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSearching = false;

  // Quick search chips
  final _quickQueries = [
    'Photos with my family',
    'Beach vacations',
    'Birthday celebrations',
    'Food photography',
    'Nature and scenery',
  ];

  void _startSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

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
                    prefixIcon: const Icon(Icons.search, color: VinciTheme.primary),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: VinciTheme.textSecondary),
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
