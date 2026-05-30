import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../storage/library_storage.dart';
import '../game_progress/game_progress_screen.dart';
import '../search/search_screen.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

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

  int? lastOpenedGameId;

  @override
  void initState() {
    super.initState();
    _loadGames();
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
  }

  void _showMessage(String text) {
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

      return b.addedAt.compareTo(a.addedAt);
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
      final genre = _genreForGame(game.title);
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

  String _genreForGame(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('witcher')) return 'RPG';
    if (lowerTitle.contains('elden')) return 'RPG';
    if (lowerTitle.contains('cyberpunk')) return 'RPG';
    if (lowerTitle.contains('mario')) return 'Platformer';
    if (lowerTitle.contains('alan')) return 'Horror';

    return 'Action';
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

  Future<void> _openSearchScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );

    await _loadGames();
  }

  Future<void> _openGameProgress(LibraryGameModel game) async {
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
          rating: game.apiRating ?? 0,
        ),
      ),
    );

    await _loadGames();
  }

  void _openGamePicker() {
    if (games.isEmpty) {
      _openSearchScreen();
      return;
    }

    final gamesWithoutRating = unratedGames;

    if (gamesWithoutRating.isEmpty) {
      _showMessage('Все игры уже оценены');
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
            padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 20),
                  const Text(
                    'Выберите игру',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Показываются только игры без оценки',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: gamesWithoutRating.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final game = gamesWithoutRating[index];

                        return _GamePickerItem(
                          game: game,
                          rating: 0,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            _openGameProgress(game);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _openSearchScreen();
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        color: accent,
                      ),
                      label: const Text(
                        'Добавить новую игру',
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
              const _RatingsHeader(),
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
              if (hasRatings)
                Column(
                  children: recentGames.map((game) {
                    final rating = _ratingOutOfTen(game.userRating);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RecentlyRatedCard(
                        game: game,
                        rating: rating,
                        dateText: _formattedDate(game.addedAt),
                        color: _ratingColor(rating),
                        quality: _ratingQuality(rating),
                        onTap: () => _openGameProgress(game),
                      ),
                    );
                  }).toList(),
                )
              else
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
  const _RatingsHeader();

  static const Color accent = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
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
              child: const Icon(
                Icons.person_rounded,
                color: accent,
                size: 24,
              ),
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
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: accent,
            size: 28,
          ),
        ),
      ],
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
            averageRating.toStringAsFixed(1),
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
              _GameCoverPlaceholder(
                title: game.title,
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
                        rating.toStringAsFixed(1),
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

class _GameCoverPlaceholder extends StatelessWidget {
  const _GameCoverPlaceholder({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final lowerTitle = title.toLowerCase();

    final colors = lowerTitle.contains('alan')
        ? const [
      Color(0xFF2A0505),
      Color(0xFFC70B0B),
    ]
        : lowerTitle.contains('mario')
        ? const [
      Color(0xFF0A6FA8),
      Color(0xFFEE3D3D),
    ]
        : lowerTitle.contains('cyberpunk')
        ? const [
      Color(0xFF263A3A),
      Color(0xFFE6D845),
    ]
        : const [
      Color(0xFF172026),
      Color(0xFF4D5D60),
    ];

    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white.withOpacity(0.32),
          size: 30,
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
            rating.toStringAsFixed(1),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _GameCoverPlaceholder(title: game.title),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hasRating ? rating.toStringAsFixed(1) : '—',
                style: TextStyle(
                  color: hasRating
                      ? const Color(0xFF75EEFD)
                      : const Color(0xFFAAABAB),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star_border_rounded,
                color: hasRating
                    ? const Color(0xFF75EEFD)
                    : const Color(0xFFAAABAB),
                size: 16,
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