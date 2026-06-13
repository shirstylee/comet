import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';
import '../models/game_model.dart';

class RawgApiService {
  RawgApiService();

  static const String _baseUrl = 'api.rawg.io';

  Future<List<GameModel>> searchGames(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final uri = Uri.https(
      _baseUrl,
      '/api/games',
      {
        'key': ApiKeys.rawgApiKey,
        'search': trimmedQuery,
        'page_size': '20',
        'search_precise': 'false',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Ошибка RAWG API: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('RAWG API вернул неверный формат данных');
    }

    final results = decoded['results'];

    if (results is! List) {
      return [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(_gameFromSearchJson)
        .toList();
  }

  Future<GameModel> getGameDetails(GameModel game) async {
    final detailsUri = Uri.https(
      _baseUrl,
      '/api/games/${game.id}',
      {
        'key': ApiKeys.rawgApiKey,
      },
    );

    final moviesUri = Uri.https(
      _baseUrl,
      '/api/games/${game.id}/movies',
      {
        'key': ApiKeys.rawgApiKey,
      },
    );

    final screenshotsUri = Uri.https(
      _baseUrl,
      '/api/games/${game.id}/screenshots',
      {
        'key': ApiKeys.rawgApiKey,
      },
    );

    final detailsResponse = await http.get(detailsUri);

    if (detailsResponse.statusCode != 200) {
      throw Exception('Ошибка загрузки подробностей: ${detailsResponse.statusCode}');
    }

    final detailsDecoded = jsonDecode(detailsResponse.body);

    if (detailsDecoded is! Map<String, dynamic>) {
      throw Exception('RAWG API вернул неверный формат подробностей');
    }

    String? trailerUrl;
    List<String> screenshots = [];

    try {
      final moviesResponse = await http.get(moviesUri);

      if (moviesResponse.statusCode == 200) {
        final moviesDecoded = jsonDecode(moviesResponse.body);

        if (moviesDecoded is Map<String, dynamic>) {
          trailerUrl = _trailerFromJson(moviesDecoded);
        }
      }
    } catch (_) {
      trailerUrl = null;
    }

    try {
      final screenshotsResponse = await http.get(screenshotsUri);

      if (screenshotsResponse.statusCode == 200) {
        final screenshotsDecoded = jsonDecode(screenshotsResponse.body);

        if (screenshotsDecoded is Map<String, dynamic>) {
          screenshots = _screenshotsFromJson(screenshotsDecoded);
        }
      }
    } catch (_) {
      screenshots = [];
    }

    return _gameFromDetailsJson(
      detailsDecoded,
      fallbackGame: game,
      trailerUrl: trailerUrl,
      screenshots: screenshots,
    );
  }

  GameModel _gameFromSearchJson(Map<String, dynamic> json) {
    final released = json['released']?.toString();
    final year = _yearFromReleasedDate(released);
    final imageUrl = json['background_image']?.toString();

    return GameModel(
      id: json['id'] as int? ?? 0,
      title: json['name']?.toString() ?? 'Без названия',
      year: year,
      genre: _firstGenreFromJson(json),
      platforms: _platformsFromJson(json),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      hours: json['playtime'] as int? ?? 0,
      hasCover: imageUrl != null && imageUrl.trim().isNotEmpty,
      imageUrl: imageUrl,
      released: released,
      metacritic: json['metacritic'] as int?,
      ratingsCount: json['ratings_count'] as int?,
    );
  }

  GameModel _gameFromDetailsJson(
      Map<String, dynamic> json, {
        required GameModel fallbackGame,
        required String? trailerUrl,
        required List<String> screenshots,
      }) {
    final released = json['released']?.toString() ?? fallbackGame.released;
    final year = _yearFromReleasedDate(released);
    final imageUrl = json['background_image']?.toString() ?? fallbackGame.imageUrl;

    final description = _cleanDescription(
      json['description_raw']?.toString() ??
          json['description']?.toString() ??
          fallbackGame.description,
    );

    return fallbackGame.copyWith(
      id: json['id'] as int? ?? fallbackGame.id,
      title: json['name']?.toString() ?? fallbackGame.title,
      year: year,

      // ВАЖНО:
      // Жанр берём из карточки поиска и больше не перезаписываем его
      // данными detail-запроса RAWG. У RAWG порядок жанров в search и details
      // может отличаться, из-за этого в поиске могло быть Adventure,
      // а на экране игры — Action.
      genre: _preserveSearchGenre(fallbackGame.genre, json),

      platforms: _platformsFromJson(json, fallback: fallbackGame.platforms),
      rating: (json['rating'] as num?)?.toDouble() ?? fallbackGame.rating,
      hours: json['playtime'] as int? ?? fallbackGame.hours,
      hasCover: imageUrl != null && imageUrl.trim().isNotEmpty,
      imageUrl: imageUrl,
      released: released,
      description: description,
      developer: _developerFromJson(json) ?? fallbackGame.developer,
      metacritic: json['metacritic'] as int? ?? fallbackGame.metacritic,
      ratingsCount: json['ratings_count'] as int? ?? fallbackGame.ratingsCount,
      esrbRating: _esrbRatingFromJson(json) ?? fallbackGame.esrbRating,
      website: json['website']?.toString() ?? fallbackGame.website,
      trailerUrl: trailerUrl ?? fallbackGame.trailerUrl,
      screenshots: screenshots.isEmpty ? fallbackGame.screenshots : screenshots,
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
        String fallback = 'Action',
      }) {
    final rawGenres = json['genres'];

    if (rawGenres is! List) {
      return fallback;
    }

    final genres = rawGenres
        .whereType<Map<String, dynamic>>()
        .map((genre) => genre['name']?.toString() ?? '')
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

    final platforms = rawPlatforms
        .whereType<Map<String, dynamic>>()
        .map((item) {
      final platform = item['platform'];

      if (platform is Map<String, dynamic>) {
        return platform['name']?.toString() ?? '';
      }

      return '';
    })
        .where((name) => name.trim().isNotEmpty)
        .toList();

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
        .whereType<Map<String, dynamic>>()
        .map((developer) => developer['name']?.toString() ?? '')
        .where((name) => name.trim().isNotEmpty)
        .toList();

    if (developers.isEmpty) {
      return null;
    }

    return developers.join(', ');
  }

  String? _esrbRatingFromJson(Map<String, dynamic> json) {
    final esrbRating = json['esrb_rating'];

    if (esrbRating is Map<String, dynamic>) {
      final name = esrbRating['name']?.toString();

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
      if (item is! Map<String, dynamic>) continue;

      final data = item['data'];

      if (data is Map<String, dynamic>) {
        final maxVideo = data['max']?.toString();

        if (maxVideo != null && maxVideo.trim().isNotEmpty) {
          return maxVideo;
        }

        final video480 = data['480']?.toString();

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
        .whereType<Map<String, dynamic>>()
        .map((screenshot) => screenshot['image']?.toString() ?? '')
        .where((imageUrl) => imageUrl.trim().isNotEmpty)
        .take(10)
        .toList();
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

  int _yearFromReleasedDate(String? released) {
    if (released == null || released.length < 4) {
      return DateTime.now().year;
    }

    return int.tryParse(released.substring(0, 4)) ?? DateTime.now().year;
  }
}
