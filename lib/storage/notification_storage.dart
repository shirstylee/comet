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
      id: _createNotificationId(),
      message: message,
      type: type,
      createdAt: DateTime.now(),
      gameId: gameId,
      gameTitle: gameTitle,
    );

    await addNotification(notification);
  }

  static Future<void> addGameAddedNotification({
    required int gameId,
    required String gameTitle,
  }) async {
    await addGameNotification(
      message:
      '«$gameTitle добавлена в библиотеку. Теперь Comet будет отслеживать ваш игровой прогресс.»',
      type: AppNotificationType.game,
      gameId: gameId,
      gameTitle: gameTitle,
    );
  }

  static Future<void> addGameDeletedNotification({
    required int gameId,
    required String gameTitle,
  }) async {
    await addGameNotification(
      message:
      '«$gameTitle удалена из библиотеки. Запись исчезла с вашей игровой орбиты.»',
      type: AppNotificationType.warning,
      gameId: gameId,
      gameTitle: gameTitle,
    );
  }

  static Future<void> addRatingNotification({
    required int gameId,
    required String gameTitle,
    required double rating,
    required bool isUpdate,
  }) async {
    final ratingText = _formatRating(rating);

    await addGameNotification(
      message: isUpdate
          ? '«Оценка $gameTitle обновлена до $ratingText/10. Игра поднялась в вашем личном рейтинге.»'
          : '«$gameTitle получила $ratingText/10. Оценка добавлена в вашу игровую статистику.»',
      type: AppNotificationType.rating,
      gameId: gameId,
      gameTitle: gameTitle,
    );
  }

  static Future<void> addGameCompletedNotification({
    required int gameId,
    required String gameTitle,
  }) async {
    await addGameNotification(
      message:
      '«Финал достигнут: $gameTitle отмечена как пройденная. Ещё одна история завершена.»',
      type: AppNotificationType.completed,
      gameId: gameId,
      gameTitle: gameTitle,
    );
  }

  static Future<void> addProgressStageNotification({
    required int gameId,
    required String gameTitle,
    required String stageTitle,
  }) async {
    await addGameNotification(
      message:
      '«Новый этап сохранён: “$stageTitle”. Прогресс добавлен в журнал прохождения.»',
      type: AppNotificationType.progress,
      gameId: gameId,
      gameTitle: gameTitle,
    );
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

  static String _createNotificationId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static String _formatRating(double rating) {
    if (rating == rating.roundToDouble()) {
      return rating.toInt().toString();
    }

    return rating.toStringAsFixed(1);
  }
}
