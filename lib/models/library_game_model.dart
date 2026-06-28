import 'game_stage_model.dart';

class LibraryGameModel {
  const LibraryGameModel({
    required this.id,
    required this.title,
    required this.status,
    required this.addedAt,
    this.ratedAt,
    this.imageUrl,
    this.localImagePath,
    this.year,
    this.genre = '',
    this.platforms = const [],
    this.apiRating,
    this.apiHours = 0,
    this.userHours = 0,
    this.userMinutes = 0,
    this.userRating,
    this.comment,
    this.isFavorite = false,
    this.stages = const [],
  });

  final int id;
  final String title;
  final String status;

  final DateTime addedAt;

  final DateTime? ratedAt;

  final String? imageUrl;
  final String? localImagePath;

  final int? year;

  final String genre;
  final List<String> platforms;

  final double? apiRating;
  final int apiHours;

  final int userHours;
  final int userMinutes;
  final double? userRating;
  final String? comment;
  final bool isFavorite;
  final List<GameStageModel> stages;

  double get progressValue {
    if (apiHours <= 0) return 0;

    final played = userHours + userMinutes / 60;
    final calculated = played / apiHours;

    if (calculated > 1) return 1;
    if (calculated < 0) return 0;

    return calculated;
  }

  int get progressPercent {
    return (progressValue * 100).round();
  }

  LibraryGameModel copyWith({
    int? id,
    String? title,
    String? status,
    DateTime? addedAt,
    DateTime? ratedAt,
    bool clearRatedAt = false,
    String? imageUrl,
    String? localImagePath,
    int? year,
    String? genre,
    List<String>? platforms,
    double? apiRating,
    int? apiHours,
    int? userHours,
    int? userMinutes,
    double? userRating,
    bool clearUserRating = false,
    String? comment,
    bool clearComment = false,
    bool? isFavorite,
    List<GameStageModel>? stages,
  }) {
    return LibraryGameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
      ratedAt: clearRatedAt ? null : ratedAt ?? this.ratedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      platforms: platforms ?? this.platforms,
      apiRating: apiRating ?? this.apiRating,
      apiHours: apiHours ?? this.apiHours,
      userHours: userHours ?? this.userHours,
      userMinutes: userMinutes ?? this.userMinutes,
      userRating: clearUserRating ? null : userRating ?? this.userRating,
      comment: clearComment ? null : comment ?? this.comment,
      isFavorite: isFavorite ?? this.isFavorite,
      stages: stages ?? this.stages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status,
      'addedAt': addedAt.toIso8601String(),
      'ratedAt': ratedAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'year': year,
      'genre': genre,
      'platforms': platforms,
      'apiRating': apiRating,
      'apiHours': apiHours,
      'userHours': userHours,
      'userMinutes': userMinutes,
      'userRating': userRating,
      'comment': comment,
      'isFavorite': isFavorite,
      'stages': stages.map((stage) => stage.toMap()).toList(),
    };
  }

  factory LibraryGameModel.fromMap(Map<dynamic, dynamic> map) {
    return LibraryGameModel(
      id: _readInt(map['id']),
      title: _readString(map['title'], fallback: 'Без названия'),
      status: _readString(map['status'], fallback: 'Играю'),
      addedAt: _readDateTime(map['addedAt']) ?? DateTime.now(),
      ratedAt: _readDateTime(map['ratedAt']),
      imageUrl: _readOptionalString(map['imageUrl']),
      localImagePath: _readOptionalString(map['localImagePath']),
      year: _readNullableInt(map['year']),
      genre: _readString(map['genre'], fallback: ''),
      platforms: _readStringList(map['platforms']),
      apiRating: _readNullableDouble(map['apiRating']),
      apiHours: _readInt(map['apiHours']),
      userHours: _readInt(map['userHours']),
      userMinutes: _readInt(map['userMinutes']),
      userRating: _readNullableDouble(map['userRating']),
      comment: _readOptionalString(map['comment']),
      isFavorite: _readBool(map['isFavorite']),
      stages: _readStages(map['stages']),
    );
  }

  static int _readInt(dynamic value) {
    final parsed = _parseNumber(value)?.toInt() ?? 0;

    return parsed < 0 ? 0 : parsed;
  }

  static int? _readNullableInt(dynamic value) {
    return _parseNumber(value)?.toInt();
  }

  static double? _readNullableDouble(dynamic value) {
    return _parseNumber(value)?.toDouble();
  }

  static num? _parseNumber(dynamic value) {
    if (value is num) return value;

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return null;

      return num.tryParse(text.replaceAll(',', '.'));
    }

    return null;
  }

  static String _readString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  static String? _readOptionalString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final text = value.trim().toLowerCase();

      if (text == 'true' || text == '1' || text == 'yes') {
        return true;
      }

      if (text == 'false' || text == '0' || text == 'no') {
        return false;
      }
    }

    return false;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<GameStageModel> _readStages(dynamic value) {
    if (value is! List) return const [];

    final stages = <GameStageModel>[];

    for (final item in value) {
      if (item is! Map) continue;

      try {
        stages.add(GameStageModel.fromMap(item));
      } catch (_) {
      }
    }

    return stages;
  }
}
