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
      '«$gameTitle» добавлена в библиотеку. Игра появилась в коллекции — теперь можно отслеживать время, оценку и этапы прохождения.',
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
      '«$gameTitle» удалена из библиотеки. Вместе с игрой удалены сохранённый прогресс, время, оценка и этапы прохождения.',
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
    double? previousRating,
  }) async {
    await addGameNotification(
      message: _ratingNotificationMessage(
        gameTitle: gameTitle,
        rating: rating,
        previousRating: previousRating,
        isUpdate: isUpdate,
      ),
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
      '«$gameTitle» отмечена как пройденная. Прохождение завершено, игра перенесена в список завершённых.',
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
      'В игре «$gameTitle» создан новый этап: «$stageTitle». Он добавлен в историю прохождения.',
      type: AppNotificationType.progress,
      gameId: gameId,
      gameTitle: gameTitle,
    );
  }

  static Future<void> addProgressStageCompletedNotification({
    required int gameId,
    required String gameTitle,
    required String stageTitle,
  }) async {
    await addGameNotification(
      message:
      'В игре «$gameTitle» завершён этап: «$stageTitle». История прохождения обновлена.',
      type: AppNotificationType.completed,
      gameId: gameId,
      gameTitle: gameTitle,
    );
  }

  static Future<void> addExportSuccessNotification({
    required String fileName,
    required int gamesCount,
  }) async {
    await addGameNotification(
      message:
      'Экспорт завершён. Файл «$fileName» сохранён, игр в резервной копии: $gamesCount.',
      type: AppNotificationType.success,
    );
  }

  static Future<void> addExportFailedNotification() async {
    await addGameNotification(
      message:
      'Экспорт не выполнен. Не удалось сохранить резервную копию — выберите другое место или повторите попытку позже.',
      type: AppNotificationType.warning,
    );
  }

  static Future<void> replaceWithImportSuccessNotification({
    required int gamesCount,
  }) async {
    final box = await _openBox();

    await box.clear();

    final notification = AppNotificationModel(
      id: _createNotificationId(),
      message:
      'Импорт завершён. Библиотека восстановлена, импортировано игр: $gamesCount.',
      type: AppNotificationType.restore,
      createdAt: DateTime.now(),
    );

    await box.put(notification.id, notification.toMap());

    NotificationChangeNotifier.notify();
  }

  static Future<void> addImportFailedNotification() async {
    await addGameNotification(
      message:
      'Импорт не выполнен. Не удалось восстановить библиотеку — проверьте JSON-файл и попробуйте снова.',
      type: AppNotificationType.warning,
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

  static String _ratingNotificationMessage({
    required String gameTitle,
    required double rating,
    required double? previousRating,
    required bool isUpdate,
  }) {
    final ratingText = _formatRating(rating);

    if (!isUpdate || previousRating == null || previousRating <= 0) {
      return 'Вы поставили игре «$gameTitle» $ratingText/10. Оценка сохранена в личной статистике.';
    }

    final previousRatingText = _formatRating(previousRating);

    if (rating > previousRating) {
      return 'Вы повысили оценку игры «$gameTitle» с $previousRatingText/10 до $ratingText/10. Игра поднялась в личном рейтинге.';
    }

    if (rating < previousRating) {
      return 'Вы снизили оценку игры «$gameTitle» с $previousRatingText/10 до $ratingText/10. Игра опустилась в личном рейтинге.';
    }

    return 'Оценка игры «$gameTitle» обновлена: $ratingText/10.';
  }

  static String _formatRating(double rating) {
    if (rating == rating.roundToDouble()) {
      return rating.toInt().toString();
    }

    return rating.toStringAsFixed(1);
  }
}
