import 'package:flutter/material.dart';

class GameStatCard extends StatelessWidget {
  const GameStatCard({
    super.key,
    required this.title,
    required this.value,
    this.valueColor = const Color(0xFFF4F3F3),
    this.onTap,
    this.compactValue = false,
  });

  final String title;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1D2020),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 116,
          padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 22,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFAAABAB),
                      fontSize: 15,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      maxLines: compactValue ? 1 : 2,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: compactValue ? 17 : 18,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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