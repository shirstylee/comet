import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../models/user_profile_model.dart';
import '../../storage/library_change_notifier.dart';
import '../../storage/library_storage.dart';
import '../../storage/library_preferences_storage.dart';
import '../../storage/profile_storage.dart';
import '../notifications/notifications_screen.dart';
import 'widgets/empty_library_state.dart';
import 'widgets/library_filter_chip.dart';
import 'widgets/library_game_card.dart';
import 'widgets/library_grid_game_card.dart';

enum LibrarySortType {
  latest,
  titleAsc,
  titleDesc,
  ratingAsc,
  ratingDesc,
  favorites,
}

enum LibraryViewType {
  list,
  grid,
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
  LibraryViewType selectedViewType = LibraryViewType.list;

  List<LibraryGameModel> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadGames();
    _loadSavedLibraryPreferences();

    LibraryChangeNotifier.version.addListener(_onLibraryChanged);
    searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadSavedLibraryPreferences() async {
    final savedViewType = await LibraryPreferencesStorage.getViewType();
    final savedSortType = await LibraryPreferencesStorage.getSortType();

    if (!mounted) return;

    setState(() {
      selectedViewType =
      savedViewType == LibraryPreferencesStorage.gridViewType
          ? LibraryViewType.grid
          : LibraryViewType.list;

      selectedSortType = _sortTypeFromStorageValue(savedSortType);
    });
  }

  LibrarySortType _sortTypeFromStorageValue(String value) {
    switch (value) {
      case LibraryPreferencesStorage.titleAscSortType:
        return LibrarySortType.titleAsc;
      case LibraryPreferencesStorage.titleDescSortType:
        return LibrarySortType.titleDesc;
      case LibraryPreferencesStorage.ratingAscSortType:
        return LibrarySortType.ratingAsc;
      case LibraryPreferencesStorage.ratingDescSortType:
        return LibrarySortType.ratingDesc;
      case LibraryPreferencesStorage.favoritesSortType:
        return LibrarySortType.favorites;
      case LibraryPreferencesStorage.latestSortType:
      default:
        return LibrarySortType.latest;
    }
  }

  String _sortTypeToStorageValue(LibrarySortType sortType) {
    switch (sortType) {
      case LibrarySortType.titleAsc:
        return LibraryPreferencesStorage.titleAscSortType;
      case LibrarySortType.titleDesc:
        return LibraryPreferencesStorage.titleDescSortType;
      case LibrarySortType.ratingAsc:
        return LibraryPreferencesStorage.ratingAscSortType;
      case LibrarySortType.ratingDesc:
        return LibraryPreferencesStorage.ratingDescSortType;
      case LibrarySortType.favorites:
        return LibraryPreferencesStorage.favoritesSortType;
      case LibrarySortType.latest:
        return LibraryPreferencesStorage.latestSortType;
    }
  }

