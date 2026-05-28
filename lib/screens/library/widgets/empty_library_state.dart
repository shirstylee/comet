import 'package:flutter/material.dart';

import '../../search/search_screen.dart';

class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key});

  static const Color accent = Color(0xFF75EEFD);
  static const Color accentDark = Color(0xFF25B0BE);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  void _openSearch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 430,
      ),
      padding: const EdgeInsets.fromLTRB(18, 34, 18, 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111A1A),
            Color(0xFF0D1212),
            Color(0xFF080B0B),
          ],
        ),
        border: Border.all(
          color: Color(0x1A75EEFD),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: accent.withOpacity(0.07),
            blurRadius: 46,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 22,
            right: 34,
            child: _GlowDot(size: 5, opacity: 0.45),
          ),
          const Positioned(
            top: 88,
            left: 28,
            child: _GlowDot(size: 4, opacity: 0.35),
          ),
          const Positioned(
            bottom: 96,
            right: 44,
            child: _GlowDot(size: 6, opacity: 0.28),
          ),
          Positioned(
            top: 34,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.045),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.12),
                    blurRadius: 80,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withOpacity(0.20),
                      accent.withOpacity(0.07),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: accent.withOpacity(0.24),
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: accent.withOpacity(0.10),
                      border: Border.all(
                        color: accent.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.16),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: accent,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                'Библиотека пуста',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Найдите первую игру и добавьте\nеё в свою коллекцию Comet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 16,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MiniFeatureChip(
                    icon: Icons.bookmark_rounded,
                    text: 'Статус',
                  ),
                  _MiniFeatureChip(
                    icon: Icons.star_rounded,
                    text: 'Оценки',
                  ),
                  _MiniFeatureChip(
                    icon: Icons.timeline_rounded,
                    text: 'Прогресс',
                  ),
                ],
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: 218,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent,
                        accentDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.24),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _openSearch(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF004C55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'НАЙТИ ИГРЫ',
                      style: TextStyle(
                        color: Color(0xFF004C55),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
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

class _MiniFeatureChip extends StatelessWidget {
  const _MiniFeatureChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2020).withOpacity(0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x1A75EEFD),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF75EEFD),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFAAABAB),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF75EEFD).withOpacity(opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(opacity),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}