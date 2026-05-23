import 'package:flutter/material.dart';

import '../../game_progress/game_progress_screen.dart';
import '../library_screen.dart';

class LibraryGameCard extends StatelessWidget {
  const LibraryGameCard({
    super.key,
    required this.game,
  });

  final LibraryGame game;

  void _openProgressScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameProgressScreen(
          title: game.title,
          status: game.status,
          userHours: game.hours,
          userMinutes: 30,
          apiHours: _getApiHours(game.title),
          rating: game.rating,
        ),
      ),
    );
  }

  int _getApiHours(String title) {
    final normalizedTitle = title.toLowerCase();

    if (normalizedTitle.contains('elden')) return 80;
    if (normalizedTitle.contains('witcher')) return 120;
    if (normalizedTitle.contains('cyberpunk')) return 70;
    if (normalizedTitle.contains('red dead')) return 180;

    return 80;
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColors(game.status);

    return GestureDetector(
      onTap: () => _openProgressScreen(context),
      child: Container(
        height: 282,
        decoration: BoxDecoration(
          color: const Color(0xFF1D2020),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _CoverGradient(index: game.imageIndex),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF1D2020),
                            const Color(0xFF1D2020).withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 12,
                    child: Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: statusColors.background,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        game.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColors.text,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 90,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFF4F3F3),
                            fontSize: 20,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x801C1917),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFEAB308),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              game.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFFF4F3F3),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: Color(0xFF78716C),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.hours}Ч',
                        style: const TextStyle(
                          color: Color(0xFF78716C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: Color(0xFF78716C),
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.year}',
                        style: const TextStyle(
                          color: Color(0xFF78716C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusColors _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'пройдено':
        return _StatusColors(
          text: const Color(0xFFBBFFB3),
          background: const Color(0x33BBFFB3),
          border: const Color(0x4DBBFFB3),
        );
      case 'играю':
        return _StatusColors(
          text: const Color(0xFF61ACFE),
          background: const Color(0x3361ACFE),
          border: const Color(0x4D61ACFE),
        );
      default:
        return _StatusColors(
          text: const Color(0xFFA8A29E),
          background: const Color(0x3378716C),
          border: const Color(0x4D78716C),
        );
    }
  }
}

class _CoverGradient extends StatelessWidget {
  const _CoverGradient({
    required this.index,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    final gradients = [
      [
        const Color(0xFF0E1C1D),
        const Color(0xFF304A4D),
        const Color(0xFF111414),
      ],
      [
        const Color(0xFF131F22),
        const Color(0xFF143C45),
        const Color(0xFF1D2020),
      ],
      [
        const Color(0xFFE7E7E7),
        const Color(0xFF7F8585),
        const Color(0xFF1D2020),
      ],
      [
        const Color(0xFF1C160E),
        const Color(0xFF7B5131),
        const Color(0xFF111414),
      ],
    ];

    final colors = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white.withOpacity(0.12),
          size: 96,
        ),
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors({
    required this.text,
    required this.background,
    required this.border,
  });

  final Color text;
  final Color background;
  final Color border;
}