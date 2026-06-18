import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/library_game_model.dart';
import '../models/user_profile_model.dart';
import '../services/cover_cache_service.dart';
import 'library_change_notifier.dart';
import 'library_storage.dart';
import 'notification_storage.dart';
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

  static const int currentVersion = 2;
  static const String _libraryBoxName = 'library_games';
  static const String _coversFolderName = 'covers';
  static const String _profileFolderName = 'profile';

  static String buildBackupFileName([DateTime? date]) {
    final currentDate = date ?? DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    final year = currentDate.year;
    final month = twoDigits(currentDate.month);
    final day = twoDigits(currentDate.day);
    final hour = twoDigits(currentDate.hour);
    final minute = twoDigits(currentDate.minute);
    final second = twoDigits(currentDate.second);

    return 'comet_backup_${year}_${month}_${day}_${hour}_${minute}_$second.json';
  }

  static Future<BackupExportResult> buildBackupExportData() async {
    final games = await LibraryStorage.getAllGames();
    final profile = await ProfileStorage.getProfile();
    final fileName = buildBackupFileName();

    final exportedGames = <Map<String, dynamic>>[];

    for (final game in games) {
      exportedGames.add(await _buildGameExportMap(game));
    }

    final profileMap = await _buildProfileExportMap(profile);

    final jsonText = _buildJsonText(
      games: exportedGames,
      profileMap: profileMap,
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

    final exportedGames = <Map<String, dynamic>>[];

    for (final game in games) {
      exportedGames.add(await _buildGameExportMap(game));
    }

    final profileMap = await _buildProfileExportMap(profile);

    return utf8.encode(
      _buildJsonText(
        games: exportedGames,
        profileMap: profileMap,
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
    final rawGames = preview.rawMap['games'];

    if (rawGames is! List) {
      throw const FormatException('В архиве нет списка игр');
    }

    await _deleteCurrentLocalCovers(libraryBox);
    await libraryBox.clear();

    for (final rawGame in rawGames) {
      if (rawGame is! Map) continue;

      final gameMap = Map<String, dynamic>.from(rawGame);
      final restoredGameMap = await _restoreGameCover(gameMap);
      final game = LibraryGameModel.fromMap(restoredGameMap);

      if (game.title.trim().isEmpty) continue;

      await libraryBox.put(game.id, game.toMap());
    }

    final rawProfile = preview.rawMap['profile'];

    if (rawProfile is Map) {
      final restoredProfileMap = await _restoreProfileAvatar(
        Map<String, dynamic>.from(rawProfile),
      );
      final profile = UserProfileModel.fromMap(restoredProfileMap);
      await ProfileStorage.saveProfile(profile);
    }

    await NotificationStorage.replaceWithImportSuccessNotification(
      gamesCount: preview.gamesCount,
    );

    LibraryChangeNotifier.notify();
  }

  static Future<Box> _openLibraryBox() async {
    if (Hive.isBoxOpen(_libraryBoxName)) {
      return Hive.box(_libraryBoxName);
    }

    return Hive.openBox(_libraryBoxName);
  }

  static Future<void> _deleteCurrentLocalCovers(Box libraryBox) async {
    final currentValues = libraryBox.values.toList(growable: false);

    for (final value in currentValues) {
      if (value is! Map) continue;

      try {
        final game = LibraryGameModel.fromMap(value);
        await CoverCacheService.deleteCover(game.localImagePath);
      } catch (_) {
        // Если старая запись повреждена, импорт всё равно должен продолжиться.
      }
    }
  }

  static Future<Map<String, dynamic>> _buildGameExportMap(
      LibraryGameModel game,
      ) async {
    final gameMap = Map<String, dynamic>.from(game.toMap());
    final localImagePath = game.localImagePath;

    if (localImagePath == null || localImagePath.trim().isEmpty) {
      return gameMap;
    }

    final file = File(localImagePath);

    if (!await file.exists()) {
      return gameMap;
    }

    try {
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) return gameMap;

      gameMap['coverBackup'] = {
        'fileName': _safeCoverFileName(game.id, localImagePath),
        'base64': base64Encode(bytes),
      };
    } catch (_) {
      // Если локальную обложку не удалось прочитать, экспорт всё равно должен
      // завершиться. В таком случае останется imageUrl, который загрузится с
      // интернетом.
    }

    return gameMap;
  }

  static Future<Map<String, dynamic>> _buildProfileExportMap(
      UserProfileModel profile,
      ) async {
    final profileMap = Map<String, dynamic>.from(profile.toMap());
    final avatarPath = profile.avatarPath;

    if (avatarPath == null || avatarPath.trim().isEmpty) {
      return profileMap;
    }

    final file = File(avatarPath);

    if (!await file.exists()) {
      return profileMap;
    }

    try {
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) return profileMap;

      profileMap['avatarBackup'] = {
        'fileName': _safeFileName(avatarPath, fallback: 'profile_avatar.jpg'),
        'base64': base64Encode(bytes),
      };
    } catch (_) {
      // Профиль всё равно экспортируется, даже если аватар не удалось прочитать.
    }

    return profileMap;
  }

  static Future<Map<String, dynamic>> _restoreGameCover(
      Map<String, dynamic> gameMap,
      ) async {
    final rawCoverBackup = gameMap['coverBackup'];

    if (rawCoverBackup is! Map) {
      return gameMap;
    }

    final base64Text = rawCoverBackup['base64'];

    if (base64Text is! String || base64Text.trim().isEmpty) {
      return gameMap;
    }

    try {
      final bytes = base64Decode(base64Text);
      final gameId = _readGameId(gameMap['id']);
      final fileName = _safeCoverFileName(
        gameId,
        rawCoverBackup['fileName']?.toString(),
      );
      final coversDirectory = await _getCoversDirectory();
      final file = File('${coversDirectory.path}/$fileName');

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      gameMap['localImagePath'] = file.path;
    } catch (_) {
      // Если восстановление обложки не удалось, игра всё равно импортируется.
      // Тогда GameCover попробует загрузить imageUrl при наличии интернета.
    }

    gameMap.remove('coverBackup');
    return gameMap;
  }

  static Future<Map<String, dynamic>> _restoreProfileAvatar(
      Map<String, dynamic> profileMap,
      ) async {
    final rawAvatarBackup = profileMap['avatarBackup'];

    if (rawAvatarBackup is! Map) {
      return profileMap;
    }

    final base64Text = rawAvatarBackup['base64'];

    if (base64Text is! String || base64Text.trim().isEmpty) {
      return profileMap;
    }

    try {
      final bytes = base64Decode(base64Text);
      final fileName = _safeFileName(
        rawAvatarBackup['fileName']?.toString(),
        fallback: 'profile_avatar.jpg',
      );
      final profileDirectory = await _getProfileDirectory();
      final file = File('${profileDirectory.path}/$fileName');

      await file.writeAsBytes(
        bytes,
        flush: true,
      );

      profileMap['avatarPath'] = file.path;
    } catch (_) {
      // Если аватар не восстановился, профиль всё равно импортируется.
    }

    profileMap.remove('avatarBackup');
    return profileMap;
  }

  static String _buildJsonText({
    required List<Map<String, dynamic>> games,
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
        'covers': true,
        'profileAvatar': true,
      },
      'summary': {
        'gamesCount': games.length,
        'ratedCount': _ratedCountFromMaps(games),
        'stagesCount': _stagesCountFromMaps(games),
        'profileIncluded': true,
        'coversIncluded': games.where((game) {
          return game['coverBackup'] is Map;
        }).length,
      },
      'profile': profileMap,
      'games': games,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportMap);
  }

  static Future<Directory> _getCoversDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final coversDirectory = Directory(
      '${appDirectory.path}/$_coversFolderName',
    );

    if (!await coversDirectory.exists()) {
      await coversDirectory.create(recursive: true);
    }

    return coversDirectory;
  }

  static Future<Directory> _getProfileDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final profileDirectory = Directory(
      '${appDirectory.path}/$_profileFolderName',
    );

    if (!await profileDirectory.exists()) {
      await profileDirectory.create(recursive: true);
    }

    return profileDirectory;
  }

  static int _readGameId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return DateTime.now().millisecondsSinceEpoch;
  }

  static String _safeCoverFileName(int gameId, String? sourcePath) {
    final extension = _safeFileExtension(sourcePath);

    return 'game_$gameId$extension';
  }

  static String _safeFileName(String? sourcePath, {required String fallback}) {
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return fallback;
    }

    final normalizedPath = sourcePath.replaceAll('\\', '/');
    final rawName = normalizedPath.split('/').last.trim();

    if (rawName.isEmpty || rawName.contains('..')) {
      return fallback;
    }

    return rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  static String _safeFileExtension(String? sourcePath) {
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return '.jpg';
    }

    final normalizedPath = sourcePath.toLowerCase();
    final extensionStart = normalizedPath.lastIndexOf('.');

    if (extensionStart < 0 || extensionStart == normalizedPath.length - 1) {
      return '.jpg';
    }

    final extension = normalizedPath.substring(extensionStart);
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

    if (!allowedExtensions.contains(extension)) {
      return '.jpg';
    }

    return extension;
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

  static int _ratedCountFromMaps(List<Map<String, dynamic>> games) {
    return games.where((game) {
      final rating = game['userRating'];
      return rating is num && rating > 0;
    }).length;
  }

  static int _stagesCountFromMaps(List<Map<String, dynamic>> games) {
    return games.fold<int>(
      0,
          (sum, game) {
        final stages = game['stages'];
        return sum + (stages is List ? stages.length : 0);
      },
    );
  }
}
