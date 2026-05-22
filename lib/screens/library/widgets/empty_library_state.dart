import 'package:flutter/material.dart';

class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 406,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
      decoration: BoxDecoration(
        color: const Color(0x4D111414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF75EEFD).withOpacity(0.08),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF75EEFD).withOpacity(0.18),
                  blurRadius: 70,
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x3375EEFD),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF75EEFD).withOpacity(0.12),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Color(0xFF75EEFD),
                  size: 56,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ваша библиотека пуста',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 24,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Используйте поиск, чтобы найти\nлюбимые видеоигры и начать\nтрекинг',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAAABAB),
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 180,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF75EEFD),
                        Color(0xFF25B0BE),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF75EEFD).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'НАЙТИ ИГРЫ',
                      style: TextStyle(
                        color: Color(0xFF00575F),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}