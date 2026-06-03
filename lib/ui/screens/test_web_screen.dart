import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/vinci_theme.dart';
import '../../data/services/web_embedding_service.dart';
import 'dart:convert';
import '../../providers_web.dart';

/// Web test entry point — mirrors the main app UI but uses WebEmbeddingService.
void main() {
  runApp(const ProviderScope(child: VinciWebTestApp()));
}

class VinciWebTestApp extends StatelessWidget {
  const VinciWebTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinci — Web Test',
      debugShowCheckedModeBanner: false,
      theme: VinciTheme.lightTheme,
      home: const TestWebHome(),
    );
  }
}

class TestWebHome extends StatefulWidget {
  const TestWebHome({super.key});

  @override
  State<TestWebHome> createState() => _TestWebHomeState();
}

class _TestWebHomeState extends State<TestWebHome> {
  int _selectedIndex = 0;
  final _webService = WebEmbeddingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          TestSearchScreen(webService: _webService, onSettingsPressed: () => setState(() => _selectedIndex = 1)),
          TestSettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── SEARCH SCREEN ────────────────────────────────────────────────────────────

class TestSearchScreen extends ConsumerStatefulWidget {
  final WebEmbeddingService webService;
  final VoidCallback onSettingsPressed;
  const TestSearchScreen({super.key, required this.webService, required this.onSettingsPressed});

  @override
  ConsumerState<TestSearchScreen> createState() => _TestSearchScreenState();
}

class _TestSearchScreenState extends ConsumerState<TestSearchScreen> {
  final _controller = TextEditingController();
  bool _isSearching = false;
  bool _isLoadingImages = false;
  List<IndexedImage> _indexedImages = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIndexedImages();
  }

  Future<void> _loadIndexedImages() async {
    setState(() => _isLoadingImages = true);
    try {
      final images = await widget.webService.listIndexed();
      setState(() {
        _indexedImages = images;
        _isLoadingImages = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingImages = false;
        _error = 'Cannot connect to test server. Is it running on localhost:8765?';
      });
    }
  }

  Future<void> _uploadAndIndex() async {
    // Trigger file picker via a custom file input approach
    // In Flutter Web, we use a file upload button
    // For simplicity, show a dialog with instructions
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Images to Test Server'),
        content: Text(
          'This web build uses the Vinci Test Server API.\n\n'
          'Images are uploaded via the /index_bytes endpoint.\n\n'
          'Server: ${WebEmbeddingService().baseUrl}\n'
          'Currently indexed: ${_indexedImages.length} images\n\n'
          'The server already has 3 test images indexed:\n'
          '  • /tmp/test_dog.jpg\n'
          '  • /tmp/test_beach.jpg\n'
          '  • /tmp/test_dinner.jpg\n\n'
          'Try a search query to see results!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadIndexedImages();
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _startSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TestResultsScreen(
          query: query,
          webService: widget.webService,
          indexedImages: _indexedImages,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIndexing = ref.watch(isIndexingProvider);

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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'WEB TEST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: VinciTheme.textPrimary),
                      onPressed: _loadIndexedImages,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: VinciTheme.textPrimary),
                      onPressed: widget.onSettingsPressed,
                    ),
                  ],
                ),
              ),

              // Connection status
              if (_error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.wifi_off, color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
                  ]),
                )
              else if (_isLoadingImages)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Connecting to test server...', style: TextStyle(fontSize: 13)),
                  ]),
                )
              else
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.cloud_done, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Test server connected — ${_indexedImages.length} images indexed',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ]),
                ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _controller,
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

              const SizedBox(height: 12),

              // Quick queries
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in [
                        'dog in a park',
                        'sunset at the beach',
                        'family dinner',
                        'street in new york',
                      ])
                        ActionChip(
                          label: Text(q),
                          onPressed: () {
                            _controller.text = q;
                            _startSearch();
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Index status
              if (isIndexing)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VinciTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Indexing...', style: TextStyle(fontSize: 13)),
                  ]),
                ),

              const SizedBox(height: 12),

              // Search button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _startSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VinciTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSearching
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Search Photos', style: TextStyle(fontSize: 16)),
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

// ─── RESULTS SCREEN ──────────────────────────────────────────────────────────

class TestResultsScreen extends StatefulWidget {
  final String query;
  final WebEmbeddingService webService;
  final List<IndexedImage> indexedImages;

  const TestResultsScreen({
    super.key,
    required this.query,
    required this.webService,
    required this.indexedImages,
  });

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  List<SearchResult>? _results;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    try {
      final results = await widget.webService.search(widget.query);
      setState(() {
        _results = results;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Results', style: TextStyle(fontSize: 18)),
            Text(
              '"${widget.query}"',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _results == null || _results!.isEmpty
                  ? const Center(child: Text('No results found'))
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: VinciTheme.primary.withOpacity(0.08),
                          child: Row(
                            children: [
                              const Icon(Icons.photo_library, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${_results!.length} photos found',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _results!.length,
                            itemBuilder: (context, i) {
                              final r = _results![i];
                              return _ResultCard(result: r);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final SearchResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = (result.score * 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // Image placeholder (we can't display server filesystem images directly in web)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildImagePlaceholder(),
            ),
          ),
          // Score badge
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$pct%',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Image ID
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.id,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    // Different placeholder color based on image id for visual distinction
    final colors = {
      'img_0': Colors.brown.shade200,
      'img_1': Colors.blue.shade200,
      'img_2': Colors.orange.shade200,
    };
    final color = colors[result.id] ?? Colors.grey.shade300;
    return Container(color: color);
  }
}

// ─── SETTINGS SCREEN ─────────────────────────────────────────────────────────

class TestSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Vinci Web Test'),
            subtitle: Text('Testing UI with MobileCLIP TFLite via test server'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Test Server'),
            subtitle: const Text('http://localhost:8765'),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Indexed Images'),
            subtitle: const Text('Server holds 3 test images: dog, beach, dinner'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Tokenizer'),
            subtitle: const Text('CLIP BPE — 4/5 HF reference queries match'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Known Issue'),
            subtitle: const Text('"smiling" token differs from HuggingFace (our: [smil, ing</w>], HF: [smiling</w>])'),
          ),
          ListTile(
            leading: const Icon(Icons.api),
            title: const Text('API Endpoints'),
            subtitle: const Text('/health, /tokenize, /embed_text, /search, /index, /index_bytes'),
          ),
        ],
      ),
    );
  }
}

// ─── Riverpod providers (minimal for test) ────────────────────────────────────
final isIndexingProvider = StateProvider<bool>((ref) => false);
final indexedCountProvider = StateProvider<int>((ref) => 3); // pre-seeded server has 3
final indexProgressProvider = StateProvider<(int, int)>((ref) => (0, 0));