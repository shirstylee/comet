import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../storage/library_storage.dart';

class SettingsStatisticsScreen extends StatefulWidget {
  const SettingsStatisticsScreen({super.key});

  @override
  State<SettingsStatisticsScreen> createState() => _SettingsStatisticsScreenState();
}

class _SettingsStatisticsScreenState extends State<SettingsStatisticsScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color headerBackground = Color(0xCC0C0F0F);
  static const Color surface = Color(0xFF1D2020);
  static const Color darkSurface = Color(0xFF111414);
  static const Color accent = Color(0xFF75EEFD);
  static const Color success = Color(0xFFBBFFB3);
  static const Color blue = Color(0xFF61ACFE);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  bool isLoading = true;
  List<LibraryGameModel> games = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final loadedGames = await LibraryStorage.getAllGames();

    if (!mounted) return;

    setState(() {
      games = loadedGames;
      isLoading = false;
    });
  }

  int get gamesCount => games.length;

  int get completedGamesCount {
    return games.where((game) {
      return game.status.trim().toLowerCase() == 'пройдено';
    }).length;
  }

  int get ratedGamesCount {
    return games.where((game) {
      return game.userRating != null && game.userRating! > 0;
    }).length;
  }

  int get stagesCount {
    var count = 0;

    for (final game in games) {
      count += game.stages.where((stage) {
        return stage.title.trim().toLowerCase() != 'начало игры';
      }).length;
    }

    return count;
  }

  int get totalPlayedMinutes {
    var total = 0;

    for (final game in games) {
      total += game.userHours * 60 + game.userMinutes;
    }

    return total;
  }

  String get totalPlayedTimeText {
    final hours = totalPlayedMinutes ~/ 60;
    final minutes = totalPlayedMinutes % 60;

    if (hours <= 0 && minutes <= 0) return '0ч.';
    if (minutes <= 0) return '${hours}ч.';

    return '${hours}ч. ${minutes}м.';
  }

  String get averageRatingText {
    final ratedGames = games.where((game) {
      return game.userRating != null && game.userRating! > 0;
    }).toList();

    if (ratedGames.isEmpty) return '—/10';

    final totalRating = ratedGames.fold<double>(
      0,
          (sum, game) => sum + game.userRating!,
    );

    final averageRating = totalRating / ratedGames.length;
    final roundedRating = double.parse(averageRating.toStringAsFixed(1));

    if (roundedRating == roundedRating.roundToDouble()) {
      return '${roundedRating.toInt()}/10';
    }

    return '${roundedRating.toStringAsFixed(1)}/10';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _StatisticsHeader(
              title: 'Статистика',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: accent,
                ),
              )
                  : RefreshIndicator(
                color: accent,
                backgroundColor: darkSurface,
                onRefresh: _loadStatistics,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 40),
                  children: [
                    _StatisticsHero(
                      gamesCount: gamesCount,
                      completedGamesCount: completedGamesCount,
                      averageRatingText: averageRatingText,
                      totalPlayedTimeText: totalPlayedTimeText,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _StatisticsCard(
                            icon: Icons.sports_esports_rounded,
                            title: 'Игр в библиотеке',
                            value: gamesCount.toString(),
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticsCard(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Пройдено игр',
                            value: completedGamesCount.toString(),
                            color: success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatisticsCard(
                            icon: Icons.star_rounded,
                            title: 'Оценено игр',
                            value: ratedGamesCount.toString(),
                            color: const Color(0xFFFACC15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticsCard(
                            icon: Icons.timeline_rounded,
                            title: 'Этапов прохождения',
                            value: stagesCount.toString(),
                            color: blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _StatisticsInfoPanel(
                      gamesCount: gamesCount,
                      completedGamesCount: completedGamesCount,
                      ratedGamesCount: ratedGamesCount,
                      stagesCount: stagesCount,
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

class _StatisticsHeader extends StatelessWidget {
  const _StatisticsHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      color: _SettingsStatisticsScreenState.headerBackground,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 24,
            child: _StatisticsBackButton(
              onTap: onBack,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _SettingsStatisticsScreenState.textPrimary,
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsBackButton extends StatelessWidget {
  const _StatisticsBackButton({
    required this.onTap,
  });

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
        child: const Icon(
          Icons.arrow_back_rounded,
          color: _SettingsStatisticsScreenState.accent,
          size: 23,
        ),
      ),
    );
  }
}

class _StatisticsHero extends StatelessWidget {
  const _StatisticsHero({
    required this.gamesCount,
    required this.completedGamesCount,
    required this.averageRatingText,
    required this.totalPlayedTimeText,
  });

  final int gamesCount;
  final int completedGamesCount;
  final String averageRatingText;
  final String totalPlayedTimeText;

  String get subtitle {
    if (gamesCount == 0) {
      return 'Локальная орбита пока пустая. Добавьте игры, чтобы Comet начал собирать статистику.';
    }

    return 'Comet хранит вашу игровую орбиту локально: игры, оценки, статусы и этапы прохождения.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _SettingsStatisticsScreenState.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF232626),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.10),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF081F23),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0x6632B8C6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF75EEFD).withOpacity(0.16),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: _SettingsStatisticsScreenState.accent,
                  size: 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Игровая орбита',
                      style: TextStyle(
                        color: _SettingsStatisticsScreenState.textPrimary,
                        fontSize: 23,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _SettingsStatisticsScreenState.textSecondary,
                        fontSize: 13,
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroMiniPill(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Средняя оценка',
                  value: averageRatingText,
                  color: const Color(0xFFFACC15),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMiniPill(
                  icon: Icons.schedule_rounded,
                  title: 'Время в играх',
                  value: totalPlayedTimeText,
                  color: _SettingsStatisticsScreenState.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMiniPill extends StatelessWidget {
  const _HeroMiniPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SettingsStatisticsScreenState.textSecondary,
                    fontSize: 9,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.11),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _SettingsStatisticsScreenState.textPrimary,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsInfoPanel extends StatelessWidget {
  const _StatisticsInfoPanel({
    required this.gamesCount,
    required this.completedGamesCount,
    required this.ratedGamesCount,
    required this.stagesCount,
  });

  final int gamesCount;
  final int completedGamesCount;
  final int ratedGamesCount;
  final int stagesCount;

  int get completionPercent {
    if (gamesCount == 0) return 0;

    return ((completedGamesCount / gamesCount) * 100).round();
  }

  int get ratedPercent {
    if (gamesCount == 0) return 0;

    return ((ratedGamesCount / gamesCount) * 100).round();
  }

  String get activityText {
    if (gamesCount == 0) {
      return 'Пока данных нет. Добавьте игры в библиотеку, чтобы здесь появился личный игровой след.';
    }

    if (completedGamesCount == gamesCount) {
      return 'Вся библиотека закрыта. Отличная орбита завершённых игр.';
    }

    if (stagesCount >= gamesCount && stagesCount > 0) {
      return 'Квест-лог активно заполняется: у игр уже есть подробные этапы прохождения.';
    }

    return 'Comet видит основу библиотеки. Чем больше оценок и этапов, тем точнее личная статистика.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _SettingsStatisticsScreenState.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x2632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Игровой след',
            style: TextStyle(
              color: _SettingsStatisticsScreenState.textPrimary,
              fontSize: 19,
              height: 1.25,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            activityText,
            style: const TextStyle(
              color: _SettingsStatisticsScreenState.textSecondary,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          _StatisticsProgressLine(
            title: 'Пройдено библиотеки',
            value: completionPercent,
            color: _SettingsStatisticsScreenState.success,
          ),
          const SizedBox(height: 14),
          _StatisticsProgressLine(
            title: 'Игр с личной оценкой',
            value: ratedPercent,
            color: const Color(0xFFFACC15),
          ),

        ],
      ),
    );
  }
}

class _StatisticsProgressLine extends StatelessWidget {
  const _StatisticsProgressLine({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _SettingsStatisticsScreenState.textPrimary,
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$safeValue%',
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeValue / 100,
            minHeight: 8,
            color: color,
            backgroundColor: const Color(0xFF111414),
          ),
        ),
      ],
    );
  }
}
