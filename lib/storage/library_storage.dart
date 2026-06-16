import 'package:hive_flutter/hive_flutter.dart';

import '../models/game_stage_model.dart';
import '../models/library_game_model.dart';
import '../services/cover_cache_service.dart';
import 'library_change_notifier.dart';
import 'notification_storage.dart';

class LibraryStorage {
  static const String _boxName = 'library_games';

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }

    return Hive.openBox(_boxName);
  }

  static Future<List<LibraryGameModel>> getAllGames() async {
    final box = await _openBox();

    return box.values
        .map((value) {
      if (value is Map) {
        return LibraryGameModel.fromMap(value);
      }

      return null;
    })
        .whereType<LibraryGameModel>()
        .toList();
  }

  static Future<void> addGame(LibraryGameModel game) async {
    final box = await _openBox();

    await box.put(game.id, game.toMap());

    await _safeCreateNotification(
          () => NotificationStorage.addGameAddedNotification(
        gameId: game.id,
        gameTitle: game.title,
      ),
    );

    LibraryChangeNotifier.notify();
  }

  static Future<void> updateGame(LibraryGameModel game) async {
    final box = await _openBox();
    final oldValue = box.get(game.id);

    final oldGame = oldValue is Map
        ? LibraryGameModel.fromMap(oldValue)
        : null;

    await box.put(game.id, game.toMap());

    await _createUpdateNotifications(
      oldGame: oldGame,
      newGame: game,
    );

    LibraryChangeNotifier.notify();
  }

  static Future<void> deleteGame(int gameId) async {
    final box = await _openBox();
    final value = box.get(gameId);
    LibraryGameModel? deletedGame;

    if (value is Map) {
      deletedGame = LibraryGameModel.fromMap(value);

      await CoverCacheService.deleteCover(deletedGame.localImagePath);
    }

    await box.delete(gameId);

    if (deletedGame != null) {
      await _safeCreateNotification(
            () => NotificationStorage.addGameDeletedNotification(
          gameId: deletedGame!.id,
          gameTitle: deletedGame.title,
        ),
      );
    }

    LibraryChangeNotifier.notify();
  }

  static Future<bool> containsGame(int gameId) async {
    final box = await _openBox();

    return box.containsKey(gameId);
  }

  static Future<LibraryGameModel?> getGameById(int gameId) async {
    final box = await _openBox();
    final value = box.get(gameId);

    if (value is Map) {
      return LibraryGameModel.fromMap(value);
    }

    return null;
  }

  static Future<void> clearLibrary() async {
    final box = await _openBox();

    for (final value in box.values) {
      if (value is Map) {
        final game = LibraryGameModel.fromMap(value);

        await CoverCacheService.deleteCover(game.localImagePath);
      }
    }

    await box.clear();

    LibraryChangeNotifier.notify();
  }

  static Future<void> _createUpdateNotifications({
    required LibraryGameModel? oldGame,
    required LibraryGameModel newGame,
  }) async {
    if (oldGame == null) return;

    final ratingWasChanged = oldGame.userRating != newGame.userRating;
    final ratingWasAdded = oldGame.userRating == null && newGame.userRating != null;

    if (ratingWasChanged && newGame.userRating != null) {
      await _safeCreateNotification(
            () => NotificationStorage.addRatingNotification(
          gameId: newGame.id,
          gameTitle: newGame.title,
          rating: newGame.userRating!,
          isUpdate: !ratingWasAdded,
        ),
      );
    }

    final statusWasChanged = oldGame.status != newGame.status;
    final gameBecameCompleted = statusWasChanged && _isCompletedStatus(newGame.status);

    if (gameBecameCompleted) {
      await _safeCreateNotification(
            () => NotificationStorage.addGameCompletedNotification(
          gameId: newGame.id,
          gameTitle: newGame.title,
        ),
      );
    }

    final stageWasAdded = newGame.stages.length > oldGame.stages.length;

    if (stageWasAdded) {
      final stage = newGame.stages.last;

      await _safeCreateNotification(
            () => NotificationStorage.addProgressStageNotification(
          gameId: newGame.id,
          gameTitle: newGame.title,
          stageTitle: stage.title,
        ),
      );

      return;
    }

    final completedStage = _findCompletedStage(
      oldStages: oldGame.stages,
      newStages: newGame.stages,
    );

    if (completedStage != null && !_isInitialStage(completedStage.title)) {
      await _safeCreateNotification(
            () => NotificationStorage.addProgressStageCompletedNotification(
          gameId: newGame.id,
          gameTitle: newGame.title,
          stageTitle: completedStage.title,
        ),
      );
    }
  }

  static GameStageModel? _findCompletedStage({
    required List<GameStageModel> oldStages,
    required List<GameStageModel> newStages,
  }) {
    final count = oldStages.length < newStages.length
        ? oldStages.length
        : newStages.length;

    for (var index = 0; index < count; index++) {
      final oldStage = oldStages[index];
      final newStage = newStages[index];

      if (!oldStage.isDone && newStage.isDone) {
        return newStage;
      }
    }

    return null;
  }

  static bool _isInitialStage(String title) {
    return title.trim().toLowerCase() == 'начало игры';
  }

  static bool _isCompletedStatus(String status) {
    final normalizedStatus = status.trim().toLowerCase();

    return normalizedStatus == 'пройдено' ||
        normalizedStatus == 'completed';
  }

  static Future<void> _safeCreateNotification(
      Future<void> Function() createNotification,
      ) async {
    try {
      await createNotification();
    } catch (_) {
      // Ошибка уведомлений не должна ломать сохранение игры.
    }
  }
}
