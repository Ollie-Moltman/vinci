import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/vinci_theme.dart';
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
      home: const PermissionsScreenWrapper(),
      routes: {
        '/search': (_) => const SearchScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

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
    final hasPermission = ref.watch(hasPermissionProvider);
    final granted = _granted || hasPermission;

    if (granted) {
      return const SearchScreen();
    }
    return PermissionsScreen(
      onGranted: () {
        ref.read(hasPermissionProvider.notifier).state = true;
        setState(() => _granted = true);
      },
    );
  }
}
