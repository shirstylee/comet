import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../models/user_profile_model.dart';
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
      final genre = game.genre.trim().isEmpty ? 'Action' : game.genre.trim();

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
    if (rating >= 9) return accent;
    if (rating >= 8) return const Color(0xFF61ACFE);
    if (rating >= 6) return const Color(0xFFA8A29E);
    if (rating >= 4) return const Color(0xFF78716C);

    return const Color(0xFF57534E);
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
              color: surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.16),
                  blurRadius: 34,
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
                        side: BorderSide(
                          color: accent.withOpacity(0.4),
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
              if (hasRatings)
                _GenreDistributionCard(
                  genres: genreRatings,
                )
              else
                const _EmptyGenreCard(),
              const SizedBox(height: 32),
              _InsightCard(
                hasRatings: hasRatings,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2020),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.star_border_rounded,
            color: Color(0xFF75EEFD),
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            _formatRating(averageRating),
            style: const TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 56,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Средняя оценка',
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 42),
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFF464848).withOpacity(0.15),
          ),
          const SizedBox(height: 32),
          Text(
            '$ratedCount',
            style: const TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Оценено игр',
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
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
    if (rating >= 9) return const Color(0xFF75EEFD);
    if (rating >= 7) return const Color(0xFF61ACFE);
    if (rating >= 5) return const Color(0xFF57534E);
    if (rating >= 3) return const Color(0xFF44403C);

    return const Color(0xFF232626);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Распределение оценок',
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 28),
          for (int rating = 10; rating >= 1; rating--)
            Padding(
              padding: EdgeInsets.only(bottom: rating == 1 ? 0 : 16),
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

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$rating',
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 15,
              fontWeight: FontWeight.w800,
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
                  height: 10,
                  color: const Color(0xFF232626),
                ),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: count > 0
                          ? [
                        BoxShadow(
                          color: color.withOpacity(0.35),
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
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF78716C),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 8),
                    Text(
                      dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 12,
                        height: 1.3,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatRating(rating),
                        style: TextStyle(
                          color: color,
                          fontSize: 26,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_border_rounded,
                        color: color,
                        size: 17,
                      ),
                    ],
                  ),
                  if (rating >= 9.5) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBFFB3).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        quality,
                        style: const TextStyle(
                          color: Color(0xFFBBFFB3),
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _AllRatingsScreen extends StatelessWidget {
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

  double get averageRating {
    if (games.isEmpty) return 0;

    final sum = games.fold<double>(0, (value, game) {
      return value + ratingOutOfTen(game.userRating);
    });

    return sum / games.length;
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
                  final rating = ratingOutOfTen(game.userRating);

                  return _AllRatingCard(
                    game: game,
                    rating: rating,
                    dateText: formattedDate(ratingDate(game)),
                    color: ratingColor(rating),
                    quality: ratingQuality(rating),
                    onTap: () => onOpenGame(game),
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
                child: const Icon(
                  Icons.star_rounded,
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
                      Text(
                        dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF78716C),
                          fontSize: 11,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (hasComment)
                        Expanded(
                          child: Text(
                            '«$comment»',
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
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: color.withOpacity(0.35),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatRating(rating),
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllGamesForRatingScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final sortedGames = [...games];

    sortedGames.sort((a, b) {
      final aHasRating = a.userRating != null && a.userRating! > 0;
      final bHasRating = b.userRating != null && b.userRating! > 0;

      if (aHasRating != bHasRating) {
        return aHasRating ? 1 : -1;
      }

      if (aHasRating && bHasRating) {
        return ratingDate(b).compareTo(ratingDate(a));
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
                  final rating = ratingOutOfTen(game.userRating);
                  final hasRating = rating > 0;

                  return _AllGameForRatingCard(
                    game: game,
                    rating: rating,
                    hasRating: hasRating,
                    dateText: hasRating
                        ? formattedDate(ratingDate(game))
                        : formattedDate(game.addedAt),
                    color: hasRating
                        ? ratingColor(rating)
                        : const Color(0xFF75EEFD),
                    quality: hasRating ? ratingQuality(rating) : 'БЕЗ ОЦЕНКИ',
                    onTap: () => onOpenGame(
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
                      Text(
                        game.status.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF75EEFD),
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasRating ? 'Оценено:' : 'Добавлено:',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF78716C),
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFAAABAB),
                              fontSize: 11,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                  Row(
                    children: [
                      Text(
                        _formatRating(rating),
                        style: TextStyle(
                          color: color,
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star_rounded,
                        color: color,
                        size: 16,
                      ),
                    ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 14,
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
    final color = rating >= 9
        ? const Color(0xFF75EEFD)
        : rating >= 8
        ? const Color(0xFF61ACFE)
        : const Color(0xFFA8A29E);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF232626),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF464848).withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatRating(rating),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
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
        horizontal: 24,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF464848).withOpacity(0.30),
        ),
      ),
      child: const Text(
        'Статистика по жанрам появится позже',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF78716C),
          fontSize: 14,
          height: 1.4,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.hasRatings,
    required this.averageRating,
  });

  final bool hasRatings;
  final double averageRating;

  @override
  Widget build(BuildContext context) {
    final text = hasRatings
        ? averageRating >= 9
        ? '"Вы — настоящий ценитель качественных игр."'
        : '"Ваши оценки помогают лучше понять ваш игровой вкус."'
        : '"Начните оценивать игры, чтобы получить персональную аналитику вашего игрового пути."';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1D2020),
            Color(0xFF111414),
          ],
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border(
          left: BorderSide(
            color: Color(0xFF75EEFD),
            width: 4,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD6D3D1),
          fontSize: 16,
          height: 1.45,
          fontStyle: FontStyle.italic,
        ),
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
      color: const Color(0xFF1D2020),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 4),
                    Text(
                      game.status.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF75EEFD),
                        fontSize: 9,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
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
    );
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