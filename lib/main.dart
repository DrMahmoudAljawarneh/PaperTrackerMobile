import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paper_tracker/app.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize flutter_downloader for foreground background downloads
  if (!kIsWeb) {
    await FlutterDownloader.initialize(
      debug: true, // set to false to disable printing logs to console
      ignoreSsl: true, // option: set to false to disable working with http links
    );
  }
  runApp(const PaperTrackerApp());
}
