import 'package:flutter/gestures.dart';
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

class _GridMenuButton extends StatefulWidget {
  const _GridMenuButton({
    required this.isFavorite,
    required this.onSelected,
  });

  final bool isFavorite;
  final ValueChanged<String> onSelected;

  @override
  State<_GridMenuButton> createState() => _GridMenuButtonState();
}

class _GridMenuController {
  static _GridMenuButtonState? _activeMenu;

  static void open(_GridMenuButtonState menu) {
    if (_activeMenu == menu) return;

    _activeMenu?._hideMenu();
    _activeMenu = menu;
  }

  static void close(_GridMenuButtonState menu) {
    if (_activeMenu == menu) {
      _activeMenu = null;
    }
  }
}

class _GridMenuButtonState extends State<_GridMenuButton> {
  static const double _menuWidth = 220;
  static const double _menuHeight = 110;
  static const double _screenEdgePadding = 12;
  static const double _menuVerticalOffset = 7;

  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _menuEntry;
  double _menuDx = 0;
  Rect? _menuRect;
  Rect? _buttonRect;
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
    _GridMenuController.open(this);

    final buttonBox = context.findRenderObject() as RenderBox?;
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (buttonBox != null && overlayBox != null) {
      final buttonOverlayPosition = buttonBox.localToGlobal(
        Offset.zero,
        ancestor: overlayBox,
      );
      final buttonGlobalPosition = buttonBox.localToGlobal(Offset.zero);
      final overlayGlobalPosition = overlayBox.localToGlobal(Offset.zero);

      final screenWidth = overlayBox.size.width;
      final minX = _screenEdgePadding;
      final maxX = screenWidth - _menuWidth - _screenEdgePadding;
      final safeMaxX = maxX < minX ? minX : maxX;
      final menuX = buttonOverlayPosition.dx.clamp(minX, safeMaxX).toDouble();
      final menuY =
          buttonOverlayPosition.dy + buttonBox.size.height + _menuVerticalOffset;

      _menuDx = menuX - buttonOverlayPosition.dx;
      _buttonRect = Rect.fromLTWH(
        buttonGlobalPosition.dx,
        buttonGlobalPosition.dy,
        buttonBox.size.width,
        buttonBox.size.height,
      );
      _menuRect = Rect.fromLTWH(
        overlayGlobalPosition.dx + menuX,
        overlayGlobalPosition.dy + menuY,
        _menuWidth,
        _menuHeight,
      );
    } else {
      _menuDx = 0;
      _buttonRect = null;
      _menuRect = null;
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
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: Offset(_menuDx, _menuVerticalOffset),
                child: _GridFloatingMenu(
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
    _menuDx = 0;
    _menuRect = null;
    _buttonRect = null;
    _pointerDownPosition = null;
    _trackedPointer = null;
    _removeGlobalPointerRoute();
    _GridMenuController.close(this);

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
      final menuRect = _menuRect;
      final buttonRect = _buttonRect;
      final isInsideMenu = menuRect?.contains(event.position) ?? false;
      final isInsideButton = buttonRect?.contains(event.position) ?? false;

      if (!isInsideMenu && !isInsideButton) {
        _hideMenu();
        return;
      }

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
  void didUpdateWidget(covariant _GridMenuButton oldWidget) {
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
          width: 30,
          height: 30,
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
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _GridFloatingMenu extends StatelessWidget {
  const _GridFloatingMenu({
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
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _GridMenuActionTile(
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
              const SizedBox(height: 6),
              _GridMenuActionTile(
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 19,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: color,
                  fontSize: 13.2,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
