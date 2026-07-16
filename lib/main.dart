import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/app.dart';
import 'package:paper_tracker/services/notification_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence for Firebase Realtime Database
  if (!kIsWeb) {
    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
    } catch (e) {
      debugPrint('Firebase Database persistence initialization failed: $e');
    }
  }

  // Run the app immediately – do NOT block on optional services
  runApp(const PaperTrackerApp());

  // Initialize optional services in the background AFTER the UI is up
  _initOptionalServices();
}

/// Initialize FlutterDownloader & NotificationService without blocking the UI.
Future<void> _initOptionalServices() async {
  // --- FlutterDownloader ---
  if (!kIsWeb) {
    try {
      await FlutterDownloader.initialize(
        debug: false,
        ignoreSsl: true,
      );
    } catch (e) {
      debugPrint('FlutterDownloader init failed: $e');
    }
  }

  // --- Local Notifications ---
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
}
