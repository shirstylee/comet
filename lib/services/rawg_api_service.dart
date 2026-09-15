import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../models/game_model.dart';

class RawgConfigurationException implements Exception {
  const RawgConfigurationException();

  @override
  String toString() =>
      'Поиск недоступен: ключ RAWG API не настроен в этой сборке.';
}

class RawgApiService {
  RawgApiService({String apiKey = ApiKeys.rawgApiKey})
      : _apiKey = apiKey.trim();

  final String _apiKey;

  static const String _baseUrl = 'api.rawg.io';
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<List<GameModel>> searchGames(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    _requireApiKey();

    final uri = Uri.https(
      _baseUrl,
      '/api/games',
      {
        'key': _apiKey,
        'search': trimmedQuery,
        'page_size': '20',
        'search_precise': 'false',
      },
    );

    final response = await _get(uri);

    if (response.statusCode != 200) {
      throw Exception('Ошибка RAWG API: ${response.statusCode}');
    }

    final decoded = _decodeJsonMap(
      response.body,
      errorMessage: 'RAWG API вернул неверный формат данных',
    );

    final results = decoded['results'];

    if (results is! List) {
      return [];
    }

    return results
        .whereType<Map>()
        .map((item) => _mapFromDynamic(item))
        .map(_safeGameFromSearchJson)
        .whereType<GameModel>()
        .toList();
  }

  Future<GameModel> getGameDetails(GameModel game) async {
    _requireApiKey();

    final detailsUri = Uri.https(
      _baseUrl,
      '/api/games/${game.id}',
      {
        'key': _apiKey,
      },
    );

    final moviesUri = Uri.https(
      _baseUrl,
      '/api/games/${game.id}/movies',
      {
        'key': _apiKey,
      },
    );

    final screenshotsUri = Uri.https(
      _baseUrl,
      '/api/games/${game.id}/screenshots',
      {
        'key': _apiKey,
      },
    );

    final gameSeriesUri = Uri.https(
      _baseUrl,
      '/api/games/${game.id}/game-series',
      {
        'key': _apiKey,
      },
    );

    final responses = await Future.wait<http.Response?>([
      _get(detailsUri),
      _safeGet(moviesUri),
      _safeGet(screenshotsUri),
      _safeGet(gameSeriesUri),
    ]);

    final detailsResponse = responses[0];

    if (detailsResponse == null || detailsResponse.statusCode != 200) {
      throw Exception(
        'Ошибка загрузки подробностей: ${detailsResponse?.statusCode ?? 'нет ответа'}',
      );
    }

    final detailsDecoded = _decodeJsonMap(
      detailsResponse.body,
      errorMessage: 'RAWG API вернул неверный формат подробностей',
    );

    final moviesResponse = responses[1];
    final screenshotsResponse = responses[2];
    final gameSeriesResponse = responses[3];

    String? trailerUrl;
    List<String> screenshots = [];
    String? franchise;

    if (moviesResponse != null && moviesResponse.statusCode == 200) {
      final moviesDecoded = _tryDecodeJsonMap(moviesResponse.body);

      if (moviesDecoded != null) {
        trailerUrl = _trailerFromJson(moviesDecoded);
      }
    }

    if (screenshotsResponse != null && screenshotsResponse.statusCode == 200) {
      final screenshotsDecoded = _tryDecodeJsonMap(screenshotsResponse.body);

      if (screenshotsDecoded != null) {
        screenshots = _screenshotsFromJson(screenshotsDecoded);
      }
    }

    if (gameSeriesResponse != null && gameSeriesResponse.statusCode == 200) {
      final gameSeriesDecoded = _tryDecodeJsonMap(gameSeriesResponse.body);

      if (gameSeriesDecoded != null) {
        franchise = _franchiseFromGameSeriesJson(
          gameSeriesDecoded,
          fallbackTitle: game.title,
        );
      }
    }

    return _gameFromDetailsJson(
      detailsDecoded,
      fallbackGame: game,
      trailerUrl: trailerUrl,
      screenshots: screenshots,
      franchise: franchise,
    );
  }

  void _requireApiKey() {
    if (_apiKey.isEmpty) {
      throw const RawgConfigurationException();
    }
  }

  Future<http.Response> _get(Uri uri) {
    return http.get(uri).timeout(_requestTimeout);
  }

  Future<http.Response?> _safeGet(Uri uri) async {
    try {
      return await _get(uri);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeJsonMap(
      String body, {
        required String errorMessage,
      }) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return _mapFromDynamic(decoded);
      }
    } catch (_) {
      throw Exception(errorMessage);
    }

