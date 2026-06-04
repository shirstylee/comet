import 'package:flutter/material.dart';

import '../models/game_model.dart';
import '../models/game_stage_model.dart';
import '../models/library_game_model.dart';
import '../screens/details/game_details_screen.dart';
import '../storage/library_storage.dart';

class GameSearchCard extends StatelessWidget {
  const GameSearchCard({
    super.key,
    required this.game,
    required this.index,
  });

  final GameModel game;
  final int index;

  static const Color cardColor = Color(0xFF111414);
  static const Color green = Color(0xFFBBFFB3);
  static const Color accent = Color(0xFF75EEFD);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailsScreen(game: game),
      ),
    );
  }

  Future<void> _addGameToLibrary(BuildContext context) async {
    final alreadyAdded = await LibraryStorage.containsGame(game.id);

    if (!context.mounted) return;

    if (alreadyAdded) {
      Navigator.pop(context);

      _showSnackBar(
        context,
        '${game.title} уже есть в коллекции',
      );

      return;
    }

    final libraryGame = LibraryGameModel(
      id: game.id,
      title: game.title,
      status: 'Планирую',
      addedAt: DateTime.now(),
      year: game.year,
      genre: game.genre,
      platforms: game.platforms,
      apiRating: game.rating,
      apiHours: game.hours,
      userHours: 0,
      userMinutes: 0,
      userRating: null,
      comment: null,
      isFavorite: false,
      stages: const [
        GameStageModel(
          title: 'Начало игры',
          subtitle: 'В процессе',
          isDone: false,
        ),
      ],
    );

    await LibraryStorage.addGame(libraryGame);

    if (!context.mounted) return;

    Navigator.pop(context);

    _showSnackBar(
      context,
      '${game.title} добавлена в коллекцию',
    );
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1A1D1D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showGameActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111414),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.16),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _SmallCover(
                        hasCover: game.hasCover,
                        index: index,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              game.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 18,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${game.year} • ${game.genre}',
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF75EEFD),
                            Color(0xFF25B0BE),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _addGameToLibrary(context),
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF00575F),
                          size: 26,
                        ),
                        label: const Text(
                          'Добавить в коллекцию',
                          style: TextStyle(
                            color: Color(0xFF00575F),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            _GameCover(
              hasCover: game.hasCover,
              index: index,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                game.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: textPrimary,
                                  fontSize: 18,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showGameActions(context),
                              child: const SizedBox(
                                width: 28,
                                height: 28,
                                child: Icon(
                                  Icons.more_vert_rounded,
                                  color: textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${game.year} • ${game.genre}',
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF232626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                game.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${game.hours}h',
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCover extends StatelessWidget {
  const _GameCover({
    required this.hasCover,
    required this.index,
  });

  final bool hasCover;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (!hasCover) {
      return Container(
        width: 112,
        height: 160,
        color: const Color(0xFF1D2020),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: Color(0x80AAABAB),
            size: 34,
          ),
        ),
      );
    }

    final colors = _coverGradients[index % _coverGradients.length];

    return Container(
      width: 112,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF111414).withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallCover extends StatelessWidget {
  const _SmallCover({
    required this.hasCover,
    required this.index,
  });

  final bool hasCover;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (!hasCover) {
      return Container(
        width: 54,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1D2020),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0x80AAABAB),
          size: 24,
        ),
      );
    }

    final colors = _coverGradients[index % _coverGradients.length];

    return Container(
      width: 54,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

const List<List<Color>> _coverGradients = [
  [
    Color(0xFF172026),
    Color(0xFFB44A2E),
  ],
  [
    Color(0xFF0E1C1D),
    Color(0xFF355962),
  ],
  [
    Color(0xFF1D2020),
    Color(0xFF303636),
  ],
  [
    Color(0xFF21102E),
    Color(0xFFFF2BD6),
  ],
  [
    Color(0xFF162311),
    Color(0xFFD2B35E),
  ],
];