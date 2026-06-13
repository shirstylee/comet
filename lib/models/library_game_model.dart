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

  /// Дата добавления игры в библиотеку.
  final DateTime addedAt;

  /// Реальная дата выставления/изменения пользовательской оценки.
  /// Берётся с телефона пользователя через DateTime.now().
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
    final rawStages = map['stages'];
    final rawPlatforms = map['platforms'];

    final rawGenre = map['genre'];
    final cleanGenre = rawGenre == null ? '' : rawGenre.toString().trim();

    final rawApiHours = map['apiHours'];
    final parsedApiHours = rawApiHours is num ? rawApiHours.toInt() : 0;

    final parsedAddedAt = map['addedAt'] == null
        ? DateTime.now()
        : DateTime.tryParse(map['addedAt'].toString()) ?? DateTime.now();

    final parsedRatedAt = map['ratedAt'] == null
        ? null
        : DateTime.tryParse(map['ratedAt'].toString());

    return LibraryGameModel(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? 'Без названия',
      status: map['status'] as String? ?? 'Играю',
      addedAt: parsedAddedAt,
      ratedAt: parsedRatedAt,
      imageUrl: map['imageUrl'] as String?,
      localImagePath: map['localImagePath'] as String?,
      year: map['year'] as int?,
      genre: cleanGenre,
      platforms: rawPlatforms is List
          ? rawPlatforms.map((platform) => platform.toString()).toList()
          : const [],
      apiRating: (map['apiRating'] as num?)?.toDouble(),
      apiHours: parsedApiHours,
      userHours: map['userHours'] as int? ?? 0,
      userMinutes: map['userMinutes'] as int? ?? 0,
      userRating: (map['userRating'] as num?)?.toDouble(),
      comment: map['comment'] as String?,
      isFavorite: map['isFavorite'] as bool? ?? false,
      stages: rawStages is List
          ? rawStages.map((stage) => GameStageModel.fromMap(stage)).toList()
          : const [],
    );
  }
}