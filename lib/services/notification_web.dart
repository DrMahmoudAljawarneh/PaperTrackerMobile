import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';
import 'dart:js_interop';

bool _isSupported() {
  try {
    final _ = web.Notification.permission;
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> initWebNotifications() async {
  try {
    if (!_isSupported()) {
      debugPrint('🔔 Web Notifications API is not supported in this browser.');
      return;
    }
    
    final permission = web.Notification.permission;
    debugPrint('🔔 Initializing web notifications. Current permission: $permission');
    
    if (permission == 'default') {
      debugPrint('🔔 Requesting web notification permission...');
      final status = await web.Notification.requestPermission().toDart;
      debugPrint('🔔 Web notification permission request completed. Result: $status');
    } else if (permission == 'denied') {
      debugPrint('🔔 Web notification permission is denied. User must enable it in browser settings.');
    } else if (permission == 'granted') {
      debugPrint('🔔 Web notification permission is already granted.');
    }
  } catch (e) {
    debugPrint('🔔 Failed to request web notification permission: $e');
  }
}

Future<void> showWebNotification(String title, String body) async {
  try {
    if (!_isSupported()) {
      debugPrint('🔔 Cannot show notification: Web Notifications API not supported.');
      return;
    }
    
    final permission = web.Notification.permission;
    debugPrint('🔔 Trying to show web notification. Permission: $permission');
    
    if (permission == 'granted') {
      web.Notification(title, web.NotificationOptions(body: body));
      debugPrint('🔔 Web notification displayed: "$title" - "$body"');
    } else {
      debugPrint('🔔 Web notification skipped (not granted). Permission: $permission');
    }
  } catch (e) {
    debugPrint('🔔 Failed to show web notification: $e');
  }
}

bool isWebNotificationSupported() {
  return _isSupported();
}

String getWebNotificationPermission() {
  try {
    if (!_isSupported()) return 'unsupported';
    return web.Notification.permission;
  } catch (_) {
    return 'unsupported';
  }
}
