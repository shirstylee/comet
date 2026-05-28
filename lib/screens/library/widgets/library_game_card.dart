import 'package:flutter/material.dart';

import '../../../models/library_game_model.dart';
import '../../../storage/library_storage.dart';
import '../../game_progress/game_progress_screen.dart';

class LibraryGameCard extends StatefulWidget {
  const LibraryGameCard({
    super.key,
    required this.game,
    required this.imageIndex,
  });

  final LibraryGameModel game;
  final int imageIndex;

  @override
  State<LibraryGameCard> createState() => _LibraryGameCardState();
}

class _LibraryGameCardState extends State<LibraryGameCard> {
  late LibraryGameModel currentGame = widget.game;

  Future<void> _openProgressScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameProgressScreen(
          gameId: currentGame.id,
          title: currentGame.title,
          status: currentGame.status,
          userHours: currentGame.userHours,
          userMinutes: currentGame.userMinutes,
          apiHours: currentGame.apiHours,
          rating: currentGame.userRating ?? currentGame.apiRating ?? 0,
        ),
      ),
    );

    final updatedGame = await LibraryStorage.getGameById(currentGame.id);

    if (!mounted || updatedGame == null) return;

    setState(() {
      currentGame = updatedGame;
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColors(currentGame.status);
    final rating = currentGame.userRating ?? currentGame.apiRating ?? 0;

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
                    child: _CoverGradient(index: widget.imageIndex),
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
                        currentGame.status.toUpperCase(),
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
                          currentGame.title,
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
                              rating.toStringAsFixed(1),
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
                        '${currentGame.userHours}Ч',
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
                        '${currentGame.year ?? '—'}',
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
      case 'планирую':
        return _StatusColors(
          text: const Color(0xFFA8A29E),
          background: const Color(0x3378716C),
          border: const Color(0x4D78716C),
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