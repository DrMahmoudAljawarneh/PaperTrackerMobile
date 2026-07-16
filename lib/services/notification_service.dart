import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_stub.dart'
    if (dart.library.html) 'notification_web.dart' as web_notif;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isWebNotificationSupported {
    if (!kIsWeb) return false;
    return web_notif.isWebNotificationSupported();
  }

  String get webNotificationPermission {
    if (!kIsWeb) return 'unsupported';
    return web_notif.getWebNotificationPermission();
  }

  /// Initialize the local notifications plugin. Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      await web_notif.initWebNotifications();
      _initialized = true;
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // Android 13+ notification permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS permission
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Deep-link handling can be added here later if needed
  }

  bool _fcmSetupDone = false;

  /// Request FCM permission, save the device token to RTDB, and listen for
  /// incoming push notifications while the app is in the foreground.
  Future<void> setupFcm({required String userId}) async {
    if (kIsWeb) return;

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        if (token != null) {
          await FirebaseDatabase.instance
              .ref('fcmTokens/$userId')
              .set(token);
        }

        if (!_fcmSetupDone) {
          _fcmSetupDone = true;

          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            final notification = message.notification;
            if (notification != null) {
              showNotification(
                id: DateTime.now()
                    .millisecondsSinceEpoch
                    .remainder(100000),
                title: notification.title ?? '',
                body: notification.body ?? '',
                payload: message.data['route'],
              );
            }
          });

          FirebaseMessaging.onMessageOpenedApp
              .listen((RemoteMessage message) {
            final route = message.data['route'];
            if (route != null) {
              // Navigate using go_router when a BuildContext is available
            }
          });
        }
      }
    } catch (e) {
      debugPrint('FCM setup failed: $e');
    }
  }

  /// Show a local notification in the system tray/shade.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      await web_notif.showWebNotification(title, body);
      return;
    }

    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'paper_tracker_notifications',
      'Paper Tracker',
      channelDescription: 'Notifications for Paper Tracker updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
