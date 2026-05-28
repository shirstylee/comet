import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../storage/library_storage.dart';
import 'widgets/empty_library_state.dart';
import 'widgets/library_filter_chip.dart';
import 'widgets/library_game_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color accent = Color(0xFF22D3EE);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  final TextEditingController searchController = TextEditingController();

  final List<String> filters = ['Все', 'Пройдено', 'Играю', 'Планирую'];
  int selectedFilterIndex = 0;

  List<LibraryGameModel> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadGames();

    searchController.addListener(() {
      setState(() {});
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
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<LibraryGameModel> get filteredGames {
    final query = searchController.text.trim().toLowerCase();
    final selectedFilter = filters[selectedFilterIndex];

    return games.where((game) {
      final matchesSearch =
          query.isEmpty || game.title.toLowerCase().startsWith(query);

      final matchesFilter = selectedFilter == 'Все' ||
          game.status.toLowerCase() == selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool get hasGames => games.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final visibleGames = filteredGames;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LibraryHeader(),

              const SizedBox(height: 34),

              Text(
                'Библиотека',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: hasGames ? 30 : 36,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${games.length} игр в вашей коллекции',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: hasGames ? 14 : 16,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              _LibrarySearchField(
                controller: searchController,
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return LibraryFilterChip(
                      text: filters[index],
                      isSelected: selectedFilterIndex == index,
                      onTap: () {
                        setState(() {
                          selectedFilterIndex = index;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              const _SortButton(),

              const SizedBox(height: 32),

              if (isLoading)
                const _LibraryLoadingState()
              else if (!hasGames)
                const EmptyLibraryState()
              else if (visibleGames.isEmpty)
                  const _NothingFoundState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visibleGames.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 28),
                    itemBuilder: (context, index) {
                      return LibraryGameCard(
                        game: visibleGames[index],
                        imageIndex: index,
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

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
              'Игры',
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

class _LibrarySearchField extends StatelessWidget {
  const _LibrarySearchField({
    required this.controller,
  });

  final TextEditingController controller;

  static const Color surface = Color(0xFF232626);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: textSecondary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              cursorColor: const Color(0xFF75EEFD),
              style: const TextStyle(
                color: textPrimary,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: 'Поиск игр...',
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2020),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'СОРТИРОВКА:',
              style: TextStyle(
                color: Color(0xFFAAABAB),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Последние',
              style: TextStyle(
                color: Color(0xFF75EEFD),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF75EEFD),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryLoadingState extends StatelessWidget {
  const _LibraryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF75EEFD),
        ),
      ),
    );
  }
}

class _NothingFoundState extends StatelessWidget {
  const _NothingFoundState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Text(
          'Ничего не найдено',
          style: TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}