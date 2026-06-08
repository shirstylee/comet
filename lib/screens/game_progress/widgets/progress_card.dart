import 'package:flutter/material.dart';

class GameProgressCard extends StatelessWidget {
  const GameProgressCard({
    super.key,
    required this.title,
    required this.statusText,
    required this.statusColor,
  });

  final String title;
  final String statusText;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final cleanTitle = title.trim().isEmpty ? 'Начало игры' : title.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF75EEFD).withOpacity(0.06),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ТЕКУЩИЙ ЭТАП',
                  style: TextStyle(
                    color: Color(0xFFAAABAB),
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              _StageStatusBadge(
                text: statusText,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            cleanTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF75EEFD),
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageStatusBadge extends StatelessWidget {
  const _StageStatusBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}