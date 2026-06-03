import 'package:flutter/material.dart';

import '../../data/mock_games.dart';
import '../../models/game_model.dart';
import '../../widgets/game_search_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color background = Color(0xFF0C0F0F);

  final TextEditingController searchController = TextEditingController();

  List<GameModel> results = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_searchGames);
  }

  @override
  void dispose() {
    searchController.removeListener(_searchGames);
    searchController.dispose();
    super.dispose();
  }

  void _searchGames() {
    final query = searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        results = [];
        return;
      }

      results = mockGames.where((game) {
        return _matchesGameTitle(
          title: game.title,
          query: query,
        );
      }).toList();
    });
  }

  bool _matchesGameTitle({
    required String title,
    required String query,
  }) {
    final normalizedTitle = title.toLowerCase();

    final words = normalizedTitle
        .split(RegExp(r'[^a-zа-я0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return words.any((word) => word.startsWith(query));
  }

  void _clearSearch() {
    searchController.clear();
  }

  bool get _isInitialState => searchController.text.trim().isEmpty;

  bool get _isNoResultsState =>
      searchController.text.trim().isNotEmpty && results.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          _SearchHeader(
            controller: searchController,
            onBack: () => Navigator.pop(context),
            onClear: _clearSearch,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialState) {
      return const _InitialSearchState(
        key: ValueKey('initial-search-state'),
      );
    }

    if (_isNoResultsState) {
      return _NoResultsState(
        key: const ValueKey('no-results-state'),
        query: searchController.text.trim(),
      );
    }

    return _ResultsState(
      key: const ValueKey('results-state'),
      results: results,
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.onBack,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final VoidCallback onClear;

  static const Color headerColor = Color(0xCC0C0F0F);
  static const Color fieldColor = Color(0xFF1D2020);
  static const Color borderColor = Color(0xFF232626);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 67,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: headerColor,
          border: Border(
            bottom: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: const SizedBox(
                width: 32,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: textSecondary,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        cursorColor: const Color(0xFF75EEFD),
                        style: const TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Начните вводить название',
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintStyle: TextStyle(
                            color: textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.close_rounded,
                        color: textSecondary,
                        size: 26,
                      ),
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

class _InitialSearchState extends StatelessWidget {
  const _InitialSearchState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SearchStateIcon(
              icon: Icons.explore_rounded,
              color: Color(0xFF75EEFD),
              backgroundColor: Color(0x1A75EEFD),
              size: 96,
              iconSize: 42,
            ),
            SizedBox(height: 24),
            Text(
              'Поиск новых миров',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF75EEFD),
                fontSize: 30,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.75,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Найдите любой тайтл среди тысяч\nигр и добавьте на свою орбиту',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAABAB),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({
    super.key,
    required this.query,
  });

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          const _ResultsTitle(
            count: 0,
          ),
          const SizedBox(height: 96),
          Icon(
            Icons.manage_search_rounded,
            color: const Color(0xFFAAABAB).withOpacity(0.3),
            size: 76,
          ),
          const SizedBox(height: 28),
          const Text(
            'Ничего не найдено',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Попробуйте изменить запрос или\nпроверить написание названия игры.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsState extends StatelessWidget {
  const _ResultsState({
    super.key,
    required this.results,
  });

  final List<GameModel> results;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      itemCount: results.length + 1,
      separatorBuilder: (_, index) {
        if (index == 0) return const SizedBox(height: 24);
        return const SizedBox(height: 16);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return _ResultsTitle(
            count: results.length,
          );
        }

        final gameIndex = index - 1;
        final game = results[gameIndex];

        return GameSearchCard(
          game: game,
          index: gameIndex,
        );
      },
    );
  }
}

class _ResultsTitle extends StatelessWidget {
  const _ResultsTitle({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Результаты',
          style: TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Найдено: $count',
          style: const TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SearchStateIcon extends StatelessWidget {
  const _SearchStateIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}