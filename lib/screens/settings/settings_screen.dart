import 'package:flutter/material.dart';

import '../../storage/library_storage.dart';
import 'about_app_screen.dart';
import 'settings_statistics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color background = Color(0xFF0C0F0F);
  static const Color headerBackground = Color(0xCC0C0F0F);
  static const Color surface = Color(0xFF1D2020);
  static const Color accent = Color(0xFF75EEFD);
  static const Color danger = Color(0xFFFF716C);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _showDeleteAllGamesDialog(BuildContext context) async {
    final games = await LibraryStorage.getAllGames();

    if (!context.mounted) return;

    if (games.isEmpty) {
      _showMessage(context, 'В библиотеке пока нет игр');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111414),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: danger,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Удалить все игры?',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Из библиотеки будет удалено игр: ${games.length}. Оценки, комментарии и этапы прохождения этих игр также будут удалены.',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF081F23),
                  side: const BorderSide(
                    color: Color(0x6632B8C6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Удалить',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != true || !context.mounted) return;

    await LibraryStorage.clearLibrary();

    if (!context.mounted) return;

    _showMessage(context, 'Все игры удалены из библиотеки');
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111414),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: danger,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Сбросить данные?',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Это действие позже можно подключить к очистке библиотеки, профиля и уведомлений. Сейчас экран настроек подготовлен под эту функцию.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF081F23),
                  side: const BorderSide(
                    color: Color(0x6632B8C6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text(
                  'Отмена',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Понятно',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != true || !context.mounted) return;

    _showMessage(context, 'Сброс данных пока не подключён');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(
              title: 'Настройки',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SettingsSectionTitle(
                      title: 'Управление данными',
                    ),
                    const SizedBox(height: 16),
                    _SettingsActionTile(
                      icon: Icons.file_download_outlined,
                      title: 'Импорт данных',
                      onTap: () => _showMessage(
                        context,
                        'Импорт JSON можно подключить следующим шагом',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SettingsActionTile(
                      icon: Icons.file_upload_outlined,
                      title: 'Экспорт данных',
                      onTap: () => _showMessage(
                        context,
                        'Экспорт библиотеки в JSON можно подключить следующим шагом',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SettingsActionTile(
                      icon: Icons.delete_sweep_outlined,
                      iconColor: danger,
                      title: 'Удалить все игры',
                      onTap: () => _showDeleteAllGamesDialog(context),
                    ),
                    const SizedBox(height: 10),
                    _SettingsActionTile(
                      icon: Icons.error_outline_rounded,
                      iconColor: danger,
                      title: 'Сбросить данные',
                      onTap: () => _showResetDialog(context),
                    ),
                    const SizedBox(height: 32),
                    const _SettingsSectionTitle(
                      title: 'Прочее',
                    ),
                    const SizedBox(height: 16),
                    _SettingsActionTile(
                      icon: Icons.info_outline_rounded,
                      title: 'О приложении',
                      height: 72,
                      iconSize: 21,
                      iconBoxSize: 38,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutAppScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _SettingsActionTile(
                      icon: Icons.query_stats_rounded,
                      title: 'Статистика',
                      height: 72,
                      iconSize: 21,
                      iconBoxSize: 38,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsStatisticsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
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
      color: SettingsScreen.headerBackground,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 24,
            child: _SettingsBackButton(
              onTap: onBack,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SettingsScreen.textPrimary,
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

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({
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
          color: SettingsScreen.accent,
          size: 23,
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: SettingsScreen.accent,
        fontSize: 18,
        height: 1.55,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = SettingsScreen.accent,
    this.height = 68,
    this.iconSize = 20,
    this.iconBoxSize = 36,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final double height;
  final double iconSize;
  final double iconBoxSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: SettingsScreen.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: iconBoxSize,
                height: iconBoxSize,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SettingsScreen.textPrimary,
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: SettingsScreen.textSecondary,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
