import 'package:flutter/material.dart';

import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color background = Color(0xFF0C0F0F);

  // Временное состояние главной страницы.
  // Позже данные будут загружаться из локального хранилища.
  final bool hasGames = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),

              const SizedBox(height: 32),

              // Блок краткой статистики пользователя.
              _StatsSection(hasGames: hasGames),

              const SizedBox(height: 32),

              // Фильтры для быстрого просмотра библиотеки.
              const _FilterChips(),

              const SizedBox(height: 32),

              // Последние действия пользователя в приложении.
              _RecentActivitySection(hasGames: hasGames),

              const SizedBox(height: 32),

              // Основная кнопка перехода к добавлению игры.
              _AddGameButton(
                onTap: () {
                  // TODO: Добавить переход на экран поиска или добавления игры.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

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

            // Кнопка перехода к поиску игр.
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(),
                  ),
                );
              },
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
    required this.hasGames,
  });

  final bool hasGames;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'ПРОЙДЕНО',
                value: hasGames ? '4' : '0',
                subtitle: 'игры',
                color: const Color(0xFFBBFFB3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'ИГРАЮ',
                value: hasGames ? '3' : '0',
                subtitle: 'активных',
                color: const Color(0xFF61ACFE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: 'СРЕДНЯЯ ОЦЕНКА',
          value: hasGames ? '4.7' : '-',
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
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  height: 1,
                  fontWeight: FontWeight.w900,
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

class _FilterChips extends StatefulWidget {
  const _FilterChips();

  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  int selectedIndex = 0;

  final List<String> filters = [
    'Все',
    'Пройдено',
    'Играю',
    'Планирую',
  ];

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
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
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
  });

  final bool hasGames;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionHeader(),
        const SizedBox(height: 24),
        if (hasGames)
          const Column(
            children: [
              _GameActivityCard(
                title: 'Elden Ring',
                subtitle: '2ч сессия\nсегодня',
                status: _GameCardStatus.playing,
                imageGradient: [
                  Color(0xFF1A322D),
                  Color(0xFFD7B95A),
                ],
              ),
              SizedBox(height: 16),
              _GameActivityCard(
                title: 'Cyberpunk\n2077',
                subtitle: '1ч сессия\nвчера',
                status: _GameCardStatus.playing,
                imageGradient: [
                  Color(0xFF1F0B2E),
                  Color(0xFFFF2BD6),
                ],
              ),
              SizedBox(height: 16),
              _GameActivityCard(
                title: "Baldur's\nGate 3",
                subtitle: 'ПРОЙДЕНО',
                status: _GameCardStatus.completed,
                imageGradient: [
                  Color(0xFF111F12),
                  Color(0xFF65724C),
                ],
              ),
            ],
          )
        else
          const _EmptyActivityState(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

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
          onPressed: () {},
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

enum _GameCardStatus {
  playing,
  completed,
}

class _GameActivityCard extends StatelessWidget {
  const _GameActivityCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.imageGradient,
  });

  final String title;
  final String subtitle;
  final _GameCardStatus status;
  final List<Color> imageGradient;

  @override
  Widget build(BuildContext context) {
    // От статуса зависит вид правой кнопки и подпись карточки.
    final bool completed = status == _GameCardStatus.completed;

    return Container(
      height: completed ? 112 : 116,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
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
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 18,
                    height: 1.22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle_rounded
                          : Icons.access_time_rounded,
                      color: completed
                          ? const Color(0xFFBBFFB3)
                          : const Color(0xFFAAABAB),
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: completed
                            ? const Color(0xFFBBFFB3)
                            : const Color(0xFFAAABAB),
                        fontSize: 14,
                        height: 1.3,
                        fontWeight:
                        completed ? FontWeight.w800 : FontWeight.w500,
                        letterSpacing: completed ? 1.2 : 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (completed)
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF232626),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Завершено',
                style: TextStyle(
                  color: Color(0xFFAAABAB),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF75EEFD),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF00575F),
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Играть',
                    style: TextStyle(
                      color: Color(0xFF00575F),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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