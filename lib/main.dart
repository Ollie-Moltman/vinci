import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/theme/vinci_theme.dart';
import 'ui/screens/permissions_screen.dart';
import 'ui/screens/search_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const VinciApp());
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
        '/settings': (_) => const _SettingsRoute(),
      },
    );
  }
}

class PermissionsScreenWrapper extends StatefulWidget {
  const PermissionsScreenWrapper({super.key});

  @override
  State<PermissionsScreenWrapper> createState() => _PermissionsScreenWrapperState();
}

class _PermissionsScreenWrapperState extends State<PermissionsScreenWrapper> {
  bool _granted = false;

  @override
  Widget build(BuildContext context) {
    if (_granted) {
      return const SearchScreen();
    }
    return PermissionsScreen(
      onGranted: () => setState(() => _granted = true),
    );
  }
}

// Minimal settings route shell — real screen coming next
class _SettingsRoute extends StatelessWidget {
  const _SettingsRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings coming soon')),
    );
  }
}
