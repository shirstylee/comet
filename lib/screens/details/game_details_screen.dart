import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/game_model.dart';
import '../../models/game_stage_model.dart';
import '../../models/library_game_model.dart';
import '../../services/cover_cache_service.dart';
import '../../services/rawg_api_service.dart';
import '../../storage/library_storage.dart';
import '../../widgets/game_cover.dart';
import '../game_progress/game_progress_screen.dart';

class GameDetailsScreen extends StatefulWidget {
  const GameDetailsScreen({
    super.key,
    required this.game,
  });

  final GameModel game;

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  static const Color background = Color(0xFF0C0F0F);

  final RawgApiService rawgApiService = RawgApiService();

  late GameModel game;

  bool isDescriptionExpanded = false;
  bool isLoadingDetails = true;
  bool isInLibrary = false;
  String? detailsError;

  @override
  void initState() {
    super.initState();

    game = widget.game;

    _loadGameDetails();
    _checkLibraryStatus();
  }

  Future<void> _checkLibraryStatus() async {
    final alreadyAdded = await LibraryStorage.containsGame(game.id);

    if (!mounted) return;

    setState(() {
      isInLibrary = alreadyAdded;
    });
  }

  Future<void> _loadGameDetails() async {
    setState(() {
      isLoadingDetails = true;
      detailsError = null;
    });

    try {
      final detailedGame = await rawgApiService.getGameDetails(widget.game);

      if (!mounted) return;

      setState(() {
        game = detailedGame;
        isLoadingDetails = false;
      });

      await _checkLibraryStatus();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoadingDetails = false;
        detailsError = 'Не удалось загрузить подробности игры';
      });
    }
  }

  Future<void> _addGameToLibrary() async {
    try {
      final alreadyAdded = await LibraryStorage.containsGame(game.id);

      if (!mounted) return;

      if (alreadyAdded) {
        setState(() {
          isInLibrary = true;
        });

        await _openGameProgressScreen();
        return;
      }

      _showMessage('Сохраняю ${game.title} в коллекцию...');

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

      if (!mounted) return;

      setState(() {
        isInLibrary = true;
      });

      _showMessage(
        localImagePath == null
            ? 'Игра добавлена, но обложка не сохранилась'
            : '${game.title} добавлена в коллекцию',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage('Не удалось добавить игру в коллекцию');
    }
  }

  Future<void> _openGameProgressScreen() async {
    final savedGame = await LibraryStorage.getGameById(game.id);

    if (!mounted) return;

    if (savedGame == null) {
      setState(() {
        isInLibrary = false;
      });

      _showMessage('Игра не найдена в коллекции');
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

    await _checkLibraryStatus();
  }

  void _showMessage(String text) {
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

  Future<void> _openTrailer() async {
    final trailerUrl = game.trailerUrl;

    if (trailerUrl == null || trailerUrl.trim().isEmpty) {
      _showMessage('Трейлер для этой игры не найден');
      return;
    }

    final uri = Uri.tryParse(trailerUrl);

    if (uri == null) {
      _showMessage('Некорректная ссылка на трейлер');
      return;
    }

    final shouldOpen = await _showTrailerWarningDialog();

    if (!shouldOpen) return;

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      if (!opened) {
        _showMessage('Не удалось открыть трейлер');
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Не удалось открыть трейлер');
    }
  }

  Future<bool> _showTrailerWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111414),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.open_in_browser_rounded,
                color: Color(0xFF75EEFD),
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Открыть трейлер?',
                  style: TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Трейлер будет открыт во внешнем браузере или приложении YouTube.',
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Color(0xFFAAABAB),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF00575F),
                size: 22,
              ),
              label: const Text(
                'Открыть',
                style: TextStyle(
                  color: Color(0xFF00575F),
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF75EEFD),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final hasTrailer =
        game.trailerUrl != null && game.trailerUrl!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF75EEFD),
            backgroundColor: const Color(0xFF111414),
            onRefresh: _loadGameDetails,
            child: CustomScrollView(
              slivers: [
                _HeroSection(game: game),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoadingDetails) ...[
                          const _LoadingDetailsBanner(),
                          const SizedBox(height: 24),
                        ],
                        if (detailsError != null) ...[
                          _DetailsErrorBanner(
                            message: detailsError!,
                            onRetry: _loadGameDetails,
                          ),
                          const SizedBox(height: 24),
                        ],
                        _PrimaryButton(
                          text: isInLibrary
                              ? 'Открыть в коллекции'
                              : 'Добавить в коллекцию',
                          icon: isInLibrary
                              ? Icons.folder_open_rounded
                              : Icons.add_rounded,
                          isLibraryAction: isInLibrary,
                          onTap: isInLibrary
                              ? _openGameProgressScreen
                              : _addGameToLibrary,
                        ),
                        const SizedBox(height: 16),
                        _TrailerButton(
                          hasTrailer: hasTrailer,
                          onTap: hasTrailer ? _openTrailer : null,
                        ),
                        const SizedBox(height: 32),
                        _RatingSection(game: game),
                        const SizedBox(height: 32),
                        _MetaCards(game: game),
                        const SizedBox(height: 32),
                        _AboutSection(
                          game: game,
                          isExpanded: isDescriptionExpanded,
                          onToggle: () {
                            setState(() {
                              isDescriptionExpanded = !isDescriptionExpanded;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        _ScreenshotsSection(game: game),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _TopHeader(title: game.title),
        ],
      ),
    );
  }
}

