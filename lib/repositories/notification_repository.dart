import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/notification_model.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';

class NotificationRepository {
  final FirebaseDatabase _db;

  NotificationRepository({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  /// Stream notifications for a specific user, ordered by creation time
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .ref('notifications/$userId')
        .orderByChild('createdAt')
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <NotificationModel>[];
      final data = safeCastMap(event.snapshot.value);
      final notifications = data.entries
          .map((e) => NotificationModel.fromMap(
              e.key, safeCastMap(e.value)))
          .toList();
      // Sort by createdAt descending (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// Get unread count for badge display
  Stream<int> getUnreadCount(String userId) {
    return getNotifications(userId)
        .map((notifications) => notifications.where((n) => !n.isRead).length);
  }

  /// Push a new notification to a recipient's node
  Future<void> pushNotification(NotificationModel notification) async {
    final ref = _db.ref('notifications/${notification.recipientId}').push();
    await ref.set(notification.toMap());
  }

  /// Push notifications to multiple recipients at once
  Future<void> pushNotificationToMany({
    required List<String> recipientIds,
    required String senderId,
    required String senderName,
    required String title,
    required String message,
    required NotificationType type,
    required String relatedPaperId,
  }) async {
    final now = DateTime.now();
    final updates = <String, dynamic>{};

    for (final recipientId in recipientIds) {
      // Don't notify yourself
      if (recipientId == senderId) continue;

      final newKey = _db.ref('notifications/$recipientId').push().key;
      if (newKey == null) continue;

      final notification = NotificationModel(
        id: newKey,
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        title: title,
        message: message,
        type: type,
        relatedPaperId: relatedPaperId,
        createdAt: now,
      );
      updates['notifications/$recipientId/$newKey'] = notification.toMap();
    }

    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _db
        .ref('notifications/$userId/$notificationId')
        .update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _db.ref('notifications/$userId').get();
    if (!snapshot.exists) return;

    final data = safeCastMap(snapshot.value);
    final updates = <String, dynamic>{};
    for (final key in data.keys) {
      updates['notifications/$userId/$key/isRead'] = true;
    }
    if (updates.isNotEmpty) {
      await _db.ref().update(updates);
    }
  }

  /// Save FCM token for a user
  Future<void> saveFcmToken(String userId, String token) async {
    await _db.ref('fcmTokens/$userId').set(token);
  }

  /// Delete a single notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _db.ref('notifications/$userId/$notificationId').remove();
  }

  /// Clear all notifications
  Future<void> clearAll(String userId) async {
    await _db.ref('notifications/$userId').remove();
  }
}
