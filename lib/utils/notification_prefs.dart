import 'package:shared_preferences/shared_preferences.dart';
import 'package:paper_tracker/models/notification_model.dart';

class NotificationPrefs {
  static const _prefix = 'notif_pref_';

  static Future<bool> isEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix${type.name}') ?? true;
  }

  static Future<void> setEnabled(NotificationType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${type.name}', enabled);
  }

  static Future<Map<NotificationType, bool>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationType.values.fold<Map<NotificationType, bool>>(
      {},
      (map, type) {
        map[type] = prefs.getBool('$_prefix${type.name}') ?? true;
        return map;
      },
    );
  }
}
