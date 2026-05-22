import '../models/game_model.dart';

const List<GameModel> mockGames = [
  GameModel(
    title: 'The Witcher 3: Wild Hunt',
    year: 2015,
    genre: 'RPG',
    rating: 9.8,
    hours: 150,
  ),
  GameModel(
    title: 'The Witcher 2: Assassins of Kings',
    year: 2011,
    genre: 'RPG',
    rating: 8.9,
    hours: 40,
  ),
  GameModel(
    title: 'The Witcher',
    year: 2007,
    genre: 'RPG',
    rating: 8.2,
    hours: 55,
    hasCover: false,
  ),
  GameModel(
    title: 'Cyberpunk 2077',
    year: 2020,
    genre: 'RPG',
    rating: 8.7,
    hours: 70,
  ),
  GameModel(
    title: 'Elden Ring',
    year: 2022,
    genre: 'Action RPG',
    rating: 9.6,
    hours: 120,
  ),
];