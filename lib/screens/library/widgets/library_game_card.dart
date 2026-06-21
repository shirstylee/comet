import 'package:flutter/gestures.dart';
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
                      isFavorite: currentGame.isFavorite,
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

class _CardMenuButton extends StatefulWidget {
  const _CardMenuButton({
    required this.isFavorite,
    required this.onSelected,
  });

  final bool isFavorite;
  final ValueChanged<String> onSelected;

  @override
  State<_CardMenuButton> createState() => _CardMenuButtonState();
}

class _CardMenuController {
  static _CardMenuButtonState? _activeMenu;

  static void open(_CardMenuButtonState menu) {
    if (_activeMenu == menu) return;

    _activeMenu?._hideMenu();
    _activeMenu = menu;
  }

  static void close(_CardMenuButtonState menu) {
    if (_activeMenu == menu) {
      _activeMenu = null;
    }
  }
}

class _CardMenuButtonState extends State<_CardMenuButton> {
  static const double _menuWidth = 210;
  static const double _screenEdgePadding = 12;

  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _menuEntry;
  bool _openToLeft = true;
  Offset? _pointerDownPosition;
  int? _trackedPointer;
  bool _isPointerRouteAdded = false;

  bool get _isMenuOpen => _menuEntry != null;

  void _toggleMenu() {
    if (_isMenuOpen) {
      _hideMenu();
      return;
    }

    _showMenu();
  }

  void _showMenu() {
    _CardMenuController.open(this);

    final buttonBox = context.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (buttonBox != null && overlayBox != null) {
      final buttonPosition = buttonBox.localToGlobal(
        Offset.zero,
        ancestor: overlayBox,
      );

      final screenWidth = overlayBox.size.width;
      final buttonRight = buttonPosition.dx + buttonBox.size.width;
      final hasSpaceOnRight = buttonPosition.dx + _menuWidth <=
          screenWidth - _screenEdgePadding;
      final hasSpaceOnLeft = buttonRight - _menuWidth >= _screenEdgePadding;

      _openToLeft = hasSpaceOnLeft && !hasSpaceOnRight;
    }

    final overlay = Overlay.of(context);

    _menuEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: _openToLeft
                    ? Alignment.bottomRight
                    : Alignment.bottomLeft,
                followerAnchor: _openToLeft
                    ? Alignment.topRight
                    : Alignment.topLeft,
                offset: const Offset(0, 7),
                child: _CardFloatingMenu(
                  isFavorite: widget.isFavorite,
                  onSelected: _handleSelected,
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_menuEntry!);
    _addGlobalPointerRoute();

    if (mounted) {
      setState(() {});
    }
  }

  void _hideMenu({bool updateState = true}) {
    _menuEntry?.remove();
    _menuEntry = null;
    _pointerDownPosition = null;
    _trackedPointer = null;
    _removeGlobalPointerRoute();
    _CardMenuController.close(this);

    if (updateState && mounted) {
      setState(() {});
    }
  }

  void _addGlobalPointerRoute() {
    if (_isPointerRouteAdded) return;

    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _handleGlobalPointerEvent,
    );
    _isPointerRouteAdded = true;
  }

  void _removeGlobalPointerRoute() {
    if (!_isPointerRouteAdded) return;

    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointerEvent,
    );
    _isPointerRouteAdded = false;
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (!_isMenuOpen) return;

    if (event is PointerDownEvent) {
      _trackedPointer = event.pointer;
      _pointerDownPosition = event.position;
      return;
    }

    if (event is PointerMoveEvent && event.pointer == _trackedPointer) {
      final startPosition = _pointerDownPosition;

      if (startPosition == null) return;

      final distance = (event.position - startPosition).distance;

      if (distance >= 7) {
        _hideMenu();
      }

      return;
    }

    if ((event is PointerUpEvent || event is PointerCancelEvent) &&
        event.pointer == _trackedPointer) {
      _trackedPointer = null;
      _pointerDownPosition = null;
    }
  }

  void _handleSelected(String value) {
    _hideMenu();
    widget.onSelected(value);
  }

  @override
  void didUpdateWidget(covariant _CardMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isFavorite != widget.isFavorite) {
      _menuEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _hideMenu(updateState: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _isMenuOpen
        ? const Color(0x6675EEFD)
        : Colors.white.withOpacity(0.08);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0x99111414),
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: const Icon(
            Icons.more_horiz_rounded,
            color: Color(0xFFF4F3F3),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _CardFloatingMenu extends StatelessWidget {
  const _CardFloatingMenu({
    required this.isFavorite,
    required this.onSelected,
  });

  final bool isFavorite;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF111414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x2932B8C6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFF75EEFD).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardMenuActionTile(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              title: isFavorite
                  ? 'Убрать из избранного'
                  : 'Добавить в избранное',
              color: const Color(0xFF75EEFD),
              backgroundColor: const Color(0xFF081F23),
              borderColor: const Color(0x5532B8C6),
              onTap: () => onSelected('favorite'),
            ),
            const SizedBox(height: 5),
            _CardMenuActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Удалить из библиотеки',
              color: const Color(0xFFFF7A7A),
              backgroundColor: const Color(0xFF251818),
              borderColor: const Color(0x55FF7A7A),
              onTap: () => onSelected('delete'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMenuActionTile extends StatelessWidget {
  const _CardMenuActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 198,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
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
