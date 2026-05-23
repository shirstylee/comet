import 'package:flutter/material.dart';

enum TimelineItemType {
  done,
  current,
  locked,
}

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    this.onTap,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final TimelineItemType type;
  final VoidCallback? onTap;
  final bool isLast;

  bool get isDone => type == TimelineItemType.done;
  bool get isCurrent => type == TimelineItemType.current;
  bool get isLocked => type == TimelineItemType.locked;

  @override
  Widget build(BuildContext context) {
    final Color mainColor = isDone
        ? const Color(0xFFBBFFB3)
        : isCurrent
        ? const Color(0xFF75EEFD)
        : const Color(0xFF464848);

    final Color titleColor = isCurrent
        ? const Color(0xFF75EEFD)
        : isLocked
        ? const Color(0xFF747675)
        : const Color(0xFFF4F3F3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                _TimelineDot(
                  type: type,
                  color: mainColor,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFF232626),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Material(
                color:
                isCurrent ? const Color(0x4D232626) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: isCurrent
                        ? const EdgeInsets.fromLTRB(16, 12, 16, 12)
                        : EdgeInsets.zero,
                    decoration: isCurrent
                        ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.04),
                      ),
                    )
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 18,
                            height: 1.35,
                            fontWeight:
                            isLocked ? FontWeight.w500 : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isLocked
                                ? const Color(0xFF747675)
                                : const Color(0xFFAAABAB),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.type,
    required this.color,
  });

  final TimelineItemType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (type == TimelineItemType.done) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
            ),
          ],
        ),
        child: Icon(
          Icons.check_rounded,
          color: color,
          size: 16,
        ),
      );
    }

    if (type == TimelineItemType.current) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0x3361ACFE),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F0F),
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
    );
  }
}