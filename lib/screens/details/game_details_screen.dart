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
                        const SizedBox(height: 32),
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 115),
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

  @override
  Widget build(BuildContext context) {
    final badges = <String>[
      game.genre,
      ...game.platforms.take(3),
      if (game.esrbRating != null && game.esrbRating!.trim().isNotEmpty)
        game.esrbRating!,
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

  String get ratingLabel {
    if (game.rating >= 4.6) return 'Исключительно';
    if (game.rating >= 4.0) return 'Отлично';
    if (game.rating >= 3.5) return 'Хорошо';
    if (game.rating > 0) return 'Средне';
    return 'Нет оценки';
  }

  String get ratingsText {
    final count = game.ratingsCount;

    if (count == null || count <= 0) {
      return 'Оценок пока нет';
    }

    return '$count оценок';
  }

  int get positiveFlex {
    if (game.rating <= 0) return 25;

    final calculated = (game.rating / 5 * 100).round();

    if (calculated < 15) return 15;
    if (calculated > 90) return 90;

    return calculated;
  }

  @override
  Widget build(BuildContext context) {
    final goodFlex = positiveFlex;
    final otherFlex = 100 - goodFlex;

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
                TextSpan(text: ratingLabel),
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
          const SizedBox(height: 26),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(
              children: [
                Expanded(
                  flex: goodFlex,
                  child: const ColoredBox(
                    color: Color(0xFFBBFFB3),
                    child: SizedBox(height: 8),
                  ),
                ),
                Expanded(
                  flex: otherFlex,
                  child: const ColoredBox(
                    color: Color(0xFF25B0BE),
                    child: SizedBox(height: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallBadge(text: game.genre),
              _SmallBadge(text: 'RAWG ${game.rating.toStringAsFixed(1)}'),
              if (game.year != null) _SmallBadge(text: 'TOP ${game.year}'),
            ],
          ),
        ],
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
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'Платформы',
            value: platformsText,
            icon: Icons.sports_esports_rounded,
            wide: true,
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'Возраст',
            value: game.esrbRating ?? 'Не указан',
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
  });

  final String title;
  final String value;
  final IconData? icon;
  final bool highlighted;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final Color valueColor =
    highlighted ? const Color(0xFFBBFFB3) : const Color(0xFF75EEFD);

    return Container(
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
              style: TextStyle(
                color: valueColor,
                fontSize: highlighted ? 20 : 13,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
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
        const SizedBox(height: 8),
        const Text(
          'Нажмите на скриншот, чтобы открыть просмотр',
          style: TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
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
  bool isScreenshotZoomed = false;

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
            physics: isScreenshotZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: widget.screenshots.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
                isScreenshotZoomed = false;
              });
            },
            itemBuilder: (context, index) {
              final screenshot = widget.screenshots[index];

              return _ZoomableScreenshot(
                imageUrl: screenshot,
                onZoomChanged: (isZoomed) {
                  if (isScreenshotZoomed == isZoomed) return;

                  setState(() {
                    isScreenshotZoomed = isZoomed;
                  });
                },
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
          if (widget.screenshots.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.screenshots.length, (index) {
                    final bool isActive = index == currentIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF75EEFD)
                            : Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomableScreenshot extends StatefulWidget {
  const _ZoomableScreenshot({
    required this.imageUrl,
    required this.onZoomChanged,
  });

  final String imageUrl;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableScreenshot> createState() => _ZoomableScreenshotState();
}

class _ZoomableScreenshotState extends State<_ZoomableScreenshot> {
  static const double _doubleTapScale = 2.6;

  final TransformationController _controller = TransformationController();

  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  TapDownDetails? _doubleTapDetails;

  bool _isZoomed = false;
  bool _isClampingMatrix = false;
  double? _imageAspectRatio;
  Size _viewportSize = Size.zero;
  int _activePointers = 0;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_handleControllerChanged);
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant _ZoomableScreenshot oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl) {
      _resetZoom();
      _imageAspectRatio = null;
      _activePointers = 0;
      _resolveImageSize();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();

    super.dispose();
  }

  void _resolveImageSize() {
    _removeImageListener();

    final imageStream = NetworkImage(widget.imageUrl).resolve(
      const ImageConfiguration(),
    );

    final listener = ImageStreamListener((imageInfo, _) {
      final image = imageInfo.image;
      final width = image.width.toDouble();
      final height = image.height.toDouble();

      if (!mounted || width <= 0 || height <= 0) return;

      setState(() {
        _imageAspectRatio = width / height;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _clampCurrentMatrix();
      });
    });

    _imageStream = imageStream;
    _imageListener = listener;
    imageStream.addListener(listener);
  }

  void _removeImageListener() {
    final imageStream = _imageStream;
    final imageListener = _imageListener;

    if (imageStream != null && imageListener != null) {
      imageStream.removeListener(imageListener);
    }

    _imageStream = null;
    _imageListener = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers++;

    if (_activePointers >= 2) {
      widget.onZoomChanged(true);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10).toInt();
    _syncParentSwipeState();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 10).toInt();
    _syncParentSwipeState();
  }

  void _syncParentSwipeState() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final shouldLockPageView = currentScale > 1.05 || _activePointers >= 2;

    widget.onZoomChanged(shouldLockPageView);
  }

  void _saveDoubleTapPosition(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleControllerChanged() {
    if (_isClampingMatrix) return;

    final isZoomed = _controller.value.getMaxScaleOnAxis() > 1.05;

    if (_isZoomed != isZoomed && mounted) {
      setState(() {
        _isZoomed = isZoomed;
      });
    }

    widget.onZoomChanged(isZoomed || _activePointers >= 2);

    _clampCurrentMatrix();
  }

  void _resetZoom() {
    _isClampingMatrix = true;
    _controller.value = Matrix4.identity();
    _isClampingMatrix = false;

    if (_isZoomed && mounted) {
      setState(() {
        _isZoomed = false;
      });
    }

    widget.onZoomChanged(_activePointers >= 2);
  }

  void _toggleZoom() {
    final currentScale = _controller.value.getMaxScaleOnAxis();

    if (currentScale > 1.05) {
      _resetZoom();
      return;
    }

    final tapPosition = _doubleTapDetails?.localPosition ??
        Offset(
          _viewportSize.width / 2,
          _viewportSize.height / 2,
        );

    final nextMatrix = Matrix4.identity()
      ..translate(
        -tapPosition.dx * (_doubleTapScale - 1),
        -tapPosition.dy * (_doubleTapScale - 1),
      )
      ..scale(_doubleTapScale);

    _isClampingMatrix = true;
    _controller.value = _clampedMatrix(nextMatrix);
    _isClampingMatrix = false;

    if (!_isZoomed && mounted) {
      setState(() {
        _isZoomed = true;
      });
    }

    widget.onZoomChanged(true);
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    if (_activePointers >= 2) {
      widget.onZoomChanged(true);
    }
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    final currentScale = _controller.value.getMaxScaleOnAxis();

    if (currentScale > 1.05 && !_isZoomed && mounted) {
      setState(() {
        _isZoomed = true;
      });
    }

    widget.onZoomChanged(currentScale > 1.05 || _activePointers >= 2);
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    final currentScale = _controller.value.getMaxScaleOnAxis();

    if (currentScale <= 1.05) {
      _resetZoom();
      return;
    }

    _clampCurrentMatrix();
    widget.onZoomChanged(true);
  }

  void _clampCurrentMatrix() {
    if (_isClampingMatrix || _viewportSize == Size.zero) return;

    final currentMatrix = _controller.value;
    final clampedMatrix = _clampedMatrix(currentMatrix);

    if (_isSameMatrix(currentMatrix, clampedMatrix)) return;

    _isClampingMatrix = true;
    _controller.value = clampedMatrix;
    _isClampingMatrix = false;
  }

  Matrix4 _clampedMatrix(Matrix4 sourceMatrix) {
    if (_viewportSize == Size.zero) return sourceMatrix;

    final scale = sourceMatrix.getMaxScaleOnAxis();

    if (scale <= 1.05) {
      return Matrix4.identity();
    }

    final imageRect = _calculateImageRect(_viewportSize);

    final scaledImageWidth = imageRect.width * scale;
    final scaledImageHeight = imageRect.height * scale;

    final matrix = Matrix4.copy(sourceMatrix);
    final values = matrix.storage;

    final currentDx = values[12];
    final currentDy = values[13];

    final minDx = _minOffset(
      viewportLength: _viewportSize.width,
      imageStart: imageRect.left,
      imageEnd: imageRect.right,
      scaledImageLength: scaledImageWidth,
      scale: scale,
    );
    final maxDx = _maxOffset(
      viewportLength: _viewportSize.width,
      imageStart: imageRect.left,
      imageEnd: imageRect.right,
      scaledImageLength: scaledImageWidth,
      scale: scale,
    );
    final minDy = _minOffset(
      viewportLength: _viewportSize.height,
      imageStart: imageRect.top,
      imageEnd: imageRect.bottom,
      scaledImageLength: scaledImageHeight,
      scale: scale,
    );
    final maxDy = _maxOffset(
      viewportLength: _viewportSize.height,
      imageStart: imageRect.top,
      imageEnd: imageRect.bottom,
      scaledImageLength: scaledImageHeight,
      scale: scale,
    );

    values[12] = currentDx.clamp(minDx, maxDx).toDouble();
    values[13] = currentDy.clamp(minDy, maxDy).toDouble();

    return matrix;
  }

  double _minOffset({
    required double viewportLength,
    required double imageStart,
    required double imageEnd,
    required double scaledImageLength,
    required double scale,
  }) {
    if (scaledImageLength <= viewportLength) {
      return (viewportLength - scaledImageLength) / 2 - imageStart * scale;
    }

    return viewportLength - imageEnd * scale;
  }

  double _maxOffset({
    required double viewportLength,
    required double imageStart,
    required double imageEnd,
    required double scaledImageLength,
    required double scale,
  }) {
    if (scaledImageLength <= viewportLength) {
      return (viewportLength - scaledImageLength) / 2 - imageStart * scale;
    }

    return -imageStart * scale;
  }

  bool _isSameMatrix(Matrix4 first, Matrix4 second) {
    final firstValues = first.storage;
    final secondValues = second.storage;

    for (var index = 0; index < 16; index++) {
      if ((firstValues[index] - secondValues[index]).abs() > 0.01) {
        return false;
      }
    }

    return true;
  }

  Rect _calculateImageRect(Size viewportSize) {
    final viewportWidth = viewportSize.width;
    final viewportHeight = viewportSize.height;
    final imageAspectRatio = _imageAspectRatio ?? (16 / 9);
    final viewportAspectRatio = viewportWidth / viewportHeight;

    late final double imageWidth;
    late final double imageHeight;

    if (imageAspectRatio > viewportAspectRatio) {
      imageWidth = viewportWidth;
      imageHeight = viewportWidth / imageAspectRatio;
    } else {
      imageHeight = viewportHeight;
      imageWidth = viewportHeight * imageAspectRatio;
    }

    return Rect.fromLTWH(
      (viewportWidth - imageWidth) / 2,
      (viewportHeight - imageHeight) / 2,
      imageWidth,
      imageHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: _saveDoubleTapPosition,
        onDoubleTap: _toggleZoom,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _viewportSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            return InteractiveViewer(
              transformationController: _controller,
              minScale: 1,
              maxScale: 5,
              panEnabled: _isZoomed,
              scaleEnabled: true,
              boundaryMargin: EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              onInteractionStart: _handleInteractionStart,
              onInteractionUpdate: _handleInteractionUpdate,
              onInteractionEnd: _handleInteractionEnd,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Center(
                  child: Image.network(
                    widget.imageUrl,
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
              ),
            );
          },
        ),
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