  Future<void> _selectSortType(
      BuildContext bottomSheetContext,
      LibrarySortType sortType,
      ) async {
    Navigator.pop(bottomSheetContext);

    setState(() {
      selectedSortType = sortType;
    });

    await LibraryPreferencesStorage.saveSortType(
      _sortTypeToStorageValue(sortType),
    );
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

  String get selectedViewTitle {
    switch (selectedViewType) {
      case LibraryViewType.list:
        return 'Список';
      case LibraryViewType.grid:
        return 'Сетка';
    }
  }

  IconData get selectedViewIcon {
    switch (selectedViewType) {
      case LibraryViewType.list:
        return Icons.view_agenda_rounded;
      case LibraryViewType.grid:
        return Icons.grid_view_rounded;
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

  void _openViewSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.46,
          minChildSize: 0.34,
          maxChildSize: 0.62,
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
                          'Вид библиотеки',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Выберите, как отображать игры',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _SortMenuItem(
                          icon: Icons.view_agenda_rounded,
                          title: 'Список',
                          subtitle: 'Одна большая карточка игры в строку',
                          isSelected: selectedViewType == LibraryViewType.list,
                          onTap: () async {
                            Navigator.pop(bottomSheetContext);

                            setState(() {
                              selectedViewType = LibraryViewType.list;
                            });

                            await LibraryPreferencesStorage.saveViewType(
                              LibraryPreferencesStorage.listViewType,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _SortMenuItem(
                          icon: Icons.grid_view_rounded,
                          title: 'Сетка',
                          subtitle: 'Компактная сетка с двумя карточками',
                          isSelected: selectedViewType == LibraryViewType.grid,
                          onTap: () async {
                            Navigator.pop(bottomSheetContext);

                            setState(() {
                              selectedViewType = LibraryViewType.grid;
                            });

                            await LibraryPreferencesStorage.saveViewType(
                              LibraryPreferencesStorage.gridViewType,
                            );
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
                            _selectSortType(
                              bottomSheetContext,
                              LibrarySortType.latest,
                            );
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
                            _selectSortType(
                              bottomSheetContext,
                              LibrarySortType.titleAsc,
                            );
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
                            _selectSortType(
                              bottomSheetContext,
                              LibrarySortType.titleDesc,
                            );
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
                            _selectSortType(
                              bottomSheetContext,
                              LibrarySortType.ratingAsc,
                            );
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
                            _selectSortType(
                              bottomSheetContext,
                              LibrarySortType.ratingDesc,
                            );
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
                            _selectSortType(
                              bottomSheetContext,
                              LibrarySortType.favorites,
                            );
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

  Future<void> _openNotificationsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
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
                onNotificationsTap: _openNotificationsScreen,
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
              const SizedBox(height: 10),
              _LibraryCollectionBadge(
                gamesCount: games.length,
              ),
              const SizedBox(height: 18),
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
              Row(
                children: [
                  _ViewModeButton(
                    title: selectedViewTitle,
                    icon: selectedViewIcon,
                    onTap: _openViewSheet,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _SortButton(
                        title: selectedSortTitle,
                        icon: selectedSortIcon,
                        onTap: _openSortSheet,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const _LibraryLoadingState()
              else if (!hasGames)
                const EmptyLibraryState()
              else if (visibleGames.isEmpty)
                  const _NothingFoundState()
                else
                  if (selectedViewType == LibraryViewType.list)
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
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleGames.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.58,
                      ),
                      itemBuilder: (context, index) {
                        final game = visibleGames[index];

                        return LibraryGridGameCard(
                          key: ValueKey('grid_${game.id}'),
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
    required this.onNotificationsTap,
  });

  final VoidCallback? onProfileTap;
  final VoidCallback onNotificationsTap;

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
          onTap: onNotificationsTap,
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

class _LibraryCollectionBadge extends StatelessWidget {
  const _LibraryCollectionBadge({
    required this.gamesCount,
  });

  final int gamesCount;

  String get gamesWord {
    final lastTwoDigits = gamesCount % 100;
    final lastDigit = gamesCount % 10;

    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return 'игр';
    }

    if (lastDigit == 1) {
      return 'игра';
    }

    if (lastDigit >= 2 && lastDigit <= 4) {
      return 'игры';
    }

    return 'игр';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 33,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF101515),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0x5532B8C6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0x1475EEFD),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0x3375EEFD),
                ),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                color: Color(0xFF75EEFD),
                size: 15,
              ),
            ),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$gamesCount $gamesWord',
                    style: const TextStyle(
                      color: Color(0xFF75EEFD),
                      fontSize: 12.8,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.05,
                    ),
                  ),
                  const TextSpan(
                    text: '  в коллекции',
                    style: TextStyle(
                      color: Color(0xFFAAABAB),
                      fontSize: 12.8,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.05,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySearchField extends StatefulWidget {
  const _LibrarySearchField({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<_LibrarySearchField> createState() => _LibrarySearchFieldState();
}

class _LibrarySearchFieldState extends State<_LibrarySearchField> {
  final FocusNode focusNode = FocusNode();

  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  @override
  void initState() {
    super.initState();

    focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _LibrarySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;

    setState(() {});
  }

  void _onTextChanged() {
    if (!mounted) return;

    setState(() {});
  }

  void _clearSearch() {
    widget.controller.clear();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 48,
      padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFocused
              ? const [
            Color(0xFF111C1D),
            Color(0xFF1B2424),
            Color(0xFF102B2F),
          ]
              : const [
            Color(0xFF151A1A),
            Color(0xFF202424),
            Color(0xFF141A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isFocused
              ? const Color(0x8875EEFD)
              : const Color(0x5532B8C6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.34),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(
              isFocused ? 0.12 : 0.055,
            ),
            blurRadius: isFocused ? 26 : 18,
            spreadRadius: isFocused ? 0.6 : 0,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isFocused
                  ? const Color(0x2275EEFD)
                  : const Color(0x1022D3EE),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isFocused
                    ? const Color(0x7775EEFD)
                    : const Color(0x4432B8C6),
              ),
            ),
            child: Icon(
              Icons.search_rounded,
              color: isFocused
                  ? const Color(0xFF75EEFD)
                  : const Color(0xFFAAABAB),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: widget.controller,
              cursorColor: const Color(0xFF75EEFD),
              onTapOutside: (_) {
                focusNode.unfocus();
              },
              style: const TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
              decoration: InputDecoration(
                hintText: 'Поиск игр...',
                border: InputBorder.none,
                isCollapsed: true,
                hintStyle: TextStyle(
                  color: textSecondary.withOpacity(0.72),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              );
            },
            child: hasText
                ? Padding(
              key: const ValueKey('clear_search_button'),
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onTap: _clearSearch,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0x1A75EEFD),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0x5575EEFD),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF75EEFD).withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF75EEFD),
                    size: 19,
                  ),
                ),
              ),
            )
                : const SizedBox.shrink(
              key: ValueKey('empty_clear_search_button'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
              Icon(
                icon,
                color: const Color(0xFF75EEFD),
                size: 17,
              ),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 104,
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
    return Material(
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
              Icon(
                icon,
                color: const Color(0xFF75EEFD),
                size: 17,
              ),
              const SizedBox(width: 5),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 104,
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