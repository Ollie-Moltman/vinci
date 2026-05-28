import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/vinci_theme.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/permissions_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'providers/providers.dart';

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
      home: const SplashWrapper(),
      routes: {
        '/permissions': (_) => const PermissionsScreenWrapper(),
        '/search': (_) => const SearchScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/home': (_) => const HomeScaffold(),
      },
    );
  }
}

/// Brief splash before permission check.
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/permissions');
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

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
