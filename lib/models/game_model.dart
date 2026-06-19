class GameModel {
  const GameModel({
    required this.id,
    required this.title,
    required this.year,
    required this.genre,
    required this.platforms,
    required this.rating,
    required this.hours,
    this.hasCover = true,
    this.imageUrl,
    this.released,
    this.description,
    this.developer,
    this.metacritic,
    this.ratingsCount,
    this.esrbRating,
    this.website,
    this.trailerUrl,
    this.screenshots = const [],
  });

  final int id;
  final String title;
  final int? year;
  final String genre;
  final List<String> platforms;
  final double rating;
  final int hours;
  final bool hasCover;

  final String? imageUrl;
  final String? released;
  final String? description;
  final String? developer;
  final int? metacritic;
  final int? ratingsCount;
  final String? esrbRating;
  final String? website;
  final String? trailerUrl;
  final List<String> screenshots;

  GameModel copyWith({
    int? id,
    String? title,
    int? year,
    String? genre,
    List<String>? platforms,
    double? rating,
    int? hours,
    bool? hasCover,
    String? imageUrl,
    String? released,
    String? description,
    String? developer,
    int? metacritic,
    int? ratingsCount,
    String? esrbRating,
    String? website,
    String? trailerUrl,
    List<String>? screenshots,
  }) {
    return GameModel(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      platforms: platforms ?? this.platforms,
      rating: rating ?? this.rating,
      hours: hours ?? this.hours,
      hasCover: hasCover ?? this.hasCover,
      imageUrl: imageUrl ?? this.imageUrl,
      released: released ?? this.released,
      description: description ?? this.description,
      developer: developer ?? this.developer,
      metacritic: metacritic ?? this.metacritic,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      esrbRating: esrbRating ?? this.esrbRating,
      website: website ?? this.website,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      screenshots: screenshots ?? this.screenshots,
    );
  }
}
