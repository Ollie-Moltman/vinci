// Web entry point — uses only web-compatible services (no FFI).
// Flutter web build target should use this as the entry point.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme/vinci_theme.dart';
import 'ui/screens/test_web_screen.dart';

void main() {
  runApp(const ProviderScope(child: VinciWebTestApp()));
}