import 'game_stage_model.dart';

class LibraryGameModel {
  const LibraryGameModel({
    required this.id,
    required this.title,
    required this.status,
    required this.addedAt,
    this.imageUrl,
    this.localImagePath,
    this.year,
    this.genre = 'Action',
    this.platforms = const [],
    this.apiRating,
    this.apiHours = 80,
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

  // Ссылка на оригинальную обложку из RAWG.
  final String? imageUrl;

  // Путь к сжатой обложке, которая хранится на устройстве.
  // В Hive сохраняем только путь, а не саму картинку.
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
    String? comment,
    bool? isFavorite,
    List<GameStageModel>? stages,
  }) {
    return LibraryGameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      platforms: platforms ?? this.platforms,
      apiRating: apiRating ?? this.apiRating,
      apiHours: apiHours ?? this.apiHours,
      userHours: userHours ?? this.userHours,
      userMinutes: userMinutes ?? this.userMinutes,
      userRating: userRating ?? this.userRating,
      comment: comment ?? this.comment,
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

    return LibraryGameModel(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String? ?? 'Без названия',
      status: map['status'] as String? ?? 'Играю',
      addedAt: map['addedAt'] == null
          ? DateTime.now()
          : DateTime.tryParse(map['addedAt'].toString()) ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      localImagePath: map['localImagePath'] as String?,
      year: map['year'] as int?,
      genre: map['genre'] as String? ?? 'Action',
      platforms: rawPlatforms is List
          ? rawPlatforms.map((platform) => platform.toString()).toList()
          : const [],
      apiRating: (map['apiRating'] as num?)?.toDouble(),
      apiHours: map['apiHours'] as int? ?? 80,
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