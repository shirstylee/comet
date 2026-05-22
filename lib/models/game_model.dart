class GameModel {
  const GameModel({
    required this.title,
    required this.year,
    required this.genre,
    required this.rating,
    required this.hours,
    this.hasCover = true,
  });

  final String title;
  final int year;
  final String genre;
  final double rating;
  final int hours;
  final bool hasCover;
}