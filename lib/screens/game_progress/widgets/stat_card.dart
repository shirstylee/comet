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

  bool get _hasRatingStar {
    return compactValue && value.trim().endsWith('★');
  }

  String get _ratingValue {
    return value.replaceAll('★', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF081F23),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 116,
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF081F23),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x6632B8C6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF75EEFD).withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF10262B),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0x5532B8C6),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF75EEFD),
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _hasRatingStar
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _ratingValue,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            color: valueColor,
                            fontSize: 18,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.translate(
                          offset: const Offset(0, -2.5),
                          child: Text(
                            '★',
                            style: TextStyle(
                              color: valueColor,
                              fontSize: 14,
                              height: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    )
                        : Text(
                      value,
                      textAlign: TextAlign.center,
                      maxLines: compactValue ? 1 : 2,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: compactValue ? 18 : 26,
                        height: compactValue ? 1.15 : 1.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: compactValue ? 0 : -0.4,
                      ),
                    ),
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF75EEFD),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
