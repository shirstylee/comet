import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const Color background = Color(0xFF0C0F0F);
  static const Color headerBackground = Color(0xCC0C0F0F);
  static const Color surface = Color(0xFF1D2020);
  static const Color darkSurface = Color(0xFF111414);
  static const Color border = Color(0xFF232626);
  static const Color accent = Color(0xFF75EEFD);
  static const Color accentDark = Color(0xFF25B0BE);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _AboutHeader(
              title: 'О приложении',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
                children: const [
                  _BrandingSection(),
                  SizedBox(height: 48),
                  _ConceptCard(),
                  SizedBox(height: 36),
                  _InfoCardsSection(),
                  SizedBox(height: 36),
                  _TechnologySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      color: AboutAppScreen.headerBackground,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 24,
            child: _AboutBackButton(
              onTap: onBack,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AboutAppScreen.textPrimary,
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutBackButton extends StatelessWidget {
  const _AboutBackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x1A75EEFD),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0x6675EEFD),
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AboutAppScreen.accent,
          size: 23,
        ),
      ),
    );
  }
}

class _BrandingSection extends StatelessWidget {
  const _BrandingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            color: AboutAppScreen.darkSurface,
            shape: BoxShape.circle,
            border: Border.all(
              color: AboutAppScreen.border,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2675EEFD),
                blurRadius: 60,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipOval(
            child: Transform.scale(
              scale: 1.12,
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) {
                  return const ColoredBox(
                    color: AboutAppScreen.darkSurface,
                    child: Center(
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: AboutAppScreen.accent,
                        size: 76,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                AboutAppScreen.accent,
                AboutAppScreen.accentDark,
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'Comet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -2.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ВЕРСИЯ 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AboutAppScreen.textSecondary,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _ConceptCard extends StatelessWidget {
  const _ConceptCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A75EEFD),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 50,
            offset: Offset(0, 25),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AboutAppScreen.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0x1A464848),
          ),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              color: AboutAppScreen.textPrimary,
              fontSize: 18,
              height: 1.62,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'Comet',
                style: TextStyle(
                  color: AboutAppScreen.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.45,
                ),
              ),
              TextSpan(
                text:
                ' — это персональный игровой трекер для удобного управления личной библиотекой видеоигр. Приложение помогает находить игры через RAWG API, сохранять их локально, отслеживать прогресс, ставить оценки и вести собственный журнал прохождения.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCardsSection extends StatelessWidget {
  const _InfoCardsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _AboutInfoCard(
          icon: Icons.storage_rounded,
          title: 'Локальное хранение',
          text:
          'Библиотека, оценки, статусы, этапы прохождения и уведомления сохраняются на устройстве через Hive.',
        ),
        SizedBox(height: 12),
        _AboutInfoCard(
          icon: Icons.public_rounded,
          title: 'RAWG API',
          text:
          'Поиск игр и основная справочная информация загружаются из внешнего игрового сервиса.',
        ),
        SizedBox(height: 12),
        _AboutInfoCard(
          icon: Icons.notifications_active_outlined,
          title: 'Системные уведомления',
          text:
          'Comet сообщает о добавлении игр, изменении оценок, этапах прохождения и завершённых играх.',
        ),
      ],
    );
  }
}

class _AboutInfoCard extends StatelessWidget {
  const _AboutInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AboutAppScreen.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x1F464848),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x1A75EEFD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AboutAppScreen.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AboutAppScreen.textPrimary,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AboutAppScreen.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
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

class _TechnologySection extends StatelessWidget {
  const _TechnologySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'ТЕХНОЛОГИИ',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AboutAppScreen.textSecondary,
            fontSize: 12,
            height: 1.33,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final double chipWidth = (constraints.maxWidth - 14) / 2;

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: const [
                _TechChip(
                  icon: Icons.code_rounded,
                  title: 'Flutter / Dart',
                ),
                _TechChip(
                  icon: Icons.storage_rounded,
                  title: 'Hive DB',
                ),
                _TechChip(
                  icon: Icons.api_rounded,
                  title: 'RAWG API',
                ),
                _TechChip(
                  icon: Icons.android_rounded,
                  title: 'Android',
                ),
              ].map((chip) {
                return SizedBox(
                  width: chipWidth,
                  child: chip,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TechChip extends StatelessWidget {
  const _TechChip({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AboutAppScreen.border,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x6675EEFD),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A75EEFD),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AboutAppScreen.accent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  color: AboutAppScreen.textPrimary,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
