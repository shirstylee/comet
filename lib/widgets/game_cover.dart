import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class GameCover extends StatefulWidget {
  const GameCover({
    super.key,
    required this.width,
    required this.height,
    this.localImagePath,
    this.imageUrl,
    this.borderRadius = 12,
    this.iconSize = 32,
    this.fit = BoxFit.cover,
    this.showGradient = true,
    this.gradientOpacity = 0.22,
  });

  final double width;
  final double height;
  final String? localImagePath;
  final String? imageUrl;
  final double borderRadius;
  final double iconSize;
  final BoxFit fit;
  final bool showGradient;
  final double gradientOpacity;

  @override
  State<GameCover> createState() => _GameCoverState();
}

class _GameCoverState extends State<GameCover> {
  static const Duration _networkRetryDelay = Duration(seconds: 4);

  Timer? networkRetryTimer;
  int networkRetryVersion = 0;

  bool get _hasLocalImage {
    final path = widget.localImagePath;

    if (path == null || path.trim().isEmpty) {
      return false;
    }

    return File(path).existsSync();
  }

  bool get _hasNetworkImage {
    final url = widget.imageUrl;

    return url != null && url.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant GameCover oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.localImagePath != widget.localImagePath) {
      networkRetryTimer?.cancel();
      networkRetryTimer = null;
      networkRetryVersion = 0;
    }
  }

  @override
  void dispose() {
    networkRetryTimer?.cancel();
    super.dispose();
  }

  void _scheduleNetworkRetry() {
    if (networkRetryTimer != null || !_hasNetworkImage) {
      return;
    }

    networkRetryTimer = Timer(_networkRetryDelay, () async {
      networkRetryTimer = null;

      if (!mounted || !_hasNetworkImage) {
        return;
      }

      await NetworkImage(widget.imageUrl!).evict();

      if (!mounted) {
        return;
      }

      setState(() {
        networkRetryVersion++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCover(),
            if (widget.showGradient)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF0C0F0F).withOpacity(0.75),
                        const Color(0xFF0C0F0F).withOpacity(
                          widget.gradientOpacity,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (_hasLocalImage) {
      return Image.file(
        File(widget.localImagePath!),
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkOrFallback();
        },
      );
    }

    return _buildNetworkOrFallback();
  }

  Widget _buildNetworkOrFallback() {
    if (!_hasNetworkImage) {
      return _GameCoverFallback(iconSize: widget.iconSize);
    }

    return Image.network(
      widget.imageUrl!,
      key: ValueKey('${widget.imageUrl}-$networkRetryVersion'),
      fit: widget.fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _GameCoverFallback(
          iconSize: widget.iconSize,
          showLoader: true,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _scheduleNetworkRetry();
        return _GameCoverFallback(iconSize: widget.iconSize);
      },
    );
  }
}

class _GameCoverFallback extends StatelessWidget {
  const _GameCoverFallback({
    required this.iconSize,
    this.showLoader = false,
  });

  final double iconSize;
  final bool showLoader;

  @override
  Widget build(BuildContext context) {
    if (showLoader) {
      return const ColoredBox(
        color: Color(0xFF172026),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF75EEFD),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF172026),
            Color(0xFF263A3A),
            Color(0xFF111414),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white54,
          size: iconSize,
        ),
      ),
    );
  }
}
