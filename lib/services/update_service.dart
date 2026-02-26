import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  // TODO: Replace with your actual Firebase Hosting URL after first deploy
  static const String _baseUrl = 'https://papercheck-2026.web.app';
  static const String _versionUrl = '$_baseUrl/version.json';

  /// Check for app updates and show dialog if available.
  /// Call this from the dashboard on startup.
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_versionUrl));
      if (response.statusCode != 200) return;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final remoteVersion = data['version'] as String? ?? '';
      final releaseNotes = data['releaseNotes'] as String? ?? '';
      final apkUrl = data['apkUrl'] as String? ?? '';

      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      if (_isNewerVersion(remoteVersion, localVersion)) {
        if (!context.mounted) return;
        _showUpdateDialog(
          context,
          remoteVersion: remoteVersion,
          releaseNotes: releaseNotes,
          downloadUrl: apkUrl,
        );
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  /// Compare semantic versions. Returns true if remote > local.
  static bool _isNewerVersion(String remote, String local) {
    final remoteParts = remote.split('.').map(int.tryParse).toList();
    final localParts = local.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final r = i < remoteParts.length ? (remoteParts[i] ?? 0) : 0;
      final l = i < localParts.length ? (localParts[i] ?? 0) : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String remoteVersion,
    required String releaseNotes,
    required String downloadUrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            const Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version $remoteVersion is available.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'What\'s new:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                releaseNotes,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startDownload(downloadUrl);
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  static Future<void> _startDownload(String url) async {
    try {
      // Request notification permission to show the progress bar (required on Android 13+)
      await Permission.notification.request();

      // Get external storage directory for the download
      final directory = await getExternalStorageDirectory();
      if (directory == null) return;

      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: directory.path,
        fileName: 'paper-tracker-update.apk',
        showNotification: true, // show download progress in status bar
        openFileFromNotification: true, // click on notification to open the downloaded file (install APK)
        saveInPublicStorage: true, // move to public Downloads folder so package installer can read it
      );
      
      debugPrint('Update download started with taskId: $taskId');
    } catch (e) {
      debugPrint('Failed to start download: $e');
    }
  }
}
