import 'dart:convert';
import 'dart:io';

import '../models/library_game_model.dart';
import 'library_storage.dart';
import 'profile_storage.dart';

class BackupExportResult {
  const BackupExportResult({
    required this.file,
    required this.fileName,
    required this.sizeBytes,
    required this.gamesCount,
    required this.ratedCount,
    required this.stagesCount,
  });

  final File file;
  final String fileName;
  final int sizeBytes;
  final int gamesCount;
  final int ratedCount;
  final int stagesCount;
}

class BackupStorage {
  const BackupStorage._();

  static const int currentVersion = 1;

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

  static Future<BackupExportResult> exportLibraryToJson({
    required String directoryPath,
  }) async {
    final games = await LibraryStorage.getAllGames();
    final profile = await ProfileStorage.getProfile();
    final fileName = buildBackupFileName();
    final jsonText = _buildJsonText(
      games: games,
      profileMap: profile.toMap(),
    );

    final file = File('$directoryPath${Platform.pathSeparator}$fileName');

    await file.writeAsString(
      jsonText,
      encoding: utf8,
      flush: true,
    );

    final sizeBytes = await file.length();

    return BackupExportResult(
      file: file,
      fileName: fileName,
      sizeBytes: sizeBytes,
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
