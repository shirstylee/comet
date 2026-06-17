import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/library_game_model.dart';
import '../models/user_profile_model.dart';
import 'library_change_notifier.dart';
import 'library_storage.dart';
import 'profile_storage.dart';

class BackupExportResult {
  const BackupExportResult({
    required this.bytes,
    required this.fileName,
    required this.sizeBytes,
    required this.gamesCount,
    required this.ratedCount,
    required this.stagesCount,
  });

  final Uint8List bytes;
  final String fileName;
  final int sizeBytes;
  final int gamesCount;
  final int ratedCount;
  final int stagesCount;
}

class BackupImportPreview {
  const BackupImportPreview({
    required this.fileName,
    required this.sizeBytes,
    required this.rawMap,
    required this.games,
    required this.gamesCount,
    required this.ratedCount,
    required this.stagesCount,
    required this.profileIncluded,
    required this.profile,
  });

  final String fileName;
  final int sizeBytes;
  final Map<String, dynamic> rawMap;
  final List<LibraryGameModel> games;
  final int gamesCount;
  final int ratedCount;
  final int stagesCount;
  final bool profileIncluded;
  final UserProfileModel? profile;
}

class BackupStorage {
  const BackupStorage._();

  static const int currentVersion = 1;
  static const String _libraryBoxName = 'library_games';

  static String buildBackupFileName([DateTime? date]) {
    final currentDate = date ?? DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    final year = currentDate.year;
    final month = twoDigits(currentDate.month);
    final day = twoDigits(currentDate.day);

    return 'comet_backup_${year}_${month}_$day.json';
  }

  static Future<BackupExportResult> buildBackupExportData() async {
    final games = await LibraryStorage.getAllGames();
    final profile = await ProfileStorage.getProfile();
    final fileName = buildBackupFileName();
    final jsonText = _buildJsonText(
      games: games,
      profileMap: profile.toMap(),
    );
    final bytes = Uint8List.fromList(utf8.encode(jsonText));

    return BackupExportResult(
      bytes: bytes,
      fileName: fileName,
      sizeBytes: bytes.length,
      gamesCount: games.length,
      ratedCount: _ratedCount(games),
      stagesCount: _stagesCount(games),
    );
  }

  static Future<int> estimateExportSizeBytes([
    List<LibraryGameModel>? preparedGames,
  ]) async {
    final games = preparedGames ?? await LibraryStorage.getAllGames();
    final profile = await ProfileStorage.getProfile();

    return utf8.encode(
      _buildJsonText(
        games: games,
        profileMap: profile.toMap(),
      ),
    ).length;
  }

  static Future<BackupImportPreview> readImportPreview({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final jsonText = utf8.decode(bytes);
    final decoded = jsonDecode(jsonText);

    if (decoded is! Map) {
      throw const FormatException('Неверная структура архива');
    }

    final rawMap = Map<String, dynamic>.from(decoded);

    if (rawMap['app'] != 'Comet') {
      throw const FormatException('Это не архив Comet');
    }

    final rawGames = rawMap['games'];

    if (rawGames is! List) {
      throw const FormatException('В архиве нет списка игр');
    }

    final games = rawGames
        .whereType<Map>()
        .map((gameMap) => LibraryGameModel.fromMap(gameMap))
        .where((game) => game.title.trim().isNotEmpty)
        .toList();

    final rawProfile = rawMap['profile'];
    final profile = rawProfile is Map
        ? UserProfileModel.fromMap(rawProfile)
        : null;

    return BackupImportPreview(
      fileName: fileName,
      sizeBytes: bytes.length,
      rawMap: rawMap,
      games: games,
      gamesCount: games.length,
      ratedCount: _ratedCount(games),
      stagesCount: _stagesCount(games),
      profileIncluded: profile != null,
      profile: profile,
    );
  }

  static Future<void> importBackup(BackupImportPreview preview) async {
    final libraryBox = await _openLibraryBox();

    await libraryBox.clear();

    for (final game in preview.games) {
      await libraryBox.put(game.id, game.toMap());
    }

    final profile = preview.profile;

    if (profile != null) {
      await ProfileStorage.saveProfile(profile);
    }

    LibraryChangeNotifier.notify();
  }

  static Future<Box> _openLibraryBox() async {
    if (Hive.isBoxOpen(_libraryBoxName)) {
      return Hive.box(_libraryBoxName);
    }

    return Hive.openBox(_libraryBoxName);
  }

  static String _buildJsonText({
    required List<LibraryGameModel> games,
    required Map<String, dynamic> profileMap,
  }) {
    final exportMap = <String, dynamic>{
      'app': 'Comet',
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'type': 'full_backup',
      'includes': {
        'library': true,
        'ratings': true,
        'progress': true,
        'notifications': false,
        'profile': true,
      },
      'summary': {
        'gamesCount': games.length,
        'ratedCount': _ratedCount(games),
        'stagesCount': _stagesCount(games),
        'profileIncluded': true,
      },
      'profile': profileMap,
      'games': games.map((game) => game.toMap()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportMap);
  }

  static int _ratedCount(List<LibraryGameModel> games) {
    return games.where((game) {
      return game.userRating != null && game.userRating! > 0;
    }).length;
  }

  static int _stagesCount(List<LibraryGameModel> games) {
    return games.fold<int>(
      0,
          (sum, game) => sum + game.stages.length,
    );
  }
}
