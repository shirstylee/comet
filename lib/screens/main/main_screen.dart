import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/app_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../ratings/ratings_screen.dart';
import '../search/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<int> tabHistory = [0];

  final GlobalKey<_LibraryTabHolderState> libraryTabKey =
  GlobalKey<_LibraryTabHolderState>();

  final GlobalKey<_RatingsTabHolderState> ratingsTabKey =
  GlobalKey<_RatingsTabHolderState>();

  late final List<Widget> screens = [
    HomeScreen(
      onAllGamesTap: _openLibraryTab,
      onProfileTap: _openProfileTab,
    ),
    _LibraryTabHolder(
      key: libraryTabKey,
      onProfileTap: _openProfileTab,
    ),
    _RatingsTabHolder(
      key: ratingsTabKey,
      onProfileTap: _openProfileTab,
    ),
    const ProfileScreen(),
  ];

  void _setTab(
      int index, {
        bool addToHistory = true,
      }) {
    if (index < 0 || index >= screens.length) {
      return;
    }

    if (currentIndex == index) {
      return;
    }

    setState(() {
      currentIndex = index;

      if (!addToHistory) {
        return;
      }

      if (tabHistory.isEmpty || tabHistory.last != index) {
        tabHistory.add(index);
      }
    });
  }

  void _openPreviousTabOrExit() {
    if (tabHistory.length > 1) {
      setState(() {
        tabHistory.removeLast();
        currentIndex = tabHistory.last;
      });

      return;
    }

    if (currentIndex != 0) {
      setState(() {
        currentIndex = 0;
        tabHistory
          ..clear()
          ..add(0);
      });

      return;
    }

    SystemNavigator.pop();
  }

  void _openLibraryTab() {
    libraryTabKey.currentState?.refreshLibrary();
    _setTab(1);
  }

  void _openProfileTab() {
    _setTab(3);
  }

  Future<void> _openSearchScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );

    if (!mounted) return;

    libraryTabKey.currentState?.refreshLibrary();
    _setTab(1);
  }

  void _openAllGamesForRating() {
    _setTab(2);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ratingsTabKey.currentState?.openAllGamesForRating();
    });
  }

  void _openAddMenu() {
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
              color: const Color(0xFF111414),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF75EEFD).withOpacity(0.16),
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
                      color: const Color(0xFFAAABAB).withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Быстрое действие',
                    style: TextStyle(
                      color: Color(0xFFF4F3F3),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Выберите, что хотите сделать',
                    style: TextStyle(
                      color: Color(0xFFAAABAB),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _AddMenuItem(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Добавить игру',
                    subtitle: 'Найти игру и добавить её в коллекцию',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _openSearchScreen();
                    },
                  ),
                  const SizedBox(height: 12),
                  _AddMenuItem(
                    icon: Icons.star_border_rounded,
                    title: 'Оставить оценку',
                    subtitle: 'Открыть список игр для оценки',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _openAllGamesForRating();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleNavTap(int index) {
    if (index == 2) {
      _openAddMenu();
      return;
    }

    final tabIndex = index > 2 ? index - 1 : index;

    if (tabIndex == 1) {
      libraryTabKey.currentState?.refreshLibrary();
    }

    _setTab(tabIndex);
  }

  int get bottomNavIndex {
    if (currentIndex >= 2) {
      return currentIndex + 1;
    }

    return currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }

        _openPreviousTabOrExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0F0F),
        body: Stack(
          children: [
            Positioned.fill(
              child: screens[currentIndex],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNavBar(
                currentIndex: bottomNavIndex,
                onTap: _handleNavTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTabHolder extends StatefulWidget {
  const _LibraryTabHolder({
    super.key,
    this.onProfileTap,
  });

  final VoidCallback? onProfileTap;

  @override
  State<_LibraryTabHolder> createState() => _LibraryTabHolderState();
}

class _LibraryTabHolderState extends State<_LibraryTabHolder> {
  int refreshKey = 0;

  void refreshLibrary() {
    setState(() {
      refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LibraryScreen(
      key: ValueKey(refreshKey),
      onProfileTap: widget.onProfileTap,
    );
  }
}

class _RatingsTabHolder extends StatefulWidget {
  const _RatingsTabHolder({
    super.key,
    this.onProfileTap,
  });

  final VoidCallback? onProfileTap;

  @override
  State<_RatingsTabHolder> createState() => _RatingsTabHolderState();
}

class _RatingsTabHolderState extends State<_RatingsTabHolder> {
  int refreshKey = 0;
  bool openAllGamesOnStart = false;

  void openAllGamesForRating() {
    setState(() {
      refreshKey++;
      openAllGamesOnStart = true;
    });
  }

  void _handleAutoOpenHandled() {
    if (!mounted) {
      return;
    }

    setState(() {
      openAllGamesOnStart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RatingsScreen(
      key: ValueKey(refreshKey),
      onProfileTap: widget.onProfileTap,
      openAllGamesOnStart: openAllGamesOnStart,
      onAutoOpenHandled: _handleAutoOpenHandled,
    );
  }
}

class _AddMenuItem extends StatelessWidget {
  const _AddMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D2020),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF75EEFD),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF4F3F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF75EEFD),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}