    throw Exception(errorMessage);
  }

  Map<String, dynamic>? _tryDecodeJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return _mapFromDynamic(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Map<String, dynamic> _mapFromDynamic(Map map) {
    return map.map(
          (key, value) => MapEntry(key.toString(), value),
    );
  }

  GameModel? _safeGameFromSearchJson(Map<String, dynamic> json) {
    try {
      return _gameFromSearchJson(json);
    } catch (_) {
      return null;
    }
  }

  GameModel _gameFromSearchJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);

    if (id <= 0) {
      throw const FormatException('У игры отсутствует корректный id');
    }

    final released = _readString(json['released']);
    final year = _yearFromReleasedDate(released);
    final imageUrl = _readString(json['background_image']);

    return GameModel(
      id: id,
      title: _readString(json['name']) ?? 'Без названия',
      year: year,
      genre: _firstGenreFromJson(json),
      platforms: _platformsFromJson(json),
      rating: _readDouble(json['rating']),
      hours: _readInt(json['playtime']),
      hasCover: imageUrl != null && imageUrl.trim().isNotEmpty,
      imageUrl: imageUrl,
      released: released,
      metacritic: _readNullableInt(json['metacritic']),
      ratingsCount: _readNullableInt(json['ratings_count']),
      ratingTop: _readNullableInt(json['rating_top']),
      ratings: _ratingsFromJson(json),
      tags: _tagsFromJson(json),
    );
  }

  GameModel _gameFromDetailsJson(
      Map<String, dynamic> json, {
        required GameModel fallbackGame,
        required String? trailerUrl,
        required List<String> screenshots,
        required String? franchise,
      }) {
    final released = _readString(json['released']) ?? fallbackGame.released;
    final year = _yearFromReleasedDate(released);
    final imageUrl = _readString(json['background_image']) ?? fallbackGame.imageUrl;

    final description = _cleanDescription(
      _readString(json['description_raw']) ??
          _readString(json['description']) ??
          fallbackGame.description,
    );

    return fallbackGame.copyWith(
      id: _readNullableInt(json['id']) ?? fallbackGame.id,
      title: _readString(json['name']) ?? fallbackGame.title,
      year: year,
      genre: _preserveSearchGenre(fallbackGame.genre, json),
      platforms: _platformsFromJson(json, fallback: fallbackGame.platforms),
      rating: _readNullableDouble(json['rating']) ?? fallbackGame.rating,
      hours: _readNullableInt(json['playtime']) ?? fallbackGame.hours,
      hasCover: imageUrl != null && imageUrl.trim().isNotEmpty,
      imageUrl: imageUrl,
      released: released,
      description: description,
      developer: _developerFromJson(json) ?? fallbackGame.developer,
      metacritic: _readNullableInt(json['metacritic']) ?? fallbackGame.metacritic,
      ratingsCount:
      _readNullableInt(json['ratings_count']) ?? fallbackGame.ratingsCount,
      esrbRating: _esrbRatingFromJson(json) ?? fallbackGame.esrbRating,
      website: _readString(json['website']) ?? fallbackGame.website,
      trailerUrl: trailerUrl ?? fallbackGame.trailerUrl,
      screenshots: screenshots.isEmpty ? fallbackGame.screenshots : screenshots,
      ratings: _ratingsFromJson(json, fallback: fallbackGame.ratings),
      tags: _tagsFromJson(json, fallback: fallbackGame.tags),
      franchise: franchise ?? fallbackGame.franchise,
      ratingTop: _readNullableInt(json['rating_top']) ?? fallbackGame.ratingTop,
    );
  }

  String _preserveSearchGenre(
      String searchGenre,
      Map<String, dynamic> detailsJson,
      ) {
    final cleanSearchGenre = searchGenre.trim();

    if (cleanSearchGenre.isNotEmpty) {
      return cleanSearchGenre;
    }

    return _firstGenreFromJson(detailsJson);
  }

  String _firstGenreFromJson(
      Map<String, dynamic> json, {
        String fallback = '',
      }) {
    final rawGenres = json['genres'];

    if (rawGenres is! List) {
      return fallback;
    }

    final genres = rawGenres
        .whereType<Map>()
        .map(_mapFromDynamic)
        .map((genre) => _readString(genre['name']) ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (genres.isEmpty) {
      return fallback;
    }

    return genres.first;
  }

  List<String> _platformsFromJson(
      Map<String, dynamic> json, {
        List<String> fallback = const [],
      }) {
    final rawPlatforms = json['platforms'];

    if (rawPlatforms is! List) {
      return fallback;
    }

    final platforms = rawPlatforms.whereType<Map>().map(_mapFromDynamic).map((item) {
      final platform = item['platform'];

      if (platform is Map) {
        return _readString(_mapFromDynamic(platform)['name']) ?? '';
      }

      return '';
    }).where((name) => name.trim().isNotEmpty).toList();

    if (platforms.isEmpty) {
      return fallback;
    }

    return platforms;
  }

  String? _developerFromJson(Map<String, dynamic> json) {
    final rawDevelopers = json['developers'];

    if (rawDevelopers is! List || rawDevelopers.isEmpty) {
      return null;
    }

    final developers = rawDevelopers
        .whereType<Map>()
        .map(_mapFromDynamic)
        .map((developer) => _readString(developer['name']) ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (developers.isEmpty) {
      return null;
    }

    return developers.join(', ');
  }

  String? _esrbRatingFromJson(Map<String, dynamic> json) {
    final esrbRating = json['esrb_rating'];

    if (esrbRating is Map) {
      final name = _readString(_mapFromDynamic(esrbRating)['name']);

      if (name != null && name.trim().isNotEmpty) {
        return name;
      }
    }

    return null;
  }

  String? _trailerFromJson(Map<String, dynamic> json) {
    final results = json['results'];

    if (results is! List || results.isEmpty) {
      return null;
    }

    for (final item in results) {
      if (item is! Map) continue;

      final data = _mapFromDynamic(item)['data'];

      if (data is Map) {
        final dataMap = _mapFromDynamic(data);
        final maxVideo = _readString(dataMap['max']);

        if (maxVideo != null && maxVideo.trim().isNotEmpty) {
          return maxVideo;
        }

        final video480 = _readString(dataMap['480']);

        if (video480 != null && video480.trim().isNotEmpty) {
          return video480;
        }
      }
    }

    return null;
  }

  List<String> _screenshotsFromJson(Map<String, dynamic> json) {
    final results = json['results'];

    if (results is! List) {
      return [];
    }

    return results
        .whereType<Map>()
        .map(_mapFromDynamic)
        .map((screenshot) => _readString(screenshot['image']) ?? '')
        .where((imageUrl) => imageUrl.trim().isNotEmpty)
        .take(10)
        .toList();
  }

  List<GameRatingModel> _ratingsFromJson(
      Map<String, dynamic> json, {
        List<GameRatingModel> fallback = const [],
      }) {
    final rawRatings = json['ratings'];

    if (rawRatings is! List) {
      return fallback;
    }

    final ratings = rawRatings.whereType<Map>().map(_mapFromDynamic).map((item) {
      return GameRatingModel(
        id: _readInt(item['id']),
        title: _readString(item['title']) ?? '',
        count: _readInt(item['count']),
        percent: _readDouble(item['percent']),
      );
    }).where((rating) {
      return rating.title.trim().isNotEmpty &&
          (rating.count > 0 || rating.percent > 0);
    }).toList();

    if (ratings.isEmpty) {
      return fallback;
    }

    return ratings;
  }

  List<String> _tagsFromJson(
      Map<String, dynamic> json, {
        List<String> fallback = const [],
      }) {
    final rawTags = json['tags'];

    if (rawTags is! List) {
      return fallback;
    }

    final tags = rawTags
        .whereType<Map>()
        .map(_mapFromDynamic)
        .map((tag) => _readString(tag['name']) ?? '')
        .where((name) => name.trim().isNotEmpty)
        .take(24)
        .toList();

    if (tags.isEmpty) {
      return fallback;
    }

    return tags;
  }

  String? _franchiseFromGameSeriesJson(
      Map<String, dynamic> json, {
        required String fallbackTitle,
      }) {
    final results = json['results'];

    if (results is! List || results.isEmpty) {
      return null;
    }

    final relatedGames = results
        .whereType<Map>()
        .map(_mapFromDynamic)
        .map((item) => _readString(item['name']) ?? '')
        .where((name) => name.trim().isNotEmpty)
        .where((name) => name.trim().toLowerCase() != fallbackTitle.trim().toLowerCase())
        .toList();

    if (relatedGames.isEmpty) {
      return null;
    }

    return _franchiseNameFromTitle(fallbackTitle);
  }

  String? _franchiseNameFromTitle(String title) {
    var text = title.trim();

    if (text.isEmpty) {
      return null;
    }

    text = text.split(RegExp(r'[:–—-]')).first.trim();
    text = text.replaceAll(
      RegExp(
        r'\s+(Remastered|Remake|Definitive Edition|Complete Edition|Game of the Year Edition|GOTY|Enhanced Edition).*$',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\s+(I|II|III|IV|V|VI|VII|VIII|IX|X|\d+)$'),
      '',
    );

    text = text.trim();

    return text.isEmpty ? null : text;
  }

  String? _cleanDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return null;
    }

    return description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .trim();
  }

  int? _yearFromReleasedDate(String? released) {
    if (released == null || released.length < 4) {
      return null;
    }

    return int.tryParse(released.substring(0, 4));
  }

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  int _readInt(dynamic value) {
    return _readNullableInt(value) ?? 0;
  }

  int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().trim());
  }

  double _readDouble(dynamic value) {
    return _readNullableDouble(value) ?? 0;
  }

  double? _readNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().trim().replaceAll(',', '.'));
  }
}
