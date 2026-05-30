import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../storage/library_storage.dart';
import '../game_progress/game_progress_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onAllGamesTap,
  });

  final VoidCallback? onAllGamesTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color background = Color(0xFF0C0F0F);

  final List<String> filters = [
    'Все',
    'Пройдено',
    'Играю',
    'Планирую',
  ];

  int selectedFilterIndex = 0;

  List<LibraryGameModel> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final loadedGames = await LibraryStorage.getAllGames();

    if (!mounted) return;

    loadedGames.sort((a, b) => b.addedAt.compareTo(a.addedAt));

    setState(() {
      games = loadedGames;
      isLoading = false;
    });
  }

  bool get hasGames => games.isNotEmpty;

  int get completedCount {
    return games.where((game) => game.status == 'Пройдено').length;
  }

  int get playingCount {
    return games.where((game) => game.status == 'Играю').length;
  }

  String get averageRatingText {
    final ratings = games
        .where((game) => game.userRating != null)
        .map((game) => game.userRating!.clamp(1, 10).toDouble())
        .toList();

    if (ratings.isEmpty) {
      return '-';
    }

    final sum = ratings.fold<double>(0, (previous, rating) {
      return previous + rating;
    });

    final average = sum / ratings.length;

    return _formatRating(average);
  }

  String _formatRating(double rating) {
    final roundedRating = double.parse(rating.toStringAsFixed(1));

    if (roundedRating == roundedRating.roundToDouble()) {
      return roundedRating.toInt().toString();
    }

    return roundedRating.toStringAsFixed(1);
  }

  List<LibraryGameModel> get filteredGames {
    final selectedFilter = filters[selectedFilterIndex];

    if (selectedFilter == 'Все') {
      return games.take(3).toList();
    }

    return games.where((game) => game.status == selectedFilter).take(3).toList();
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
        ),
      ),
    );

    await _loadGames();
  }

  void _openAllGames() {
    if (widget.onAllGamesTap != null) {
      widget.onAllGamesTap!();
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1D2020),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: Color(0x3322D3EE),
            ),
          ),
          content: const Text(
            'Откройте вкладку «Игры» в нижнем меню',
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final visibleGames = filteredGames;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF75EEFD),
          backgroundColor: const Color(0xFF111414),
          onRefresh: _loadGames,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(
                  onSearchTap: _openSearchScreen,
                ),

                const SizedBox(height: 32),

                if (isLoading)
                  const _HomeLoadingState()
                else ...[
                  _StatsSection(
                    completedCount: completedCount,
                    playingCount: playingCount,
                    averageRating: averageRatingText,
                  ),

                  const SizedBox(height: 32),

                  _FilterChips(
                    filters: filters,
                    selectedIndex: selectedFilterIndex,
                    onSelected: (index) {
                      setState(() {
                        selectedFilterIndex = index;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  _RecentActivitySection(
                    hasGames: hasGames,
                    visibleGames: visibleGames,
                    onAllGamesTap: _openAllGames,
                    onGameTap: _openGameProgress,
                  ),

                  const SizedBox(height: 32),

                  _AddGameButton(
                    onTap: _openSearchScreen,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onSearchTap,
  });

  final VoidCallback onSearchTap;

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
              'Главная',
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
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: accent,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: onSearchTap,
              icon: const Icon(
                Icons.search_rounded,
                color: accent,
                size: 30,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.completedCount,
    required this.playingCount,
    required this.averageRating,
  });

  final int completedCount;
  final int playingCount;
  final String averageRating;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'ПРОЙДЕНО',
                value: '$completedCount',
                subtitle: 'игры',
                color: const Color(0xFFBBFFB3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'ИГРАЮ',
                value: '$playingCount',
                subtitle: 'активных',
                color: const Color(0xFF61ACFE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'СРЕДНЯЯ ОЦЕНКА',
          value: averageRating,
          subtitle: '★',
          color: const Color(0xFF75EEFD),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2020),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(
                  bottom: subtitle == '★' ? 0.0 : 5.0,
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitle == '★'
                        ? color
                        : const Color(0xFFAAABAB),
                    fontSize: subtitle == '★' ? 24 : 14,
                    fontWeight: FontWeight.w600,
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF25B0BE)
                    : const Color(0xFF232626),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                filters[index],
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF00272B)
                      : const Color(0xFFAAABAB),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.hasGames,
    required this.visibleGames,
    required this.onAllGamesTap,
    required this.onGameTap,
  });

  final bool hasGames;
  final List<LibraryGameModel> visibleGames;
  final VoidCallback onAllGamesTap;
  final ValueChanged<LibraryGameModel> onGameTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          onAllGamesTap: onAllGamesTap,
        ),
        const SizedBox(height: 24),
        if (!hasGames)
          const _EmptyActivityState()
        else if (visibleGames.isEmpty)
          const _NoFilteredGamesState()
        else
          Column(
            children: [
              for (int i = 0; i < visibleGames.length; i++) ...[
                _GameActivityCard(
                  game: visibleGames[i],
                  imageIndex: i,
                  onTap: () => onGameTap(visibleGames[i]),
                ),
                if (i != visibleGames.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.onAllGamesTap,
  });

  final VoidCallback onAllGamesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Недавняя\nактивность',
          style: TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.75,
          ),
        ),
        TextButton(
          onPressed: onAllGamesTap,
          child: const Text(
            'ВСЕ\nИГРЫ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF75EEFD),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 44, horizontal: 8),
      child: Column(
        children: [
          Text(
            'Орбита пуста. Радары не\nзафиксировали игровой\nактивности',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Добавьте первый тайтл в коллекцию, чтобы\nзапустить трекинг',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoFilteredGamesState extends StatelessWidget {
  const _NoFilteredGamesState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 44, horizontal: 8),
      child: Text(
        'По выбранному фильтру игр пока нет',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFAAABAB),
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GameActivityCard extends StatelessWidget {
  const _GameActivityCard({
    required this.game,
    required this.imageIndex,
    required this.onTap,
  });

  final LibraryGameModel game;
  final int imageIndex;
  final VoidCallback onTap;

  bool get isCompleted => game.status == 'Пройдено';

  String get title {
    return game.title;
  }

  String get subtitle {
    if (isCompleted) {
      return 'ПРОЙДЕНО';
    }

    final hasPlayedTime = game.userHours > 0 || game.userMinutes > 0;

    if (!hasPlayedTime) {
      return 'нет сессий';
    }

    final hoursText = game.userHours > 0 ? '${game.userHours}ч' : '';
    final minutesText = game.userMinutes > 0 ? ' ${game.userMinutes}м' : '';

    return '${hoursText}${minutesText.trimRight()} сессия';
  }

  List<Color> get imageGradient {
    final gradients = [
      [
        const Color(0xFF1A322D),
        const Color(0xFFD7B95A),
      ],
      [
        const Color(0xFF1F0B2E),
        const Color(0xFFFF2BD6),
      ],
      [
        const Color(0xFF111F12),
        const Color(0xFF65724C),
      ],
      [
        const Color(0xFF143C45),
        const Color(0xFF75EEFD),
      ],
    ];

    return gradients[imageIndex % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF111414),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 112,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: isCompleted ? 0.58 : 1,
                child: Container(
                  width: 64,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: imageGradient,
                    ),
                  ),
                  child: Icon(
                    game.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.sports_esports_rounded,
                    color: Colors.white.withOpacity(0.18),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF4F3F3),
                        fontSize: 18,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.access_time_rounded,
                          color: isCompleted
                              ? const Color(0xFFBBFFB3)
                              : const Color(0xFFAAABAB),
                          size: isCompleted ? 11 : 12,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCompleted
                                  ? const Color(0xFFBBFFB3)
                                  : const Color(0xFFAAABAB),
                              fontSize: isCompleted ? 12 : 13,
                              height: 1.25,
                              fontWeight: isCompleted
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              letterSpacing: isCompleted ? 1.0 : 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF232626),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Завершено',
                    style: TextStyle(
                      color: Color(0xFFAAABAB),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF75EEFD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF00575F),
                        size: 15,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Играть',
                        style: TextStyle(
                          color: Color(0xFF00575F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _AddGameButton extends StatelessWidget {
  const _AddGameButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 68,
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
              color: const Color(0xFF75EEFD).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(
            Icons.add_circle_outline_rounded,
            color: Color(0xFF00575F),
            size: 24,
          ),
          label: const Text(
            'Добавить игру',
            style: TextStyle(
              color: Color(0xFF00575F),
              fontSize: 18,
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
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 160),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF75EEFD),
        ),
      ),
    );
  }
}