class _LoadingDetailsBanner extends StatelessWidget {
  const _LoadingDetailsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF75EEFD).withOpacity(0.18),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF75EEFD),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Загружаем подробности из RAWG API...',
              style: TextStyle(
                color: Color(0xFFF4F3F3),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsErrorBanner extends StatelessWidget {
  const _DetailsErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF716C).withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFFF716C),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFF4F3F3),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Повторить',
              style: TextStyle(
                color: Color(0xFF75EEFD),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.game,
  });

  final GameModel game;

  static const Color background = Color(0xFF0C0F0F);

  @override
  Widget build(BuildContext context) {
    final topHeaderHeight = MediaQuery.paddingOf(context).top + 64;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: topHeaderHeight),
        child: SizedBox(
          height: 320,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _HeroBackground(game: game),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          background.withOpacity(0.05),
                          background.withOpacity(0.35),
                          background,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 4,
                  child: _GenreBadges(game: game),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({
    required this.game,
  });

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return GameCover(
      width: double.infinity,
      height: 320,
      imageUrl: game.imageUrl,
      borderRadius: 0,
      iconSize: 110,
      showGradient: false,
    );
  }
}

class _GenreBadges extends StatelessWidget {
  const _GenreBadges({
    required this.game,
  });

  final GameModel game;

  String _localizedAge(String text) {
    final normalized = text.trim().toLowerCase();

    if (normalized == 'everyone') return 'Для всех';
    if (normalized == 'everyone 10+') return '10+';
    if (normalized == 'teen') return '13+';
    if (normalized == 'mature') return '17+';
    if (normalized == 'adults only') return '18+';
    if (normalized == 'rating pending') return 'Ожидается';

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final badges = <String>[
      game.genre,
      ...game.platforms.take(3),
      if (game.esrbRating != null && game.esrbRating!.trim().isNotEmpty)
        _localizedAge(game.esrbRating!),
    ].where((badge) => badge.trim().isNotEmpty).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: badges.map((badge) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _DetailBadge(
              text: badge,
              compact: true,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: const Color(0x990C0F0F),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF75EEFD),
                  size: 23,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 54),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: textColor,
            size: 24,
          ),
          label: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: textColor,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailerButton extends StatelessWidget {
  const _TrailerButton({
    required this.hasTrailer,
    required this.onTap,
  });

  final bool hasTrailer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
    hasTrailer ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05);

