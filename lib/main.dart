import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:paper_tracker/app.dart';
import 'package:paper_tracker/services/notification_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app immediately – do NOT block on optional services
  runApp(const PaperTrackerApp());

  // Initialize optional services in the background AFTER the UI is up
  _initOptionalServices();
}

/// Initialize FlutterDownloader & NotificationService without blocking the UI.
/// Any errors are surfaced as toast messages so you can see what went wrong.
Future<void> _initOptionalServices() async {
  // --- FlutterDownloader ---
  if (!kIsWeb) {
    try {
      await FlutterDownloader.initialize(
        debug: true,
        ignoreSsl: true,
      );
      _showToast('✅ FlutterDownloader initialized');
    } catch (e) {
      debugPrint('FlutterDownloader init failed: $e');
      _showToast('❌ FlutterDownloader init failed: $e', isError: true);
    }
  }

  // --- Local Notifications ---
  try {
    await NotificationService().initialize();
    _showToast('✅ NotificationService initialized');
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
    _showToast('❌ NotificationService init failed: $e', isError: true);
  }
}

void _showToast(String message, {bool isError = false}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}
