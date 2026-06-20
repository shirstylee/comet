import 'package:flutter/material.dart';

import '../models/game_model.dart';
import '../models/game_stage_model.dart';
import '../models/library_game_model.dart';
import '../screens/details/game_details_screen.dart';
import '../screens/game_progress/game_progress_screen.dart';
import '../services/cover_cache_service.dart';
import '../storage/library_storage.dart';
import '../widgets/game_cover.dart';

class GameSearchCard extends StatefulWidget {
  const GameSearchCard({
    super.key,
    required this.game,
    required this.index,
  });

  final GameModel game;
  final int index;

  @override
  State<GameSearchCard> createState() => _GameSearchCardState();
}

class _GameSearchCardState extends State<GameSearchCard>
    with AutomaticKeepAliveClientMixin<GameSearchCard> {
  GameModel get game => widget.game;
  int get index => widget.index;

  @override
  bool get wantKeepAlive => true;

  String get yearText {
    final year = game.year;

    if (year == null) {
      return 'Год неизвестен';
    }

    return year.toString();
  }

  String get subtitleText {
    final genre = game.genre.trim();

    if (genre.isEmpty) {
      return yearText;
    }

    return '$yearText • $genre';
  }

  static const Color cardColor = Color(0xFF111414);
  static const Color green = Color(0xFFBBFFB3);
  static const Color accent = Color(0xFF75EEFD);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  Future<void> _openDetails(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameDetailsScreen(game: game),
      ),
    );

    if (!context.mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openGameProgressScreen(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final savedGame = await LibraryStorage.getGameById(game.id);

    if (!context.mounted) return;

    if (savedGame == null) {
      _showSnackBar(
        context,
        'Игра не найдена в коллекции',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameProgressScreen(
          gameId: savedGame.id,
          title: savedGame.title,
          status: savedGame.status,
          userHours: savedGame.userHours,
          userMinutes: savedGame.userMinutes,
          apiHours: savedGame.apiHours,
          rating: savedGame.userRating ?? savedGame.apiRating ?? 0,
        ),
      ),
    );

    if (!context.mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _addGameToLibrary(BuildContext context) async {
    try {
      final alreadyAdded = await LibraryStorage.containsGame(game.id);

      if (!context.mounted) return;

      if (alreadyAdded) {
        await _openGameProgressScreen(context);
        return;
      }

      _showSnackBar(
        context,
        'Сохраняю ${game.title} в коллекцию...',
      );

      final localImagePath = await CoverCacheService.saveCompressedCover(
        gameId: game.id,
        imageUrl: game.imageUrl,
      );

      final libraryGame = LibraryGameModel(
        id: game.id,
        title: game.title,
        status: 'Планирую',
        addedAt: DateTime.now(),
        imageUrl: game.imageUrl,
        localImagePath: localImagePath,
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

      _showSnackBar(
        context,
        localImagePath == null
            ? 'Игра добавлена, но обложка не сохранилась'
            : '${game.title} добавлена в коллекцию',
      );
    } catch (error) {
      if (!context.mounted) return;

      _showSnackBar(
        context,
        'Не удалось добавить игру в коллекцию',
      );
    }
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
    FocusManager.instance.primaryFocus?.unfocus();

    final pageContext = context;

    showModalBottomSheet(
      context: pageContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (bottomSheetContext) {
        return FutureBuilder<bool>(
          future: LibraryStorage.containsGame(game.id),
          builder: (sheetContext, snapshot) {
            final bool isInLibrary = snapshot.data ?? false;
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting;

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
                            imageUrl: game.imageUrl,
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
                                  subtitleText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                      _BottomSheetActionButton(
                        text: isInLibrary
                            ? 'Открыть в коллекции'
                            : isLoading
                            ? 'Проверяем коллекцию...'
                            : 'Добавить в коллекцию',
                        icon: isInLibrary
                            ? Icons.folder_open_rounded
                            : Icons.add_rounded,
                        isDisabled: isLoading,
                        isLibraryAction: isInLibrary,
                        onTap: isLoading
                            ? null
                            : () async {
                          Navigator.pop(bottomSheetContext);

                          if (!pageContext.mounted) return;

                          if (isInLibrary) {
                            await _openGameProgressScreen(pageContext);
                            return;
                          }

                          await _addGameToLibrary(pageContext);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onTap: () {
        _openDetails(context);
      },
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
              imageUrl: game.imageUrl,
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
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _BottomSheetActionButton extends StatelessWidget {
  const _BottomSheetActionButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
    this.isLibraryAction = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDisabled;
  final bool isLibraryAction;

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDisabled
        ? const Color(0xFFAAABAB)
        : isLibraryAction
        ? const Color(0xFF07370D)
        : const Color(0xFF00575F);

    final List<Color> gradientColors = isDisabled
        ? const [
      Color(0xFF2B2F2F),
      Color(0xFF1D2020),
    ]
        : isLibraryAction
        ? const [
      Color(0xFFBBFFB3),
      Color(0xFF70E36C),
    ]
        : const [
      Color(0xFF75EEFD),
      Color(0xFF25B0BE),
    ];

    final Color borderColor = isDisabled
        ? Colors.white.withOpacity(0.06)
        : isLibraryAction
        ? const Color(0xFFBBFFB3).withOpacity(0.28)
        : Colors.transparent;

    final Color shadowColor = isDisabled
        ? Colors.black.withOpacity(0.16)
        : isLibraryAction
        ? const Color(0xFFBBFFB3).withOpacity(0.18)
        : const Color(0xFF75EEFD).withOpacity(0.2);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: textColor,
            size: 26,
          ),
          label: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: textColor,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCover extends StatelessWidget {
  const _GameCover({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return GameCover(
      width: 112,
      height: 160,
      imageUrl: imageUrl,
      borderRadius: 0,
      iconSize: 34,
      gradientOpacity: 0.42,
    );
  }
}

class _SmallCover extends StatelessWidget {
  const _SmallCover({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return GameCover(
      width: 54,
      height: 70,
      imageUrl: imageUrl,
      borderRadius: 10,
      iconSize: 24,
      gradientOpacity: 0.14,
    );
  }
}
