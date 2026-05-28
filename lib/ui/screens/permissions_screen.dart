import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/vinci_theme.dart';
import '../services/permission_service.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onGranted;

  const PermissionsScreen({super.key, required this.onGranted});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _permissionService = PermissionService();
  bool _isRequesting = false;
  bool _denied = false;

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    final granted = await _permissionService.requestPhotosPermission();
    setState(() {
      _isRequesting = false;
      _denied = !granted;
    });
    if (granted) widget.onGranted();
  }

  @override
  void initState() {
    super.initState();
    // Auto-request on appear
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermission());
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
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                // Vinci logo placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VinciTheme.primary, VinciTheme.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.photo_search_rounded,
                      size: 56, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Vinci',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: VinciTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'AI-Powered Photo Search',
                  style: TextStyle(fontSize: 16, color: VinciTheme.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: VinciTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.photo_library_outlined,
                          'Your photos stay on your device'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.lock_outlined, '100% private & secure'),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.cloud_off, 'No cloud upload needed'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_denied) ...[
                  const Text(
                    'Permission required to search your photos',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _permissionService.openSettings(),
                    child: const Text('Open Settings'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _isRequesting ? null : _requestPermission,
                    child: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Allow Access'),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
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
          child: Text(text,
              style: const TextStyle(fontSize: 14, color: VinciTheme.textPrimary)),
        ),
      ],
    );
  }
}
