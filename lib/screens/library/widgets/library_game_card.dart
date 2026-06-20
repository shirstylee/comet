import 'package:flutter/material.dart';

import '../../../models/library_game_model.dart';
import '../../../storage/library_storage.dart';
import '../../../widgets/game_cover.dart';
import '../../game_progress/game_progress_screen.dart';

Color _ratingScaleColor(double rating) {
  if (rating <= 0) return const Color(0xFF78716C);
  if (rating >= 8) return const Color(0xFF75EEFD);
  if (rating >= 6) return const Color(0xFFFACC15);
  if (rating >= 4) return const Color(0xFFF97316);

  return const Color(0xFFEF4444);
}

class LibraryGameCard extends StatefulWidget {
  const LibraryGameCard({
    super.key,
    required this.game,
    required this.imageIndex,
    required this.onDelete,
    required this.onGameChanged,
  });

  final LibraryGameModel game;
  final int imageIndex;
  final VoidCallback onDelete;
  final VoidCallback onGameChanged;

  @override
  State<LibraryGameCard> createState() => _LibraryGameCardState();
}

class _LibraryGameCardState extends State<LibraryGameCard> {
  late LibraryGameModel currentGame;

  @override
  void initState() {
    super.initState();

    currentGame = widget.game;
  }

  @override
  void didUpdateWidget(covariant LibraryGameCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.game.id != widget.game.id) {
      currentGame = widget.game;
    }
  }

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

    widget.onGameChanged();
  }

  void _handleMenuAction(String value) {
    if (value == 'delete') {
      widget.onDelete();
    }
  }

  String get playedTimeText {
    if (currentGame.userHours <= 0 && currentGame.userMinutes <= 0) {
      return '0ч.';
    }

    final parts = <String>[];

    if (currentGame.userHours > 0) {
      parts.add('${currentGame.userHours}ч.');
    }

    if (currentGame.userMinutes > 0) {
      parts.add('${currentGame.userMinutes}м.');
    }

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColors(currentGame.status);
    final ratingValue = currentGame.userRating ?? 0;
    final ratingColor = _ratingScaleColor(ratingValue);
    final String ratingText = currentGame.userRating == null
        ? '-'
        : currentGame.userRating!.round().clamp(1, 10).toString();

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
                    child: GameCover(
                      width: double.infinity,
                      height: double.infinity,
                      localImagePath: currentGame.localImagePath,
                      imageUrl: currentGame.imageUrl,
                      borderRadius: 0,
                      iconSize: 96,
                      gradientOpacity: 0.0,
                    ),
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
                  if (currentGame.isFavorite)
                    Positioned(
                      left: 16,
                      bottom: 14,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0x99111414),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0x4475EEFD),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF75EEFD).withOpacity(0.14),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFF75EEFD),
                          size: 19,
                        ),
                      ),
                    ),
                  Positioned(
                    right: 10,
                    top: 8,
                    child: _CardMenuButton(
                      onSelected: _handleMenuAction,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 96,
              padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
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
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        decoration: BoxDecoration(
                          color: ratingColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: ratingColor.withOpacity(0.34),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ratingColor.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: ratingColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ratingText,
                              style: TextStyle(
                                color: ratingColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Flexible(
                        child: _LibraryInfoPill(
                          icon: Icons.access_time_rounded,
                          text: playedTimeText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _LibraryInfoPill(
                          icon: Icons.calendar_month_rounded,
                          text: '${currentGame.year ?? '—'}',
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
          text: const Color(0xFF00671A),
          background: const Color(0xFFBBFFB3),
          border: const Color(0xFFBBFFB3),
        );
      case 'играю':
        return _StatusColors(
          text: const Color(0xFF00272B),
          background: const Color(0xFF61ACFE),
          border: const Color(0xFF61ACFE),
        );
      case 'планирую':
        return _StatusColors(
          text: const Color(0xFF00272B),
          background: const Color(0xFF75EEFD),
          border: const Color(0xFF75EEFD),
        );
      default:
        return _StatusColors(
          text: const Color(0xFF00272B),
          background: const Color(0xFF75EEFD),
          border: const Color(0xFF75EEFD),
        );
    }
  }
}

class _LibraryInfoPill extends StatelessWidget {
  const _LibraryInfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF75EEFD),
            size: 14,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMenuButton extends StatelessWidget {
  const _CardMenuButton({
    required this.onSelected,
  });

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF1D2020),
      elevation: 12,
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0x1AFFFFFF),
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFF7A7A),
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Удалить из библиотеки',
                  style: TextStyle(
                    color: Color(0xFFFF7A7A),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0x99111414),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: Color(0xFFF4F3F3),
          size: 22,
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
