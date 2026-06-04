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
  });

  final int id;
  final String title;
  final int year;
  final String genre;
  final List<String> platforms;
  final double rating;
  final int hours;
  final bool hasCover;
}