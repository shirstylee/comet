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

  Color get mainColor {
    if (isDone) return const Color(0xFFBBFFB3);
    if (isCurrent) return const Color(0xFF75EEFD);

    return const Color(0xFF464848);
  }

  Color get cardColor {
    if (isDone) return const Color(0xFF102417);
    if (isLocked) return const Color(0xFF111414);

    return const Color(0xFF081F23);
  }

  Color get borderColor {
    if (isDone) return const Color(0x99BBFFB3);
    if (isLocked) return const Color(0x1A464848);

    return const Color(0x6632B8C6);
  }

  Color get titleColor {
    if (isLocked) return const Color(0xFF747675);

    return const Color(0xFFF4F3F3);
  }

  String get statusText {
    if (isDone) return 'ЗАВЕРШЕНО';
    if (isCurrent) return 'В ПРОЦЕССЕ';

    return 'ЗАКРЫТО';
  }

  IconData get statusIcon {
    if (isDone) return Icons.check_circle_rounded;
    if (isCurrent) return Icons.radio_button_checked_rounded;

    return Icons.lock_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
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
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0x6637D67A)
                            : const Color(0xFF232626),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withOpacity(
                            isLocked
                                ? 0.02
                                : isDone
                                ? 0.18
                                : 0.08,
                          ),
                          blurRadius: isDone ? 26 : 18,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _StageSmallPill(
                              text: 'ЭТАП',
                              color: mainColor,
                              isDone: isDone,
                              isLocked: isLocked,
                            ),
                            const Spacer(),
                            if (onTap != null)
                              Icon(
                                Icons.more_horiz_rounded,
                                color: isLocked
                                    ? const Color(0xFF747675)
                                    : mainColor,
                                size: 22,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 19,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Flexible(
                              child: _StageStatusPill(
                                icon: statusIcon,
                                text: statusText,
                                color: mainColor,
                                isLocked: isLocked,
                              ),
                            ),
                            if (subtitle.trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: _StageDatePill(
                                  text: subtitle,
                                  isDone: isDone,
                                  isLocked: isLocked,
                                ),
                              ),
                            ],
                          ],
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

class _StageSmallPill extends StatelessWidget {
  const _StageSmallPill({
    required this.text,
    required this.color,
    required this.isDone,
    required this.isLocked,
  });

  final String text;
  final Color color;
  final bool isDone;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isLocked
            ? const Color(0xFF1D2020)
            : isDone
            ? const Color(0x2237D67A)
            : const Color(0xFF10262B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLocked
              ? const Color(0x1A464848)
              : isDone
              ? const Color(0x66BBFFB3)
              : const Color(0x5532B8C6),
          width: 0.8,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: isLocked ? const Color(0xFF747675) : color,
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StageStatusPill extends StatelessWidget {
  const _StageStatusPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.isLocked,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final Color currentColor = isLocked ? const Color(0xFF747675) : color;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: currentColor.withOpacity(isLocked ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: currentColor.withOpacity(isLocked ? 0.18 : 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: currentColor,
            size: 15,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: currentColor,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageDatePill extends StatelessWidget {
  const _StageDatePill({
    required this.text,
    required this.isDone,
    required this.isLocked,
  });

  final String text;
  final bool isDone;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isLocked
            ? const Color(0xFF10262B).withOpacity(0.35)
            : isDone
            ? const Color(0x2237D67A)
            : const Color(0xFF10262B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLocked
              ? const Color(0x5532B8C6).withOpacity(0.35)
              : isDone
              ? const Color(0x55BBFFB3)
              : const Color(0x5532B8C6),
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: isLocked
                ? const Color(0xFF747675)
                : isDone
                ? const Color(0xFFD8FFD3)
                : const Color(0xFFAAABAB),
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
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
