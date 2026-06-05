import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/vinci_theme.dart';

enum _PermissionStatus { checking, requesting, denied, permanentlyDenied }

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const PermissionsScreen({super.key, required this.onGranted});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  _PermissionStatus _status = _PermissionStatus.checking;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final result = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        iosAccessLevel: IosAccessLevel.readWrite,
      ),
    );

    if (!mounted) return;

    if (result.isAuth) {
      widget.onGranted();
    } else if (result == PermissionState.denied) {
      setState(() => _status = _PermissionStatus.requesting);
    } else {
      setState(() => _status = _PermissionStatus.permanentlyDenied);
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _status = _PermissionStatus.requesting);
    try {
      final result = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;
      if (result.isAuth) {
        widget.onGranted();
      } else if (result == PermissionState.denied) {
        setState(() => _status = _PermissionStatus.denied);
      } else {
        setState(() => _status = _PermissionStatus.permanentlyDenied);
      }
    } finally {
      if (mounted && _status != _PermissionStatus.denied &&
          _status != _PermissionStatus.permanentlyDenied) {
        setState(() => _status = _PermissionStatus.requesting);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _PermissionStatus.checking) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [VinciTheme.backgroundMain, VinciTheme.backgroundLight],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [VinciTheme.primary, VinciTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: VinciTheme.primary.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Access Your Photos',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: VinciTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vinci needs access to your photo library to index and search your photos using AI — all processing happens on your device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: VinciTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Privacy badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        '100% on-device — never leaves your phone',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 4),
                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _status == _PermissionStatus.requesting
                        ? null
                        : _requestPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VinciTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _status == _PermissionStatus.requesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Allow Photo Access',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (_status == _PermissionStatus.denied) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => openAppSettings(),
                    child: const Text(
                      'Open Settings Instead',
                      style: TextStyle(
                        color: VinciTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                if (_status == _PermissionStatus.permanentlyDenied) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.block,
                            size: 20, color: Colors.orange.shade700),
                        const SizedBox(height: 8),
                        Text(
                          'Permission was denied. Please enable photo access in Settings.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Open Settings'),
                  ),
                ],
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}