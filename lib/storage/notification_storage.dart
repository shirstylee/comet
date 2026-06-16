import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_notification_model.dart';
import 'notification_change_notifier.dart';

class NotificationStorage {
  static const String _boxName = 'app_notifications';

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }

    return Hive.openBox(_boxName);
  }

  static Future<List<AppNotificationModel>> getAllNotifications() async {
    final box = await _openBox();

    final notifications = box.values
        .map((value) {
      if (value is Map) {
        return AppNotificationModel.fromMap(value);
      }

      return null;
    })
        .whereType<AppNotificationModel>()
        .toList();

    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  }

  static Future<void> addNotification(AppNotificationModel notification) async {
    final box = await _openBox();

    await box.put(notification.id, notification.toMap());

    NotificationChangeNotifier.notify();
  }

  static Future<void> addGameNotification({
    required String message,
    required AppNotificationType type,
    int? gameId,
    String? gameTitle,
  }) async {
    final notification = AppNotificationModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      type: type,
      createdAt: DateTime.now(),
      gameId: gameId,
      gameTitle: gameTitle,
    );

    await addNotification(notification);
  }

  static Future<void> deleteNotification(String id) async {
    final box = await _openBox();

    await box.delete(id);

    NotificationChangeNotifier.notify();
  }

  static Future<void> clearNotifications() async {
    final box = await _openBox();

    await box.clear();

    NotificationChangeNotifier.notify();
  }
}
