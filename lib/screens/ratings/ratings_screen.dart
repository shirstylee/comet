import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../models/user_profile_model.dart';
import '../../storage/library_change_notifier.dart';
import '../../storage/library_storage.dart';
import '../../storage/profile_storage.dart';
import '../../widgets/game_cover.dart';
import '../game_progress/game_progress_screen.dart';

String _formatRating(double rating) {
  final roundedRating = double.parse(rating.toStringAsFixed(1));

  if (roundedRating == roundedRating.roundToDouble()) {
    return roundedRating.toInt().toString();
  }

  return roundedRating.toStringAsFixed(1);
}


Color _ratingScaleColor(double rating) {
  if (rating <= 0) return const Color(0xFF78716C);
  if (rating >= 8) return const Color(0xFF75EEFD);
  if (rating >= 6) return const Color(0xFFFACC15);
  if (rating >= 4) return const Color(0xFFF97316);

  return const Color(0xFFEF4444);
}

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({
    super.key,
    this.onProfileTap,
    this.openAllGamesOnStart = false,
    this.onAutoOpenHandled,
  });

  final VoidCallback? onProfileTap;
  final bool openAllGamesOnStart;
  final VoidCallback? onAutoOpenHandled;

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color surface = Color(0xFF111414);
  static const Color accent = Color(0xFF75EEFD);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  List<LibraryGameModel> games = [];
  bool isLoading = true;
  bool didOpenAllGamesOnStart = false;

  int? lastOpenedGameId;

  @override
  void initState() {
    super.initState();

    _loadGames();

    LibraryChangeNotifier.version.addListener(_onLibraryChanged);
  }

  void _onLibraryChanged() {
    if (!mounted) return;

    _loadGames();
  }

  @override
  void didUpdateWidget(covariant RatingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.openAllGamesOnStart && widget.openAllGamesOnStart) {
      didOpenAllGamesOnStart = false;
      _tryOpenAllGamesOnStart();
    }
  }

  void _tryOpenAllGamesOnStart() {
    if (!widget.openAllGamesOnStart) return;
    if (didOpenAllGamesOnStart) return;
    if (isLoading) return;

    didOpenAllGamesOnStart = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      widget.onAutoOpenHandled?.call();
      _openAllGamesScreen();
    });
  }

  Future<void> _loadGames() async {
    final loadedGames = await LibraryStorage.getAllGames();

    loadedGames.sort((a, b) {
      return b.addedAt.compareTo(a.addedAt);
    });

    if (!mounted) return;

    setState(() {
      games = loadedGames;
      isLoading = false;
    });

    _tryOpenAllGamesOnStart();
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

  List<LibraryGameModel> get ratedGames {
    final result = games.where((game) {
      return game.userRating != null && game.userRating! > 0;
    }).toList();

    result.sort((a, b) {
      if (a.id == lastOpenedGameId && b.id != lastOpenedGameId) {
        return -1;
      }

      if (b.id == lastOpenedGameId && a.id != lastOpenedGameId) {
        return 1;
      }

      return _ratingDate(b).compareTo(_ratingDate(a));
    });

    return result;
  }

  List<LibraryGameModel> get unratedGames {
    return games.where((game) {
      return game.userRating == null || game.userRating! <= 0;
    }).toList();
  }

  bool get hasRatings => ratedGames.isNotEmpty;

  double get averageRating {
    if (ratedGames.isEmpty) return 0;

    final sum = ratedGames.fold<double>(0, (value, game) {
      return value + _ratingOutOfTen(game.userRating);
    });

    return sum / ratedGames.length;
  }

  Map<int, int> get ratingDistribution {
    final distribution = <int, int>{
      for (int rating = 10; rating >= 1; rating--) rating: 0,
    };

    for (final game in ratedGames) {
      final rating = _ratingOutOfTen(game.userRating).round().clamp(1, 10);
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return distribution;
  }

  List<_GenreRating> get genreRatings {
    if (ratedGames.isEmpty) return [];

    final Map<String, List<double>> grouped = {};

    for (final game in ratedGames) {
      final genre = game.genre.trim();

      if (genre.isEmpty) continue;

      grouped.putIfAbsent(genre, () => []);
      grouped[genre]!.add(_ratingOutOfTen(game.userRating));
    }

    final genres = grouped.entries.map((entry) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;

      return _GenreRating(
        title: entry.key,
        rating: average,
      );
    }).toList();

    genres.sort((a, b) => b.rating.compareTo(a.rating));

    return genres;
  }

  double _ratingOutOfTen(double? rating) {
    if (rating == null || rating <= 0) return 0;

    if (rating > 10) return 10;
    if (rating < 1) return 1;

    return rating;
  }

  DateTime _ratingDate(LibraryGameModel game) {
    return game.ratedAt ?? game.addedAt;
  }

  Color _ratingColor(double rating) {
    return _ratingScaleColor(rating);
  }

  String _ratingQuality(double rating) {
    if (rating >= 9.5) return 'ШЕДЕВР';
    if (rating >= 8.5) return 'ОТЛИЧНО';
    if (rating >= 7.0) return 'ХОРОШО';
    if (rating >= 5.0) return 'СРЕДНЕ';

    return 'СЛАБО';
  }

  String _formattedDate(DateTime date) {
    const months = [
      'ЯНВАРЯ',
      'ФЕВРАЛЯ',
      'МАРТА',
      'АПРЕЛЯ',
      'МАЯ',
      'ИЮНЯ',
      'ИЮЛЯ',
      'АВГУСТА',
      'СЕНТЯБРЯ',
      'ОКТЯБРЯ',
      'НОЯБРЯ',
      'ДЕКАБРЯ',
    ];

    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Future<void> _openGameProgress(
      LibraryGameModel game, {
        bool openReview = false,
      }) async {
    lastOpenedGameId = game.id;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameProgressScreen(
          gameId: game.id,
          title: game.title,
          status: game.status,
          userHours: game.userHours,
          userMinutes: game.userMinutes,
          apiHours: game.apiHours,
          rating: game.userRating ?? game.apiRating ?? 0,
          openReviewOnStart: openReview,
        ),
      ),
    );

    await _loadGames();
  }

  Future<void> _openAllGamesScreen() async {
    if (games.isEmpty) {
      _showMessage('В библиотеке пока нет игр');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllGamesForRatingScreen(
          games: games,
          onOpenGame: _openGameProgress,
          ratingOutOfTen: _ratingOutOfTen,
          ratingColor: _ratingColor,
          ratingQuality: _ratingQuality,
          formattedDate: _formattedDate,
          ratingDate: _ratingDate,
        ),
      ),
    );

    await _loadGames();
  }

  Future<void> _openAllRatingsScreen() async {
    if (ratedGames.isEmpty) {
      _showMessage('Оценок пока нет');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllRatingsScreen(
          games: ratedGames,
          onOpenGame: _openGameProgress,
          ratingOutOfTen: _ratingOutOfTen,
          ratingColor: _ratingColor,
          ratingQuality: _ratingQuality,
          formattedDate: _formattedDate,
          ratingDate: _ratingDate,
        ),
      ),
    );

    await _loadGames();
  }

  void _openGamePicker() {
    if (games.isEmpty) {
      _showMessage('В библиотеке пока нет игр');
      return;
    }

    final gamesWithoutRating = unratedGames;
    final recentGamesWithoutRating = gamesWithoutRating.take(3).toList();

    if (gamesWithoutRating.isEmpty) {
      _openAllGamesScreen();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(26),
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
                      color: accent.withOpacity(0.28),
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
                  const SizedBox(height: 14),
                  const Text(
                    'Выберите игру',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Показаны 3 последние игры без оценки',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: recentGamesWithoutRating.map((game) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _GamePickerItem(
                          game: game,
                          rating: 0,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            _openGameProgress(
                              game,
                              openReview: true,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _openAllGamesScreen();
                      },
                      icon: const Icon(
                        Icons.grid_view_rounded,
                        color: accent,
                      ),
                      label: const Text(
                        'Все игры',
                        style: TextStyle(
                          color: accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF081F23),
                        side: const BorderSide(
                          color: Color(0x5532B8C6),
                          width: 1.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
  void dispose() {
    LibraryChangeNotifier.version.removeListener(_onLibraryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distribution = ratingDistribution;
    final maxDistribution = distribution.values.fold<int>(0, (a, b) {
      return a > b ? a : b;
    });

    final recentGames = ratedGames.take(3).toList();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: accent,
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RatingsHeader(
                onProfileTap: widget.onProfileTap,
              ),
              const SizedBox(height: 32),
              _TitleAndAction(
                onTap: _openGamePicker,
              ),
              const SizedBox(height: 48),
              _SummaryCard(
                averageRating: averageRating,
                ratedCount: ratedGames.length,
              ),
              const SizedBox(height: 48),
              _DistributionCard(
                distribution: distribution,
                maxValue: maxDistribution,
              ),
              const SizedBox(height: 32),
              const _SectionTitle('Недавно оценённые'),
              const SizedBox(height: 24),
              if (hasRatings) ...[
                Column(
                  children: recentGames.map((game) {
                    final rating = _ratingOutOfTen(game.userRating);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RecentlyRatedCard(
                        game: game,
                        rating: rating,
                        dateText: _formattedDate(_ratingDate(game)),
                        color: _ratingColor(rating),
                        quality: _ratingQuality(rating),
                        onTap: () => _openGameProgress(game),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                _AllRatingsButton(
                  onTap: _openAllRatingsScreen,
                ),
              ] else
                const _EmptyRatingsState(),
              const SizedBox(height: 32),
              const _SectionTitle('Распределение по жанрам'),
              const SizedBox(height: 24),
              if (genreRatings.isNotEmpty)
                _GenreDistributionCard(
                  genres: genreRatings,
                )
              else
                const _EmptyGenreCard(),
              const SizedBox(height: 32),
              _InsightCard(
                games: games,
                ratedGames: ratedGames,
                averageRating: averageRating,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingsHeader extends StatelessWidget {
  const _RatingsHeader({
    this.onProfileTap,
  });

  final VoidCallback? onProfileTap;

  static const Color accent = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _ProfileAvatarButton(
              onTap: onProfileTap,
            ),
            const SizedBox(width: 12),
            const Text(
              'Оценки',
              style: TextStyle(
                color: accent,
                fontSize: 24,
                height: 1.33,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ],
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
      ],
    );
  }
}


class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(
          icon,
          color: const Color(0xFF75EEFD),
          size: 23,
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatelessWidget {
  const _ProfileAvatarButton({
    this.onTap,
  });

  final VoidCallback? onTap;

  static const Color accent = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfileModel>(
      future: ProfileStorage.getProfile(),
      builder: (context, snapshot) {
        final avatarPath = snapshot.data?.avatarPath;
        final hasAvatar =
            avatarPath != null &&
                avatarPath.trim().isNotEmpty &&
                File(avatarPath).existsSync();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x3375EEFD),
                width: 2,
              ),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF10333A),
                  Color(0xFF091111),
                ],
              ),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.file(
                File(avatarPath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
                  : const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TitleAndAction extends StatelessWidget {
  const _TitleAndAction({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(
          width: 138,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'СТАТИСТИКА',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.8,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Оценки',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              height: 48,
              width: 164,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF75EEFD),
                      Color(0xFF25B0BE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF00575F),
                    size: 18,
                  ),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Оценить игру',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: Color(0xFF00575F),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.averageRating,
    required this.ratedCount,
  });

  final double averageRating;
  final int ratedCount;

  @override
  Widget build(BuildContext context) {
    final ratingColor = _ratingScaleColor(averageRating);
    final ratingText = averageRating <= 0 ? '—' : _formatRating(averageRating);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10262B),
            Color(0xFF111414),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x6632B8C6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetricPlaque(
              icon: Icons.star_rounded,
              label: 'СРЕДНЯЯ',
              value: ratingText,
              caption: 'ОЦЕНКА',
              color: ratingColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryMetricPlaque(
              icon: Icons.rate_review_rounded,
              label: 'ОЦЕНЕНО',
              value: '$ratedCount',
              caption: 'ИГР',
              color: const Color(0xFF75EEFD),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricPlaque extends StatelessWidget {
  const _SummaryMetricPlaque({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: color.withOpacity(0.35),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAABAB),
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: color,
                      fontSize: 38,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD6D3D1),
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.distribution,
    required this.maxValue,
  });

  final Map<int, int> distribution;
  final int maxValue;

  Color _barColor(int rating) {
    return _ratingScaleColor(rating.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10262B),
            Color(0xFF111414),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x6632B8C6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.09),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF75EEFD),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Распределение оценок',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: Color(0xFFF4F3F3),
                      fontSize: 20,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          for (int rating = 10; rating >= 1; rating--)
            Padding(
              padding: EdgeInsets.only(bottom: rating == 1 ? 0 : 10),
              child: _DistributionRow(
                rating: rating,
                count: distribution[rating] ?? 0,
                maxValue: maxValue,
                color: _barColor(rating),
              ),
            ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.rating,
    required this.count,
    required this.maxValue,
    required this.color,
  });

  final int rating;
  final int count;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final value = maxValue == 0 ? 0.0 : count / maxValue;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: count > 0
              ? color.withOpacity(0.22)
              : const Color(0x3332B8C6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: color.withOpacity(0.30),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rating',
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(
                    height: 9,
                    color: const Color(0xFF10262B),
                  ),
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        boxShadow: count > 0
                            ? [
                          BoxShadow(
                            color: color.withOpacity(0.40),
                            blurRadius: 12,
                          ),
                        ]
                            : [],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF10262B),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: const Color(0x3332B8C6),
              ),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFFD6D3D1),
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFF4F3F3),
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EmptyRatingsState extends StatelessWidget {
  const _EmptyRatingsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: Color(0xFF57534E),
            size: 64,
          ),
          SizedBox(height: 18),
          Text(
            'Оценок пока нет',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Добавьте первую оценку, чтобы увидеть её здесь',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateInfoPill extends StatelessWidget {
  const _DateInfoPill({
    required this.label,
    required this.dateText,
    this.compact = false,
  });

  final String label;
  final String dateText;
  final bool compact;

  bool get isAddedDate => label == 'ДОБАВЛЕНО';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 28 : 30,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6632B8C6),
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
          Icon(
            isAddedDate
                ? Icons.add_rounded
                : compact
                ? Icons.calendar_month_rounded
                : Icons.event_available_rounded,
            color: const Color(0xFF75EEFD),
            size: compact ? 12 : 13,
          ),
          SizedBox(width: compact ? 5 : 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                dateText,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: const Color(0xFF75EEFD),
                  fontSize: compact ? 8.8 : 9.8,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSquareBadge extends StatelessWidget {
  const _RatingSquareBadge({
    required this.rating,
    required this.color,
    required this.size,
    required this.fontSize,
    required this.starSize,
    required this.borderRadius,
  });

  final double rating;
  final Color color;
  final double size;
  final double fontSize;
  final double starSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatRating(rating),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.star_rounded,
            color: color,
            size: starSize,
          ),
        ],
      ),
    );
  }
}

class _QualityPill extends StatelessWidget {
  const _QualityPill({
    required this.quality,
    required this.color,
  });

  final String quality;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.28),
        ),
      ),
      child: Text(
        quality,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RecentlyRatedCard extends StatelessWidget {
  const _RecentlyRatedCard({
    required this.game,
    required this.rating,
    required this.dateText,
    required this.color,
    required this.quality,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final String dateText;
  final Color color;
  final String quality;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D2020),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GameCover(
                width: 64,
                height: 80,
                localImagePath: game.localImagePath,
                imageUrl: game.imageUrl,
                borderRadius: 8,
                iconSize: 30,
                gradientOpacity: 0.18,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF4F3F3),
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _DateInfoPill(
                        label: 'ОЦЕНЕНО',
                        dateText: dateText,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _RatingSquareBadge(
                    rating: rating,
                    color: color,
                    size: 54,
                    fontSize: 22,
                    starSize: 15,
                    borderRadius: 15,
                  ),
                  if (rating >= 9.5) ...[
                    const SizedBox(height: 6),
                    _QualityPill(
                      quality: quality,
                      color: color,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllRatingsButton extends StatelessWidget {
  const _AllRatingsButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.star_rounded,
          color: Color(0xFF75EEFD),
          size: 19,
        ),
        label: const Text(
          'Все оценки',
          style: TextStyle(
            color: Color(0xFF75EEFD),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF081F23),
          side: const BorderSide(
            color: Color(0x6632B8C6),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _AllRatingsScreen extends StatefulWidget {
  const _AllRatingsScreen({
    required this.games,
    required this.onOpenGame,
    required this.ratingOutOfTen,
    required this.ratingColor,
    required this.ratingQuality,
    required this.formattedDate,
    required this.ratingDate,
  });

  final List<LibraryGameModel> games;
  final Future<void> Function(
      LibraryGameModel game, {
      bool openReview,
      }) onOpenGame;
  final double Function(double? rating) ratingOutOfTen;
  final Color Function(double rating) ratingColor;
  final String Function(double rating) ratingQuality;
  final String Function(DateTime date) formattedDate;
  final DateTime Function(LibraryGameModel game) ratingDate;

  @override
  State<_AllRatingsScreen> createState() => _AllRatingsScreenState();
}

class _AllRatingsScreenState extends State<_AllRatingsScreen> {
  late List<LibraryGameModel> games;

  @override
  void initState() {
    super.initState();

    games = [...widget.games];
    LibraryChangeNotifier.version.addListener(_onLibraryChanged);
  }

  void _onLibraryChanged() {
    if (!mounted) return;

    _loadRatedGames();
  }

  Future<void> _loadRatedGames() async {
    final loadedGames = await LibraryStorage.getAllGames();

    final result = loadedGames.where((game) {
      return game.userRating != null && game.userRating! > 0;
    }).toList();

    result.sort((a, b) {
      return widget.ratingDate(b).compareTo(widget.ratingDate(a));
    });

    if (!mounted) return;

    setState(() {
      games = result;
    });
  }

  Future<void> _openGame(LibraryGameModel game) async {
    await widget.onOpenGame(game);

    if (!mounted) return;

    await _loadRatedGames();
  }

  double get averageRating {
    if (games.isEmpty) return 0;

    final sum = games.fold<double>(0, (value, game) {
      return value + widget.ratingOutOfTen(game.userRating);
    });

    return sum / games.length;
  }

  @override
  void dispose() {
    LibraryChangeNotifier.version.removeListener(_onLibraryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0F0F),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _AllRatingsHero(
                  count: games.length,
                  averageRating: averageRating,
                  onBack: () => Navigator.pop(context),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverList.separated(
                itemCount: games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final game = games[index];
                  final rating = widget.ratingOutOfTen(game.userRating);

                  return _AllRatingCard(
                    game: game,
                    rating: rating,
                    dateText: widget.formattedDate(widget.ratingDate(game)),
                    color: widget.ratingColor(rating),
                    quality: widget.ratingQuality(rating),
                    onTap: () => _openGame(game),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllRatingsHero extends StatelessWidget {
  const _AllRatingsHero({
    required this.count,
    required this.averageRating,
    required this.onBack,
  });

  final int count;
  final double averageRating;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ratingColor = _ratingScaleColor(averageRating);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
            const SizedBox(width: 12),
            const Text(
              'Все оценки',
              style: TextStyle(
                color: Color(0xFF75EEFD),
                fontSize: 24,
                height: 1.33,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF081F23),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x6632B8C6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF75EEFD).withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: ratingColor,
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'СРЕДНЯЯ ОЦЕНКА',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF75EEFD),
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRating(averageRating),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ratingColor,
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$count оценок сохранено',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD6D3D1),
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Полный список ваших игровых оценок',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllRatingCard extends StatelessWidget {
  const _AllRatingCard({
    required this.game,
    required this.rating,
    required this.dateText,
    required this.color,
    required this.quality,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final String dateText;
  final Color color;
  final String quality;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final comment = game.comment?.trim();
    final hasComment = comment != null && comment.isNotEmpty;

    return Material(
      color: const Color(0xFF111414),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              GameCover(
                width: 78,
                height: 104,
                localImagePath: game.localImagePath,
                imageUrl: game.imageUrl,
                borderRadius: 14,
                iconSize: 34,
                gradientOpacity: 0.16,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF4F3F3),
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _DateInfoPill(
                        label: 'ОЦЕНЕНО',
                        dateText: dateText,
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                      if (hasComment)
                        Expanded(
                          child: Text(
                            comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFAAABAB),
                              fontSize: 12,
                              height: 1.35,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        const Expanded(
                          child: Text(
                            'Комментарий не добавлен',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF57534E),
                              fontSize: 12,
                              height: 1.35,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RatingSquareBadge(
                    rating: rating,
                    color: color,
                    size: 58,
                    fontSize: 21,
                    starSize: 14,
                    borderRadius: 18,
                  ),
                  const SizedBox(height: 8),
                  _QualityPill(
                    quality: quality,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllGamesForRatingScreen extends StatefulWidget {
  const _AllGamesForRatingScreen({
    required this.games,
    required this.onOpenGame,
    required this.ratingOutOfTen,
    required this.ratingColor,
    required this.ratingQuality,
    required this.formattedDate,
    required this.ratingDate,
  });

  final List<LibraryGameModel> games;
  final Future<void> Function(
      LibraryGameModel game, {
      bool openReview,
      }) onOpenGame;
  final double Function(double? rating) ratingOutOfTen;
  final Color Function(double rating) ratingColor;
  final String Function(double rating) ratingQuality;
  final String Function(DateTime date) formattedDate;
  final DateTime Function(LibraryGameModel game) ratingDate;

  @override
  State<_AllGamesForRatingScreen> createState() =>
      _AllGamesForRatingScreenState();
}

class _AllGamesForRatingScreenState extends State<_AllGamesForRatingScreen> {
  late List<LibraryGameModel> games;

  @override
  void initState() {
    super.initState();

    games = [...widget.games];
    LibraryChangeNotifier.version.addListener(_onLibraryChanged);
  }

  void _onLibraryChanged() {
    if (!mounted) return;

    _loadGames();
  }

  Future<void> _loadGames() async {
    final loadedGames = await LibraryStorage.getAllGames();

    if (!mounted) return;

    setState(() {
      games = loadedGames;
    });
  }

  Future<void> _openGame(
      LibraryGameModel game, {
        required bool openReview,
      }) async {
    await widget.onOpenGame(
      game,
      openReview: openReview,
    );

    if (!mounted) return;

    await _loadGames();
  }

  @override
  void dispose() {
    LibraryChangeNotifier.version.removeListener(_onLibraryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedGames = [...games];

    sortedGames.sort((a, b) {
      final aHasRating = a.userRating != null && a.userRating! > 0;
      final bHasRating = b.userRating != null && b.userRating! > 0;

      if (aHasRating != bHasRating) {
        return aHasRating ? 1 : -1;
      }

      if (aHasRating && bHasRating) {
        return widget.ratingDate(b).compareTo(widget.ratingDate(a));
      }

      return b.addedAt.compareTo(a.addedAt);
    });

    final unratedCount = sortedGames.where((game) {
      return game.userRating == null || game.userRating! <= 0;
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F0F),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _AllGamesHero(
                  totalCount: sortedGames.length,
                  unratedCount: unratedCount,
                  onBack: () => Navigator.pop(context),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              sliver: SliverList.separated(
                itemCount: sortedGames.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final game = sortedGames[index];
                  final rating = widget.ratingOutOfTen(game.userRating);
                  final hasRating = rating > 0;

                  return _AllGameForRatingCard(
                    game: game,
                    rating: rating,
                    hasRating: hasRating,
                    dateText: hasRating
                        ? widget.formattedDate(widget.ratingDate(game))
                        : widget.formattedDate(game.addedAt),
                    color: hasRating
                        ? widget.ratingColor(rating)
                        : const Color(0xFF75EEFD),
                    quality:
                    hasRating ? widget.ratingQuality(rating) : 'БЕЗ ОЦЕНКИ',
                    onTap: () => _openGame(
                      game,
                      openReview: !hasRating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllGamesHero extends StatelessWidget {
  const _AllGamesHero({
    required this.totalCount,
    required this.unratedCount,
    required this.onBack,
  });

  final int totalCount;
  final int unratedCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _CircleIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
            const SizedBox(width: 12),
            const Text(
              'Все игры',
              style: TextStyle(
                color: Color(0xFF75EEFD),
                fontSize: 24,
                height: 1.33,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF081F23),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x6632B8C6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF75EEFD).withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  color: Color(0xFF75EEFD),
                  size: 34,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'БЕЗ ОЦЕНКИ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF75EEFD),
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$unratedCount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF4F3F3),
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Всего в библиотеке: $totalCount',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD6D3D1),
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Нажмите на игру, чтобы открыть оценку и прогресс',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllGameForRatingCard extends StatelessWidget {
  const _AllGameForRatingCard({
    required this.game,
    required this.rating,
    required this.hasRating,
    required this.dateText,
    required this.color,
    required this.quality,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final bool hasRating;
  final String dateText;
  final Color color;
  final String quality;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111414),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: hasRating
                  ? color.withOpacity(0.18)
                  : const Color(0x6632B8C6),
            ),
          ),
          child: Row(
            children: [
              GameCover(
                width: 70,
                height: 92,
                localImagePath: game.localImagePath,
                imageUrl: game.imageUrl,
                borderRadius: 13,
                iconSize: 32,
                gradientOpacity: 0.16,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 92,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF4F3F3),
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _GameStatusInfoPill(
                        status: game.status,
                      ),
                      const Spacer(),
                      _DateInfoPill(
                        label: hasRating ? 'ОЦЕНЕНО' : 'ДОБАВЛЕНО',
                        dateText: dateText,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              hasRating
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RatingSquareBadge(
                    rating: rating,
                    color: color,
                    size: 54,
                    fontSize: 20,
                    starSize: 14,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    quality,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              )
                  : Container(
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
                child: const Text(
                  'ОЦЕНИТЬ',
                  style: TextStyle(
                    color: Color(0xFF75EEFD),
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(
          icon,
          color: const Color(0xFF75EEFD),
          size: 23,
        ),
      ),
    );
  }
}

class _GenreDistributionCard extends StatelessWidget {
  const _GenreDistributionCard({
    required this.genres,
  });

  final List<_GenreRating> genres;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10262B),
            Color(0xFF111414),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x6632B8C6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.09),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: genres.map((genre) {
          return _GenreChip(
            title: genre.title,
            rating: genre.rating,
          );
        }).toList(),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.title,
    required this.rating,
  });

  final String title;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final color = _ratingScaleColor(rating);

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.category_rounded,
            color: Color(0xFF75EEFD),
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 9),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: color.withOpacity(0.30),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatRating(rating),
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGenreCard extends StatelessWidget {
  const _EmptyGenreCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10262B),
            Color(0xFF111414),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x6632B8C6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            color: Color(0xFF75EEFD),
            size: 20,
          ),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Статистика по жанрам появится позже',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAABAB),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.games,
    required this.ratedGames,
    required this.averageRating,
  });

  final List<LibraryGameModel> games;
  final List<LibraryGameModel> ratedGames;
  final double averageRating;

  int get completedCount {
    return games.where((game) {
      return game.status.trim().toLowerCase() == 'пройдено';
    }).length;
  }

  int get playingCount {
    return games.where((game) {
      final status = game.status.trim().toLowerCase();
      return status == 'играю' || status == 'в процессе';
    }).length;
  }

  int get plannedCount {
    return games.where((game) {
      return game.status.trim().toLowerCase() == 'планирую';
    }).length;
  }

  LibraryGameModel? get latestGame {
    if (games.isEmpty) return null;

    final sortedGames = [...games];
    sortedGames.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    return sortedGames.first;
  }

  String get dominantStatusText {
    final statusCounts = <String, int>{
      'Пройдено': completedCount,
      'Играю': playingCount,
      'Планирую': plannedCount,
    };

    final sortedStatuses = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedStatuses.isEmpty || sortedStatuses.first.value <= 0) {
      return 'без статуса';
    }

    return sortedStatuses.first.key;
  }

  String? get topGenre {
    final genreCounts = <String, int>{};

    for (final game in games) {
      final genre = game.genre.trim();
      if (genre.isEmpty) continue;

      genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
    }

    if (genreCounts.isEmpty) return null;

    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedGenres.first.key;
  }

  String get description {
    if (games.isEmpty) {
      return 'Здесь будет короткая сводка по библиотеке: последние добавления, статусы, жанры и сохранённые игры.';
    }

    final latestTitle = latestGame?.title.trim();
    final latestText = latestTitle == null || latestTitle.isEmpty
        ? 'последняя игра пока не определена'
        : 'последнее добавление — «$latestTitle»';

    final genre = topGenre;
    final genreText = genre == null ? '' : ' Чаще всего встречается жанр: $genre.';

    return 'В библиотеке ${games.length} игр, $latestText. Больше всего сейчас игр со статусом «$dominantStatusText». $genreText';
  }

  @override
  Widget build(BuildContext context) {
    final ratingText = averageRating <= 0
        ? '—'
        : '${_formatRating(averageRating)}/10';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10262B),
            Color(0xFF111414),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0x6675EEFD),
                  ),
                ),
                child: const Icon(
                  Icons.collections_bookmark_rounded,
                  color: Color(0xFF75EEFD),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Игровая полка',
                  style: TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFD6D3D1),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InsightPill(
                icon: Icons.sports_esports_rounded,
                text: 'Игр: ${games.length}',
              ),
              _InsightPill(
                icon: Icons.star_rounded,
                text: 'Оценок: ${ratedGames.length}',
              ),
              _InsightPill(
                icon: Icons.check_circle_rounded,
                text: 'Пройдено: $completedCount',
              ),
              _InsightPill(
                icon: Icons.schedule_rounded,
                text: 'Играю: $playingCount',
              ),
              if (averageRating > 0)
                _InsightPill(
                  icon: Icons.auto_awesome_rounded,
                  text: 'Средняя: $ratingText',
                ),
              if (topGenre != null)
                _InsightPill(
                  icon: Icons.category_rounded,
                  text: topGenre!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF75EEFD),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
class _GameStatusInfoPill extends StatelessWidget {
  const _GameStatusInfoPill({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final statusIcon = _pickerStatusIcon(status);

    return Container(
      height: 24,
      constraints: const BoxConstraints(
        maxWidth: 128,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: const Color(0xFF75EEFD),
            size: 12,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                status.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 9.5,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GamePickerItem extends StatelessWidget {
  const _GamePickerItem({
    required this.game,
    required this.rating,
    required this.onTap,
  });

  final LibraryGameModel game;
  final double rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF081F23),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0x5532B8C6),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF75EEFD).withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0x2275EEFD),
          highlightColor: const Color(0x1275EEFD),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            child: Row(
              children: [
                GameCover(
                  width: 42,
                  height: 52,
                  localImagePath: game.localImagePath,
                  imageUrl: game.imageUrl,
                  borderRadius: 8,
                  iconSize: 22,
                  gradientOpacity: 0.18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF4F3F3),
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _GameStatusInfoPill(
                          status: game.status,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081F23),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0x6632B8C6),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasRating ? _formatRating(rating) : 'Оценить',
                        style: TextStyle(
                          color: hasRating
                              ? const Color(0xFF75EEFD)
                              : const Color(0xFF75EEFD),
                          fontSize: hasRating ? 14 : 11,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (hasRating) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFF75EEFD),
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _pickerStatusIcon(String status) {
  switch (status.trim().toLowerCase()) {
    case 'пройдено':
      return Icons.check_circle_rounded;
    case 'играю':
    case 'в процессе':
      return Icons.sports_esports_rounded;
    case 'планирую':
    case 'хочу пройти':
      return Icons.schedule_rounded;
    default:
      return Icons.label_rounded;
  }
}

class _GenreRating {
  const _GenreRating({
    required this.title,
    required this.rating,
  });

  final String title;
  final double rating;
}