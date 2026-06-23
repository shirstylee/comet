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

  String get genreText {
    final genre = game.genre.trim();

    if (genre.isEmpty) {
      return 'Жанр не указан';
    }

    return genre;
  }

  String get subtitleText {
    final genre = game.genre.trim();

    if (genre.isEmpty) {
      return yearText;
    }

    return '$genre • $yearText';
  }

  String get hoursText {
    if (game.hours <= 0) {
      return '—';
    }

    return '${game.hours}ч.';
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
    final containsGameFuture = LibraryStorage.containsGame(game.id);

    showModalBottomSheet(
      context: pageContext,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (bottomSheetContext) {
        return FutureBuilder<bool>(
          future: containsGameFuture,
          builder: (sheetContext, snapshot) {
            final bool isInLibrary = snapshot.data ?? false;
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF151A1A),
                      Color(0xFF202424),
                      Color(0xFF141A1A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0x5532B8C6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.32),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: accent.withOpacity(0.075),
                      blurRadius: 22,
                      offset: const Offset(0, 0),
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
                          color: const Color(0xFF75EEFD).withOpacity(0.28),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _SmallCover(
                            imageUrl: game.imageUrl,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: 70,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  _GameInfoBadges(
                                    yearText: yearText,
                                    genreText: genreText,
                                    compact: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _BottomSheetActionButton(
                        text: isInLibrary
                            ? 'Открыть в коллекции'
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
          color: const Color(0xFF081F23),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0x5532B8C6),
            width: 1.1,
          ),
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
                            _CardMenuButton(
                              onTap: () => _showGameActions(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GameInfoBadges(
                          yearText: yearText,
                          genreText: genreText,
                          compact: true,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              height: 26,
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF232626),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: green.withOpacity(0.28),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                      height: 1.2,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _GameHoursPill(
                                text: hoursText,
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

class _CardMenuButton extends StatelessWidget {
  const _CardMenuButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0x99111414),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: Color(0xFFF4F3F3),
          size: 22,
        ),
      ),
    );
  }
}

class _GameInfoBadges extends StatelessWidget {
  const _GameInfoBadges({
    required this.yearText,
    required this.genreText,
    this.compact = false,
  });

  final String yearText;
  final String genreText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 26 : 30,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _GameInfoBadge(
              text: genreText,
              compact: compact,
            ),
            const SizedBox(width: 8),
            _GameInfoBadge(
              text: yearText,
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameInfoBadge extends StatelessWidget {
  const _GameInfoBadge({
    required this.text,
    required this.compact,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 26 : 30,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF75EEFD),
          fontSize: compact ? 11 : 12,
          height: compact ? 1.15 : 1.2,
          fontWeight: FontWeight.w900,
          letterSpacing: compact ? -0.1 : 0.6,
        ),
      ),
    );
  }
}

class _GameHoursPill extends StatelessWidget {
  const _GameHoursPill({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Color(0xFF75EEFD),
            size: 13,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
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
        ? const Color(0xFF75EEFD)
        : const Color(0xFF00575F);

    final List<Color> gradientColors = isDisabled
        ? const [
      Color(0xFF2B2F2F),
      Color(0xFF1D2020),
    ]
        : isLibraryAction
        ? const [
      Color(0xFF1D3033),
      Color(0xFF132224),
    ]
        : const [
      Color(0xFF75EEFD),
      Color(0xFF25B0BE),
    ];

    final Color borderColor = isDisabled
        ? Colors.white.withOpacity(0.06)
        : isLibraryAction
        ? const Color(0x6632B8C6)
        : Colors.transparent;

    final Color shadowColor = isDisabled
        ? Colors.black.withOpacity(0.16)
        : isLibraryAction
        ? Colors.black.withOpacity(0.22)
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
