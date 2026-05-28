import 'package:hive_flutter/hive_flutter.dart';

import '../models/library_game_model.dart';

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
  }

  static Future<void> updateGame(LibraryGameModel game) async {
    final box = await _openBox();

    await box.put(game.id, game.toMap());
  }

  static Future<void> deleteGame(int gameId) async {
    final box = await _openBox();

    await box.delete(gameId);
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

    await box.clear();
  }
}