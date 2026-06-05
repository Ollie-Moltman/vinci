import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'ui/theme/vinci_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/model_download_screen.dart';
import 'ui/screens/permissions_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'providers/providers.dart';
import 'data/services/model_download_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: VinciApp()));
}

class VinciApp extends StatelessWidget {
  const VinciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vinci',
      debugShowCheckedModeBanner: false,
      theme: VinciTheme.lightTheme,
      home: const StartupFlow(),
      routes: {
        '/permissions': (_) => const PermissionsScreenWrapper(),
        '/search': (_) => const SearchScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/home': (_) => const HomeScaffold(),
      },
    );
  }
}

/// Root widget that manages the startup sequence:
/// 1. Splash (brief)
/// 2. If models missing → Model download screen
/// 3. Permissions check
/// 4. Home
class StartupFlow extends StatefulWidget {
  const StartupFlow({super.key});

  @override
  State<StartupFlow> createState() => _StartupFlowState();
}

class _StartupFlowState extends State<StartupFlow> {
  static const _splashDuration = Duration(milliseconds: 900);

  _StartupStep _step = _StartupStep.splash;
  bool? _modelsReady;

  @override
  void initState() {
    super.initState();
    _checkModels();
  }

  Future<void> _checkModels() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;

    final appDir = await getApplicationDocumentsDirectory();
    final modelDir = '${appDir.path}/.vinci/models';

    // Ensure directory exists before checking or downloading
    final dir = Directory(modelDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final service = ModelDownloadService(modelDir);
    _modelsReady = await service.modelsReady();

    setState(() {
      _step = _modelsReady == true
          ? _StartupStep.permissions
          : _StartupStep.modelDownload;
    });
  }

  void _onModelsReady() {
    if (mounted) {
      setState(() => _step = _StartupStep.permissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _StartupStep.splash:
        return const SplashScreen();
      case _StartupStep.modelDownload:
        return ModelDownloadScreen(onComplete: _onModelsReady);
      case _StartupStep.permissions:
        return const PermissionsScreenWrapper();
    }
  }
}

enum _StartupStep { splash, modelDownload, permissions }

/// Permissions check → then to home.
class PermissionsScreenWrapper extends ConsumerStatefulWidget {
  const PermissionsScreenWrapper({super.key});

  @override
  ConsumerState<PermissionsScreenWrapper> createState() =>
      _PermissionsScreenWrapperState();
}

class _PermissionsScreenWrapperState
    extends ConsumerState<PermissionsScreenWrapper> {
  bool _granted = false;

  @override
  Widget build(BuildContext context) {
    if (_granted) {
      return const HomeScaffold();
    }
    return PermissionsScreen(
      onGranted: () {
        ref.read(hasPermissionProvider.notifier).state = true;
        setState(() => _granted = true);
      },
    );
  }
}

/// Main scaffold with bottom navigation bar.
class HomeScaffold extends StatefulWidget {
  const HomeScaffold({super.key});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> {
  int _currentIndex = 0;

  final _screens = const [
    SearchScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.search,
                  label: 'Search',
                  active: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  active: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? VinciTheme.primary : VinciTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? VinciTheme.primary : VinciTheme.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}