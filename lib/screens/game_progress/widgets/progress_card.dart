import 'package:flutter/material.dart';

class GameProgressCard extends StatelessWidget {
  const GameProgressCard({
    super.key,
    required this.progress,
    required this.percent,
  });

  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF75EEFD).withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Мой прогресс',
                  style: TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 16,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: const Color(0xFF232626),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF75EEFD),
                          Color(0xFF25B0BE),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}