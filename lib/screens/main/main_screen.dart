import 'package:flutter/material.dart';

import '../../widgets/app_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../search/search_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final GlobalKey<_LibraryTabHolderState> libraryTabKey =
  GlobalKey<_LibraryTabHolderState>();

  late final List<Widget> screens = [
    const HomeScreen(),
    _LibraryTabHolder(key: libraryTabKey),
    const _TempScreen(title: 'Оценки'),
    const _TempScreen(title: 'Профиль'),
  ];

  Future<void> _openSearchScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );

    if (!mounted) return;

    libraryTabKey.currentState?.refreshLibrary();

    setState(() {
      currentIndex = 1;
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
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Оставить комментарий',
                    subtitle: 'Сначала выберите игру из библиотеки',
                    onTap: () {
                      Navigator.pop(bottomSheetContext);

                      setState(() {
                        currentIndex = 1;
                      });
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

    setState(() {
      if (index > 2) {
        currentIndex = index - 1;
      } else {
        currentIndex = index;
      }
    });
  }

  int get bottomNavIndex {
    if (currentIndex >= 2) {
      return currentIndex + 1;
    }

    return currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}

class _LibraryTabHolder extends StatefulWidget {
  const _LibraryTabHolder({super.key});

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

class _TempScreen extends StatelessWidget {
  const _TempScreen({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0F0F),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}