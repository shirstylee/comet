import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../models/user_profile_model.dart';
import '../../storage/library_change_notifier.dart';
import '../../storage/library_storage.dart';
import '../../storage/profile_storage.dart';
import 'widgets/empty_library_state.dart';
import 'widgets/library_filter_chip.dart';
import 'widgets/library_game_card.dart';

enum LibrarySortType {
  latest,
  titleAsc,
  titleDesc,
  ratingAsc,
  ratingDesc,
  favorites,
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    this.onProfileTap,
  });

  final VoidCallback? onProfileTap;

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

  LibrarySortType selectedSortType = LibrarySortType.latest;

  List<LibraryGameModel> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadGames();

    LibraryChangeNotifier.version.addListener(_onLibraryChanged);
    searchController.addListener(_onSearchChanged);
  }

  void _onLibraryChanged() {
    if (!mounted) return;

    _loadGames();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadGames() async {
    final loadedGames = await LibraryStorage.getAllGames();

    if (!mounted) return;

    setState(() {
      games = loadedGames;
      isLoading = false;
    });
  }

  String get selectedSortTitle {
    switch (selectedSortType) {
      case LibrarySortType.latest:
        return 'Последние';
      case LibrarySortType.titleAsc:
        return 'По названию (А → Я)';
      case LibrarySortType.titleDesc:
        return 'По названию (Я → А)';
      case LibrarySortType.ratingAsc:
        return 'Оценка ↑';
      case LibrarySortType.ratingDesc:
        return 'Оценка ↓';
      case LibrarySortType.favorites:
        return 'Избранные';
    }
  }

  IconData get selectedSortIcon {
    switch (selectedSortType) {
      case LibrarySortType.latest:
        return Icons.schedule_rounded;
      case LibrarySortType.titleAsc:
        return Icons.sort_by_alpha_rounded;
      case LibrarySortType.titleDesc:
        return Icons.sort_by_alpha_rounded;
      case LibrarySortType.ratingAsc:
        return Icons.arrow_upward_rounded;
      case LibrarySortType.ratingDesc:
        return Icons.arrow_downward_rounded;
      case LibrarySortType.favorites:
        return Icons.favorite_rounded;
    }
  }

  double _ratingOf(LibraryGameModel game) {
    return game.userRating ?? game.apiRating ?? 0;
  }

  List<LibraryGameModel> _sortGames(List<LibraryGameModel> source) {
    final sortedGames = [...source];

    switch (selectedSortType) {
      case LibrarySortType.latest:
        sortedGames.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;

      case LibrarySortType.titleAsc:
        sortedGames.sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;

      case LibrarySortType.titleDesc:
        sortedGames.sort(
              (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;

      case LibrarySortType.ratingAsc:
        sortedGames.sort((a, b) => _ratingOf(a).compareTo(_ratingOf(b)));
        break;

      case LibrarySortType.ratingDesc:
        sortedGames.sort((a, b) => _ratingOf(b).compareTo(_ratingOf(a)));
        break;

      case LibrarySortType.favorites:
        sortedGames.sort((a, b) {
          final favoriteCompare =
          (b.isFavorite ? 1 : 0).compareTo(a.isFavorite ? 1 : 0);

          if (favoriteCompare != 0) {
            return favoriteCompare;
          }

          return b.addedAt.compareTo(a.addedAt);
        });
        break;
    }

    return sortedGames;
  }

  Future<void> _deleteGameFromLibrary(LibraryGameModel game) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D2020),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Удалить игру?',
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Игра «${game.title}» будет удалена из вашей библиотеки. '
                'Оценка, комментарий, время и этапы прохождения тоже удалятся.',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF081F23),
                foregroundColor: const Color(0xFF75EEFD),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(
                    color: Color(0x6632B8C6),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Отмена',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0x33EF4444),
                foregroundColor: const Color(0xFFFF7A7A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: const BorderSide(
                    color: Color(0x66EF4444),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Удалить',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await LibraryStorage.deleteGame(game.id);

    if (!mounted) return;

    setState(() {
      games.removeWhere((item) => item.id == game.id);
    });

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
          content: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0x3322D3EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Игра удалена из библиотеки',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111414),
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
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _BottomSheetHandle(),
                        const SizedBox(height: 20),
                        const Text(
                          'Сортировка',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Выберите порядок отображения игр',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SortMenuItem(
                          icon: Icons.schedule_rounded,
                          title: 'Последние',
                          subtitle: 'Новые добавленные игры сверху',
                          isSelected:
                          selectedSortType == LibrarySortType.latest,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              selectedSortType = LibrarySortType.latest;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SortMenuItem(
                          icon: Icons.sort_by_alpha_rounded,
                          title: 'По названию (А → Я)',
                          subtitle: 'Сортировка названий от А до Я',
                          isSelected:
                          selectedSortType == LibrarySortType.titleAsc,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              selectedSortType = LibrarySortType.titleAsc;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SortMenuItem(
                          icon: Icons.sort_by_alpha_rounded,
                          title: 'По названию (Я → А)',
                          subtitle: 'Сортировка названий от Я до А',
                          isSelected:
                          selectedSortType == LibrarySortType.titleDesc,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              selectedSortType = LibrarySortType.titleDesc;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SortMenuItem(
                          icon: Icons.arrow_upward_rounded,
                          title: 'Оценка ↑',
                          subtitle: 'Сначала игры с низкой оценкой',
                          isSelected:
                          selectedSortType == LibrarySortType.ratingAsc,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              selectedSortType = LibrarySortType.ratingAsc;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SortMenuItem(
                          icon: Icons.arrow_downward_rounded,
                          title: 'Оценка ↓',
                          subtitle: 'Сначала игры с высокой оценкой',
                          isSelected:
                          selectedSortType == LibrarySortType.ratingDesc,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              selectedSortType = LibrarySortType.ratingDesc;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SortMenuItem(
                          icon: Icons.favorite_rounded,
                          title: 'Избранные',
                          subtitle: 'Игры с сердечком будут сверху',
                          isSelected:
                          selectedSortType == LibrarySortType.favorites,
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              selectedSortType = LibrarySortType.favorites;
                            });
                          },
                        ),
                      ],
                    ),
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
  void dispose() {
    LibraryChangeNotifier.version.removeListener(_onLibraryChanged);
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  List<LibraryGameModel> get filteredGames {
    final query = searchController.text.trim().toLowerCase();
    final selectedFilter = filters[selectedFilterIndex].toLowerCase();

    final filtered = games.where((game) {
      final title = game.title.trim().toLowerCase();
      final status = game.status.trim().toLowerCase();

      final matchesSearch = query.isEmpty || title.contains(query);
      final matchesFilter = selectedFilter == 'все' || status == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    return _sortGames(filtered);
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
              _LibraryHeader(
                onProfileTap: widget.onProfileTap,
              ),
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
              _SortButton(
                title: selectedSortTitle,
                icon: selectedSortIcon,
                onTap: _openSortSheet,
              ),
              const SizedBox(height: 24),
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
                      final game = visibleGames[index];

                      return LibraryGameCard(
                        key: ValueKey(game.id),
                        game: game,
                        imageIndex: index,
                        onDelete: () {
                          _deleteGameFromLibrary(game);
                        },
                        onGameChanged: _loadGames,
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
  const _LibraryHeader({
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
        final hasAvatar = avatarPath != null &&
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
  const _SortButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2020),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0x2275EEFD),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF75EEFD).withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'СОРТИРОВКА:',
                  style: TextStyle(
                    color: Color(0xFFAAABAB),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  icon,
                  color: const Color(0xFF75EEFD),
                  size: 17,
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 150,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF75EEFD),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF75EEFD),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortMenuItem extends StatelessWidget {
  const _SortMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF75EEFD) : const Color(0xFFAAABAB);

    return Material(
      color: isSelected ? const Color(0x2675EEFD) : const Color(0xFF1D2020),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0x6675EEFD) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF75EEFD)
                            : const Color(0xFFF4F3F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? const Color(0xFF75EEFD)
                    : const Color(0xFF747675),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFAAABAB).withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
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