    final Color contentColor =
    hasTrailer ? const Color(0xFFF4F3F3) : const Color(0xFF666B6B);

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          hasTrailer
              ? Icons.play_circle_outline_rounded
              : Icons.play_disabled_rounded,
          color: contentColor,
          size: 25,
        ),
        label: Text(
          hasTrailer ? 'Смотреть трейлер' : 'Трейлер не найден',
          style: TextStyle(
            color: contentColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: contentColor,
          side: BorderSide(
            color: borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({
    required this.game,
  });

  final GameModel game;

  static const Color excellentColor = Color(0xFF7ED321);
  static const Color recommendedColor = Color(0xFF4F7BDB);
  static const Color normalColor = Color(0xFFFFA33A);
  static const Color terribleColor = Color(0xFFFF3048);

  List<_RawgRatingItem> get ratingItems {
    final source = game.ratings;

    if (source.isEmpty) {
      final excellentPercent = game.rating <= 0
          ? 0.0
          : (game.rating / 5 * 100).clamp(0.0, 100.0).toDouble();
      final otherPercent = (100 - excellentPercent).clamp(0.0, 100.0).toDouble();

      return [
        _RawgRatingItem(
          title: 'Отлично',
          count: game.ratingsCount ?? 0,
          percent: excellentPercent,
          color: excellentColor,
        ),
        _RawgRatingItem(
          title: 'Рекомендуют',
          count: 0,
          percent: otherPercent,
          color: recommendedColor,
        ),
        const _RawgRatingItem(
          title: 'Нормально',
          count: 0,
          percent: 0,
          color: normalColor,
        ),
        const _RawgRatingItem(
          title: 'Ужасно',
          count: 0,
          percent: 0,
          color: terribleColor,
        ),
      ];
    }

    final rawMap = {
      for (final item in source) item.title.trim().toLowerCase(): item,
    };

    return [
      _itemFromRawg(rawMap['exceptional'], 'Отлично', excellentColor),
      _itemFromRawg(rawMap['recommended'], 'Рекомендуют', recommendedColor),
      _itemFromRawg(rawMap['meh'], 'Нормально', normalColor),
      _itemFromRawg(rawMap['skip'], 'Ужасно', terribleColor),
    ];
  }

  _RawgRatingItem _itemFromRawg(
      GameRatingModel? raw,
      String title,
      Color color,
      ) {
    return _RawgRatingItem(
      title: title,
      count: raw?.count ?? 0,
      percent: raw?.percent ?? 0,
      color: color,
    );
  }

  String get ratingsText {
    final count = game.ratingsCount;

    if (count == null || count <= 0) {
      return 'Оценок пока нет';
    }

    return '$count ${_ratingsWord(count)}';
  }

  String _ratingsWord(int count) {
    final lastTwoDigits = count % 100;
    final lastDigit = count % 10;

    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return 'оценок';
    }

    if (lastDigit == 1) {
      return 'оценка';
    }

    if (lastDigit >= 2 && lastDigit <= 4) {
      return 'оценки';
    }

    return 'оценок';
  }

  String get mainRatingTitle {
    final items = ratingItems;
    final best = items.reduce((a, b) {
      if (b.count > a.count) return b;
      if (b.count == a.count && b.percent > a.percent) return b;
      return a;
    });

    if (best.count <= 0 && best.percent <= 0) {
      return 'Нет оценки';
    }

    return best.title;
  }

  String get featureText {
    final tags = game.tags.map((tag) => tag.trim()).where((tag) {
      return tag.isNotEmpty;
    }).toList();

    final priority = [
      'Open World',
      'Story Rich',
      'Atmospheric',
      'Difficult',
      'Great Soundtrack',
      'Choices Matter',
      'Souls-like',
      'Horror',
      'Fantasy',
      'Sci-fi',
      'Exploration',
    ];

    for (final preferred in priority) {
      final found = tags.where((tag) {
        return tag.toLowerCase() == preferred.toLowerCase();
      }).toList();

      if (found.isNotEmpty) {
        return _translateTag(found.first);
      }
    }

    if (tags.isNotEmpty) {
      return _translateTag(tags.first);
    }

    return 'Особенность не указана';
  }

  String get playTypeText {
    final tags = game.tags.map((tag) => tag.trim().toLowerCase()).toList();

    if (tags.any((tag) => tag.contains('singleplayer'))) {
      return 'Одиночная';
    }

    if (tags.any((tag) => tag.contains('co-op') || tag.contains('coop'))) {
      return 'Кооператив';
    }

    if (tags.any((tag) => tag.contains('multiplayer'))) {
      return 'Мультиплеер';
    }

    if (tags.any((tag) => tag == 'pvp')) {
      return 'PvP';
    }

    return 'Тип не указан';
  }

  String get franchiseText {
    final franchise = game.franchise;

    if (franchise != null && franchise.trim().isNotEmpty) {
      return franchise;
    }

    return 'Отдельная игра';
  }

  String get rawgRatingText {
    if (game.rating <= 0) {
      return 'RAWG —';
    }

    return 'RAWG ${game.rating.toStringAsFixed(1)}';
  }

  String get topChipText {
    final year = game.year;
    final ratingTop = game.ratingTop;
    final yearText = year == null || year <= 0 ? 'RAWG' : year.toString();

    if (ratingTop == null || ratingTop <= 0) {
      return 'TOP $yearText';
    }

    return '№$ratingTop TOP $yearText';
  }

  String _translateTag(String tag) {
    final normalized = tag.trim().toLowerCase();

    const translations = {
      'open world': 'Открытый мир',
      'story rich': 'Сюжетная',
      'atmospheric': 'Атмосферная',
      'difficult': 'Сложная',
      'great soundtrack': 'Сильный саундтрек',
      'choices matter': 'Выборы важны',
      'souls-like': 'Souls-like',
      'horror': 'Хоррор',
      'fantasy': 'Фэнтези',
      'sci-fi': 'Фантастика',
      'exploration': 'Исследование',
      'singleplayer': 'Одиночная',
      'multiplayer': 'Мультиплеер',
      'co-op': 'Кооператив',
      'pvp': 'PvP',
    };

    return translations[normalized] ?? tag;
  }

  @override
  Widget build(BuildContext context) {
    final items = ratingItems;
    final infoPills = [
      game.genre.trim().isEmpty ? 'Не указан' : game.genre,
      featureText,
      playTypeText,
      franchiseText,
      rawgRatingText,
      topChipText,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.06),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: mainRatingTitle),
                const TextSpan(text: '  🎯'),
              ],
            ),
            style: const TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 24,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ratingsText,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _RawgColorScale(
            items: items,
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final pillWidth = (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: infoPills.map((text) {
                  return SizedBox(
                    width: pillWidth,
                    child: _RatingInfoTile(
                      value: text,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RawgRatingItem {
  const _RawgRatingItem({
    required this.title,
    required this.count,
    required this.percent,
    required this.color,
  });

  final String title;
  final int count;
  final double percent;
  final Color color;
}

class _RawgColorScale extends StatelessWidget {
  const _RawgColorScale({
    required this.items,
  });

  final List<_RawgRatingItem> items;

  List<_RawgRatingItem> get _segments {
    if (items.isEmpty) {
      return const [];
    }

    final countBasedItems = items.where((item) => item.count > 0).toList();

    if (countBasedItems.isNotEmpty) {
      return countBasedItems;
    }

    final percentBasedItems = items.where((item) => item.percent > 0).toList();

    if (percentBasedItems.isNotEmpty) {
      return percentBasedItems;
    }

    return items;
  }

  int _flexOf(_RawgRatingItem item, bool useCount) {
    if (useCount) {
      return item.count.clamp(1, 10000).toInt();
    }

    return item.percent.round().clamp(1, 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final segments = _segments;

    if (segments.isEmpty) {
      return const SizedBox(height: 18);
    }

    final useCount = segments.any((item) => item.count > 0);

    return Container(
      width: double.infinity,
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: segments.map((item) {
          return Flexible(
            flex: _flexOf(item, useCount),
            fit: FlexFit.tight,
            child: SizedBox.expand(
              child: ColoredBox(
                color: item.color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RatingInfoTile extends StatelessWidget {
  const _RatingInfoTile({
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6632B8C6),
          width: 1.1,
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF75EEFD),
            fontSize: 12,
            height: 1.2,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _MetaCards extends StatelessWidget {
  const _MetaCards({
    required this.game,
  });

  final GameModel game;

  String get releaseText {
    final released = game.released;

    if (released == null || released.trim().isEmpty) {
      final year = game.year;

      if (year == null) {
        return 'Год неизвестен';
      }

      return year.toString();
    }

    final parts = released.split('-');

    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year != null && month != null && day != null) {
        final dayText = day.toString().padLeft(2, '0');
        final monthText = month.toString().padLeft(2, '0');

        return '$dayText.$monthText.$year';
      }
    }

    return released;
  }

  String get metacriticText {
    final metacritic = game.metacritic;

    if (metacritic == null || metacritic <= 0) {
      return game.rating.toStringAsFixed(1);
    }

    return metacritic.toString();
  }

  String get developerText {
    final developer = game.developer;

    if (developer == null || developer.trim().isEmpty) {
      return 'Не указан';
    }

    return developer;
  }

  String get platformsText {
    if (game.platforms.isEmpty) {
      return 'Не указаны';
    }

    return game.platforms.join(', ');
  }

  String get hoursText {
    if (game.hours <= 0) {
      return 'Не указано';
    }

    return '${game.hours} ч.';
  }

  String get ageText {
    final esrbRating = game.esrbRating;

    if (esrbRating == null || esrbRating.trim().isEmpty) {
      return 'Не указан';
    }

    final normalized = esrbRating.trim().toLowerCase();

    if (normalized == 'everyone') return 'Для всех';
    if (normalized == 'everyone 10+') return '10+';
    if (normalized == 'teen') return '13+';
    if (normalized == 'mature') return '17+';
    if (normalized == 'adults only') return '18+';
    if (normalized == 'rating pending') return 'Ожидается';

    return esrbRating;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _MetaCard(
            title: game.metacritic == null ? 'Рейтинг' : 'Metacritic',
            value: metacriticText,
            icon: Icons.star_rounded,
            highlighted: true,
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'Дата релиза',
            value: releaseText,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'Время игры',
            value: hoursText,
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'Разработчик',
            value: developerText,
            icon: Icons.code_rounded,
            wide: true,
            showFullOnTap: true,
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'Платформы',
            value: platformsText,
            icon: Icons.sports_esports_rounded,
            wide: true,
            showFullOnTap: true,
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'Возраст',
            value: ageText,
            icon: Icons.verified_user_outlined,
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.title,
    required this.value,
    required this.icon,
    this.highlighted = false,
    this.wide = false,
    this.showFullOnTap = false,
  });

  final String title;
  final String value;
  final IconData? icon;
  final bool highlighted;
  final bool wide;
  final bool showFullOnTap;

  bool _isFullInfoAllowed(bool isOverflowing) {
    if (!showFullOnTap) return false;
    if (!isOverflowing) return false;
    if (value.trim().isEmpty) return false;
    if (value == 'Не указан' || value == 'Не указаны') return false;

    return true;
  }

  bool _isValueOverflowing(BuildContext context, TextStyle style) {
    final maxWidth = (wide ? 152.0 : 118.0) - 24;
    final maxLines = wide ? 2 : 1;

    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: style,
      ),
      maxLines: maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);

    return painter.didExceedMaxLines;
  }

  void _showFullInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111414),
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: Color(0x6632B8C6),
              width: 1.1,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0x3375EEFD),
                  ),
                ),
                child: Icon(
                  icon ?? Icons.info_outline_rounded,
                  color: const Color(0xFF75EEFD),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF081F23),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0x5532B8C6),
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF081F23),
                foregroundColor: const Color(0xFF75EEFD),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(
                    color: Color(0x6632B8C6),
                  ),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Закрыть',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color valueColor =
    highlighted ? const Color(0xFFBBFFB3) : const Color(0xFF75EEFD);

    final valueStyle = TextStyle(
      color: valueColor,
      fontSize: highlighted ? 20 : 13,
      height: 1.15,
      fontWeight: FontWeight.w900,
    );

    final isOverflowing = _isValueOverflowing(context, valueStyle);
    final canShowFullInfo = _isFullInfoAllowed(isOverflowing);

    final card = Container(
      width: wide ? 152 : 118,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: valueColor,
              size: 22,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: wide ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
          if (canShowFullInfo) ...[
            const SizedBox(height: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xCC75EEFD),
              size: 18,
            ),
          ],
        ],
      ),
    );

    if (!canShowFullInfo) {
      return card;
    }

    return GestureDetector(
      onTap: () => _showFullInfo(context),
      child: card,
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.game,
    required this.isExpanded,
    required this.onToggle,
  });

  final GameModel game;
  final bool isExpanded;
  final VoidCallback onToggle;

  String get description {
    final apiDescription = game.description;

    if (apiDescription == null || apiDescription.trim().isEmpty) {
      return 'Описание для этой игры пока не найдено.';
    }

    return apiDescription;
  }

  @override
  Widget build(BuildContext context) {
    const descriptionTextStyle = TextStyle(
      color: Color(0xFFAAABAB),
      fontSize: 14,
      height: 1.65,
      fontWeight: FontWeight.w500,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = (constraints.maxWidth - 36)
            .clamp(0.0, double.infinity)
            .toDouble();

        final textPainter = TextPainter(
          text: TextSpan(
            text: description,
            style: descriptionTextStyle,
          ),
          maxLines: 4,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: textWidth);

        final canExpand = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Об игре',
              style: TextStyle(
                color: Color(0xFFF4F3F3),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF111414),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0x6632B8C6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF75EEFD).withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        color: Color(0xFF75EEFD),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Описание',
                        style: TextStyle(
                          color: Color(0xFF75EEFD),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    description,
                    maxLines: isExpanded ? null : 4,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: descriptionTextStyle,
                  ),
                ],
              ),
            ),
            if (canExpand) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onToggle,
                child: Row(
                  children: [
                    Text(
                      isExpanded ? 'СВЕРНУТЬ' : 'РАСКРЫТЬ',
                      style: const TextStyle(
                        color: Color(0xFF75EEFD),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF75EEFD),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ScreenshotsSection extends StatelessWidget {
  const _ScreenshotsSection({
    required this.game,
  });

  final GameModel game;

  void _openScreenshotViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ScreenshotViewerScreen(
          screenshots: game.screenshots,
          initialIndex: initialIndex,
          gameTitle: game.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenshots = game.screenshots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Скриншоты',
              style: TextStyle(
                color: Color(0xFFF4F3F3),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            if (screenshots.isNotEmpty)
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF081F23),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0x6632B8C6),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  screenshots.length.toString(),
                  style: const TextStyle(
                    color: Color(0xFF75EEFD),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (screenshots.isEmpty)
          Container(
            width: double.infinity,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF111414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
              ),
            ),
            child: const Text(
              'Скриншоты не найдены',
              style: TextStyle(
                color: Color(0xFFAAABAB),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: screenshots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final screenshot = screenshots[index];

                return GestureDetector(
                  onTap: () => _openScreenshotViewer(context, index),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          screenshot,
                          width: 224,
                          height: 126,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;

                            return Container(
                              width: 224,
                              height: 126,
                              color: const Color(0xFF172026),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF75EEFD),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 224,
                              height: 126,
                              color: const Color(0xFF172026),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0x80AAABAB),
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.25),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xCC0C0F0F),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: const Icon(
                            Icons.open_in_full_rounded,
                            color: Color(0xFFF4F3F3),
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ScreenshotViewerScreen extends StatefulWidget {
  const _ScreenshotViewerScreen({
    required this.screenshots,
    required this.initialIndex,
    required this.gameTitle,
  });

  final List<String> screenshots;
  final int initialIndex;
  final String gameTitle;

  @override
  State<_ScreenshotViewerScreen> createState() =>
      _ScreenshotViewerScreenState();
}

class _ScreenshotViewerScreenState extends State<_ScreenshotViewerScreen> {
  late final PageController pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;
    pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            itemCount: widget.screenshots.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final screenshot = widget.screenshots[index];

              return InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    screenshot,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF75EEFD),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFFAAABAB),
                          size: 46,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          SafeArea(
            bottom: false,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0x1A75EEFD),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0x6675EEFD),
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF75EEFD),
                        size: 23,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.gameTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF4F3F3),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF081F23),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0x6632B8C6),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${currentIndex + 1}/${widget.screenshots.length}',
                      style: const TextStyle(
                        color: Color(0xFF75EEFD),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.text,
    this.compact = false,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 30 : 34,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
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
          height: 1.2,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return _DetailBadge(text: text);
  }
}
