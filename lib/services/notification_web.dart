import 'dart:html' as html;

Future<void> initWebNotifications() async {
  try {
    if (!html.Notification.supported) {
      print('🔔 Web Notifications API is not supported in this browser.');
      return;
    }
    
    print('🔔 Initializing web notifications. Current permission: ${html.Notification.permission}');
    
    if (html.Notification.permission == 'default') {
      print('🔔 Requesting web notification permission...');
      final status = await html.Notification.requestPermission();
      print('🔔 Web notification permission request completed. Result: $status');
    } else if (html.Notification.permission == 'denied') {
      print('🔔 Web notification permission is denied. User must enable it in browser settings.');
    } else if (html.Notification.permission == 'granted') {
      print('🔔 Web notification permission is already granted.');
    }
  } catch (e) {
    print('🔔 Failed to request web notification permission: $e');
  }
}

Future<void> showWebNotification(String title, String body) async {
  try {
    if (!html.Notification.supported) {
      print('🔔 Cannot show notification: Web Notifications API not supported.');
      return;
    }
    
    final permission = html.Notification.permission;
    print('🔔 Trying to show web notification. Permission: $permission');
    
    if (permission == 'granted') {
      html.Notification(title, body: body);
      print('🔔 Web notification displayed: "$title" - "$body"');
    } else {
      print('🔔 Web notification skipped (not granted). Permission: $permission');
    }
  } catch (e) {
    print('🔔 Failed to show web notification: $e');
  }
}

bool isWebNotificationSupported() {
  try {
    return html.Notification.supported;
  } catch (_) {
    return false;
  }
}

String getWebNotificationPermission() {
  try {
    if (!html.Notification.supported) return 'unsupported';
    return html.Notification.permission ?? 'default';
  } catch (_) {
    return 'unsupported';
  }
}

