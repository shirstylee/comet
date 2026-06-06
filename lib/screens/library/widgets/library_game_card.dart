import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/library_game_model.dart';
import '../../../storage/library_storage.dart';
import '../../game_progress/game_progress_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColors(currentGame.status);
    final rating =
    (currentGame.userRating ?? currentGame.apiRating ?? 0).round();

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
                    child: _LibraryCover(
                      game: currentGame,
                      imageIndex: widget.imageIndex,
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
                              '$rating',
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

class _LibraryCover extends StatelessWidget {
  const _LibraryCover({
    required this.game,
    required this.imageIndex,
  });

  final LibraryGameModel game;
  final int imageIndex;

  bool get _hasLocalImage {
    final path = game.localImagePath;

    if (path == null || path.trim().isEmpty) {
      return false;
    }

    return File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasLocalImage) {
      return Image.file(
        File(game.localImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _NetworkOrGradientCover(
            game: game,
            imageIndex: imageIndex,
          );
        },
      );
    }

    return _NetworkOrGradientCover(
      game: game,
      imageIndex: imageIndex,
    );
  }
}

class _NetworkOrGradientCover extends StatelessWidget {
  const _NetworkOrGradientCover({
    required this.game,
    required this.imageIndex,
  });

  final LibraryGameModel game;
  final int imageIndex;

  bool get _hasNetworkImage {
    final url = game.imageUrl;

    return url != null && url.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasNetworkImage) {
      return _CoverGradient(index: imageIndex);
    }

    return Image.network(
      game.imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _CoverGradient(index: imageIndex);
      },
      errorBuilder: (context, error, stackTrace) {
        return _CoverGradient(index: imageIndex);
      },
    );
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