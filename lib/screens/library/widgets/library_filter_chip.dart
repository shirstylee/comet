import 'package:flutter/material.dart';

class LibraryFilterChip extends StatelessWidget {
  const LibraryFilterChip({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isSelected
        ? const Color(0xFF081F23)
        : const Color(0xFF1D2020);

    final Color borderColor = isSelected
        ? const Color(0x6632B8C6)
        : const Color(0x1AFFFFFF);

    final Color textColor = isSelected
        ? const Color(0xFF75EEFD)
        : const Color(0xFFAAABAB);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: borderColor,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
