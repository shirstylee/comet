import 'package:flutter/material.dart';

import '../../../models/library_game_model.dart';
import '../../../storage/library_storage.dart';
import '../../../widgets/game_cover.dart';
import '../../game_progress/game_progress_screen.dart';

Color _gridRatingScaleColor(double rating) {
  if (rating <= 0) return const Color(0xFF78716C);
  if (rating >= 8) return const Color(0xFF75EEFD);
  if (rating >= 6) return const Color(0xFFFACC15);
  if (rating >= 4) return const Color(0xFFF97316);

  return const Color(0xFFEF4444);
}

class LibraryGridGameCard extends StatefulWidget {
  const LibraryGridGameCard({
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
  State<LibraryGridGameCard> createState() => _LibraryGridGameCardState();
}

class _LibraryGridGameCardState extends State<LibraryGridGameCard> {
  late LibraryGameModel currentGame;

  @override
  void initState() {
    super.initState();

    currentGame = widget.game;
  }

  @override
  void didUpdateWidget(covariant LibraryGridGameCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.game.id != widget.game.id) {
      currentGame = widget.game;
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

  Future<void> _toggleFavorite() async {
    final updatedGame = currentGame.copyWith(
      isFavorite: !currentGame.isFavorite,
    );

    await LibraryStorage.updateGame(updatedGame);

    if (!mounted) return;

    setState(() {
      currentGame = updatedGame;
    });

    widget.onGameChanged();
  }

  void _handleMenuAction(String value) {
    if (value == 'favorite') {
      _toggleFavorite();
      return;
    }

    if (value == 'delete') {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColors(currentGame.status);
    final ratingValue = currentGame.userRating ?? 0;
    final ratingColor = _gridRatingScaleColor(ratingValue);
    final ratingText = currentGame.userRating == null
        ? '-'
        : currentGame.userRating!.round().clamp(1, 10).toString();

    return GestureDetector(
      onTap: () => _openProgressScreen(context),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1D2020),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x0FFFFFFF),
          ),
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
                      iconSize: 46,
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
                            const Color(0xFF1D2020).withOpacity(0.94),
                            const Color(0xFF1D2020).withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.55],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 9,
                    top: 9,
                    child: _GridStatusPill(
                      text: currentGame.status.toUpperCase(),
                      colors: statusColors,
                    ),
                  ),
                  if (currentGame.isFavorite)
                    const Positioned(
                      left: 10,
                      bottom: 10,
                      child: _GridFavoriteBadge(),
                    ),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: _GridMenuButton(
                      isFavorite: currentGame.isFavorite,
                      onSelected: _handleMenuAction,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 92,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentGame.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFF4F3F3),
                      fontSize: 14,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _GridRatingBadge(
                        text: ratingText,
                        color: ratingColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _GridInfoPill(
                          icon: Icons.access_time_rounded,
                          text: playedTimeText,
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

  _GridStatusColors _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'пройдено':
        return _GridStatusColors(
          text: const Color(0xFF00671A),
          background: const Color(0xFFBBFFB3),
          border: const Color(0xFFBBFFB3),
        );
      case 'играю':
        return _GridStatusColors(
          text: const Color(0xFF00272B),
          background: const Color(0xFF61ACFE),
          border: const Color(0xFF61ACFE),
        );
      case 'планирую':
        return _GridStatusColors(
          text: const Color(0xFF00272B),
          background: const Color(0xFF75EEFD),
          border: const Color(0xFF75EEFD),
        );
      default:
        return _GridStatusColors(
          text: const Color(0xFF00272B),
          background: const Color(0xFF75EEFD),
          border: const Color(0xFF75EEFD),
        );
    }
  }
}

class _GridStatusPill extends StatelessWidget {
  const _GridStatusPill({
    required this.text,
    required this.colors,
  });

  final String text;
  final _GridStatusColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      constraints: const BoxConstraints(
        maxWidth: 92,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.border,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.text,
          fontSize: 9,
          height: 1.1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.65,
        ),
      ),
    );
  }
}

class _GridRatingBadge extends StatelessWidget {
  const _GridRatingBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: color.withOpacity(0.34),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            maxLines: 1,
            style: TextStyle(
              color: color,
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridInfoPill extends StatelessWidget {
  const _GridInfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF75EEFD),
            size: 12,
          ),
          const SizedBox(width: 4),
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
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridFavoriteBadge extends StatelessWidget {
  const _GridFavoriteBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0x99111414),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0x4475EEFD),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF75EEFD).withOpacity(0.12),
            blurRadius: 14,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: Color(0xFF75EEFD),
        size: 16,
      ),
    );
  }
}

class _GridMenuButton extends StatelessWidget {
  const _GridMenuButton({
    required this.isFavorite,
    required this.onSelected,
  });

  final bool isFavorite;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF111414),
      elevation: 14,
      offset: const Offset(0, 32),
      constraints: const BoxConstraints(
        minWidth: 220,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0x2932B8C6),
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          PopupMenuItem<String>(
            value: 'favorite',
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: _GridMenuActionTile(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              title: isFavorite
                  ? 'Убрать из избранного'
                  : 'Добавить в избранное',
              color: const Color(0xFF75EEFD),
              backgroundColor: const Color(0xFF081F23),
              borderColor: const Color(0x5532B8C6),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            padding: EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: _GridMenuActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Удалить из библиотеки',
              color: Color(0xFFFF7A7A),
              backgroundColor: Color(0xFF251818),
              borderColor: Color(0x55FF7A7A),
            ),
          ),
        ];
      },
      child: Container(
        width: 30,
        height: 30,
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
          size: 20,
        ),
      ),
    );
  }
}

class _GridMenuActionTile extends StatelessWidget {
  const _GridMenuActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridStatusColors {
  const _GridStatusColors({
    required this.text,
    required this.background,
    required this.border,
  });

  final Color text;
  final Color background;
  final Color border;
}
