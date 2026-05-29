import 'package:flutter/material.dart';

import '../../models/game_model.dart';
import '../../models/game_stage_model.dart';
import '../../models/library_game_model.dart';
import '../../storage/library_storage.dart';

class GameDetailsScreen extends StatefulWidget {
  const GameDetailsScreen({
    super.key,
    required this.game,
  });

  final GameModel game;

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  static const Color background = Color(0xFF0C0F0F);

  bool isDescriptionExpanded = false;

  Future<void> _addGameToLibrary() async {
    final alreadyAdded = await LibraryStorage.containsGame(widget.game.id);

    if (!mounted) return;

    if (alreadyAdded) {
      _showMessage('${widget.game.title} уже есть в коллекции');
      return;
    }

    final libraryGame = LibraryGameModel(
      id: widget.game.id,
      title: widget.game.title,
      status: 'Планирую',
      addedAt: DateTime.now(),
      year: widget.game.year,
      apiRating: widget.game.rating,
      apiHours: widget.game.hours,
      userHours: 0,
      userMinutes: 0,
      userRating: null,
      comment: null,
      isFavorite: false,
      stages: const [
        GameStageModel(
          title: 'Начало игры',
          subtitle: 'В процессе',
          isDone: false,
        ),
      ],
    );

    await LibraryStorage.addGame(libraryGame);

    if (!mounted) return;

    _showMessage('${widget.game.title} добавлена в коллекцию');
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

  void _showTrailerUnavailable() {
    _showMessage('Трейлер будет доступен после подключения API');
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _HeroSection(game: game),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PrimaryButton(
                        text: 'Добавить в коллекцию',
                        icon: Icons.add_rounded,
                        onTap: _addGameToLibrary,
                      ),
                      const SizedBox(height: 32),
                      _TrailerButton(
                        onTap: _showTrailerUnavailable,
                      ),
                      const SizedBox(height: 32),
                      _RatingSection(game: game),
                      const SizedBox(height: 32),
                      _MetaCards(game: game),
                      const SizedBox(height: 32),
                      _AboutSection(
                        isExpanded: isDescriptionExpanded,
                        onToggle: () {
                          setState(() {
                            isDescriptionExpanded = !isDescriptionExpanded;
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      const _ScreenshotsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _TopHeader(title: game.title),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.game,
  });

  final GameModel game;

  static const Color background = Color(0xFF0C0F0F);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 115),
        child: SizedBox(
          height: 320,
          child: Stack(
            children: [
              Positioned.fill(
                child: _HeroBackground(
                  title: game.title,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        background.withOpacity(0.05),
                        background.withOpacity(0.4),
                        background,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 16,
                right: 16,
                bottom: 4,
                child: _GenreBadges(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final bool witcher = title.toLowerCase().contains('witcher');

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: witcher
              ? const [
            Color(0xFF122026),
            Color(0xFF1B2B2E),
            Color(0xFF071010),
          ]
              : const [
            Color(0xFF172026),
            Color(0xFF263A3A),
            Color(0xFF071010),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -40,
            right: -40,
            top: 70,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _ForestPainter(),
            ),
          ),
          Positioned(
            top: 0,
            left: 150,
            child: Container(
              width: 90,
              height: 190,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mountainPaint = Paint()
      ..color = const Color(0xFF152225).withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final treePaint = Paint()
      ..color = const Color(0xFF071010).withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final mountainPath = Path()
      ..moveTo(0, size.height * 0.65)
      ..lineTo(size.width * 0.18, size.height * 0.35)
      ..lineTo(size.width * 0.34, size.height * 0.58)
      ..lineTo(size.width * 0.52, size.height * 0.28)
      ..lineTo(size.width * 0.76, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.38)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(mountainPath, mountainPaint);

    for (double x = 0; x < size.width; x += 14) {
      final treeHeight = 40 + (x % 42);
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + 7, size.height - treeHeight)
        ..lineTo(x + 14, size.height)
        ..close();

      canvas.drawPath(path, treePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GenreBadges extends StatelessWidget {
  const _GenreBadges();

  @override
  Widget build(BuildContext context) {
    final badges = ['RPG', 'ACTION', 'CD PROJEKT RED', '17+'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: badges.map((badge) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF232626),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                badge,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: const Color(0x990C0F0F),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x80232626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFFF4F3F3),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 54),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF75EEFD),
              Color(0xFF25B0BE),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF75EEFD).withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(
            icon,
            color: const Color(0xFF00575F),
            size: 24,
          ),
          label: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF00575F),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailerButton extends StatelessWidget {
  const _TrailerButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.play_circle_outline_rounded,
          color: Color(0xFFF4F3F3),
          size: 25,
        ),
        label: const Text(
          'Трейлер',
          style: TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({
    required this.game,
  });

  final GameModel game;

  String get ratingLabel {
    if (game.rating >= 9.2) return 'Исключительно';
    if (game.rating >= 8.0) return 'Отлично';
    if (game.rating >= 7.0) return 'Хорошо';
    return 'Средне';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: ratingLabel),
                const TextSpan(text: '  🎯'),
              ],
            ),
            style: const TextStyle(
              color: Color(0xFFF4F3F3),
              fontSize: 24,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '7,321 оценок',
            style: TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 26),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const Row(
              children: [
                Expanded(
                  flex: 75,
                  child: ColoredBox(
                    color: Color(0xFFBBFFB3),
                    child: SizedBox(height: 8),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: ColoredBox(
                    color: Color(0xFF61ACFE),
                    child: SizedBox(height: 8),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: ColoredBox(
                    color: Color(0xFF25B0BE),
                    child: SizedBox(height: 8),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ColoredBox(
                    color: Color(0xFFFF716C),
                    child: SizedBox(height: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallBadge(text: '#1 RPG'),
              _SmallBadge(text: '#1 TOP 2015'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaCards extends StatelessWidget {
  const _MetaCards({
    required this.game,
  });

  final GameModel game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const _MetaCard(
            title: 'METASCORE',
            value: '92',
            icon: null,
            highlighted: true,
          ),
          const SizedBox(width: 8),
          const _MetaCard(
            title: 'РЕЛИЗ',
            value: 'May 18, 2015',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 8),
          _MetaCard(
            title: 'ВРЕМЯ ИГРЫ',
            value: '${game.hours} hrs',
            icon: Icons.access_time_rounded,
          ),
          const SizedBox(width: 8),
          const _MetaCard(
            title: 'ПЛАТФОРМЫ',
            value: 'PC, PS, Xbox',
            icon: Icons.sports_esports_rounded,
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({
    required this.title,
    required this.value,
    required this.icon,
    this.highlighted = false,
    this.wide = false,
  });

  final String title;
  final String value;
  final IconData? icon;
  final bool highlighted;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? 130 : 115,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF232626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          if (highlighted)
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFBBFFB3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFBBFFB3),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else ...[
            if (icon != null)
              Icon(
                icon,
                color: const Color(0xFFF4F3F3),
                size: 22,
              ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 13,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.isExpanded,
    required this.onToggle,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  static const String description =
      'The Witcher 3: Wild Hunt is a story-driven, next-generation open world role-playing game set in a visually stunning fantasy universe full of meaningful choices and impactful consequences.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Об игре',
          style: TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF111414),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.03),
            ),
          ),
          child: Text(
            description,
            maxLines: isExpanded ? null : 4,
            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onToggle,
          child: Row(
            children: [
              Text(
                isExpanded ? 'СВЕРНУТЬ' : 'РАСКРЫТЬ',
                style: const TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF75EEFD),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScreenshotsSection extends StatelessWidget {
  const _ScreenshotsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Скриншоты',
          style: TextStyle(
            color: Color(0xFFF4F3F3),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF172026),
                      index.isEven
                          ? const Color(0xFFD28F4E)
                          : const Color(0xFF25B0BE),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF232626),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFAAABAB),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}