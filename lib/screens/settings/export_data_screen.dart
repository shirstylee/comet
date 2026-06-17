import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../storage/backup_storage.dart';
import '../../storage/library_storage.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color headerBackground = Color(0xCC0C0F0F);
  static const Color surface = Color(0xFF111414);
  static const Color surfaceLight = Color(0xFF1D2020);
  static const Color accent = Color(0xFF75EEFD);
  static const Color accentDark = Color(0xFF00575F);
  static const Color success = Color(0xFFBBFFB3);
  static const Color blue = Color(0xFF61ACFE);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  bool isLoading = true;
  bool isExporting = false;
  bool isExported = false;

  int gamesCount = 0;
  int ratedCount = 0;
  int stagesCount = 0;
  int estimatedBytes = 0;
  String fileName = BackupStorage.buildBackupFileName();

  @override
  void initState() {
    super.initState();
    _loadExportInfo();
  }

  Future<void> _loadExportInfo() async {
    final games = await LibraryStorage.getAllGames();
    final bytes = await BackupStorage.estimateExportSizeBytes(games);

    if (!mounted) return;

    setState(() {
      gamesCount = games.length;
      ratedCount = games.where((game) {
        return game.userRating != null && game.userRating! > 0;
      }).length;
      stagesCount = games.fold<int>(
        0,
            (sum, game) => sum + game.stages.length,
      );
      estimatedBytes = bytes;
      fileName = BackupStorage.buildBackupFileName();
      isLoading = false;
    });
  }

  String get estimatedSizeText {
    if (estimatedBytes <= 0) return '~0 KB';

    final kb = estimatedBytes / 1024;
    if (kb < 1024) {
      return '~${kb.ceil()} KB';
    }

    final mb = kb / 1024;
    return '~${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _startExport() async {
    if (isExporting) return;

    setState(() {
      isExporting = true;
      isExported = false;
    });

    try {
      final result = await BackupStorage.buildBackupExportData();

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить архив Comet',
        fileName: result.fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: result.bytes,
      );

      if (!mounted) return;

      if (savedPath == null) {
        _showMessage('Экспорт отменён');
        return;
      }

      setState(() {
        fileName = result.fileName;
        estimatedBytes = result.sizeBytes;
        isExported = true;
      });

      _showMessage(
        'Архив сохранён: ${result.fileName}',
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage('Не удалось сохранить архив');
    } finally {
      if (!mounted) return;

      setState(() {
        isExporting = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceLight,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 104, 24, 128),
                child: isLoading
                    ? const SizedBox(
                  height: 520,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: accent,
                    ),
                  ),
                )
                    : Column(
                  children: [
                    const _AmbientCircle(),
                    const SizedBox(height: 8),
                    _ExportHeroIcon(
                      isExported: isExported,
                    ),
                    const SizedBox(height: 42),
                    const Text(
                      'Создание архива',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Экспортируйте профиль, библиотеку, оценки и прогресс в JSON-файл для переноса на другое устройство или хранения резервной копии.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 16,
                        height: 1.62,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 52),
                    _ExportDetailsCard(
                      fileName: fileName,
                      estimatedSizeText: estimatedSizeText,
                      gamesCount: gamesCount,
                      ratedCount: ratedCount,
                      stagesCount: stagesCount,
                    ),
                  ],
                ),
              ),
            ),
            const _ExportHeader(),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomActionArea(
                isLoading: isLoading,
                isExporting: isExporting,
                onTap: _startExport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportHeader extends StatelessWidget {
  const _ExportHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      color: _ExportDataScreenState.headerBackground,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 24,
            child: _ExportBackButton(),
          ),
          const Text(
            'Экспорт данных',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ExportDataScreenState.textPrimary,
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

class _ExportBackButton extends StatelessWidget {
  const _ExportBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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
          color: _ExportDataScreenState.accent,
          size: 23,
        ),
      ),
    );
  }
}

class _AmbientCircle extends StatelessWidget {
  const _AmbientCircle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 280,
        height: 0,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _ExportDataScreenState.accent.withOpacity(0.18),
              blurRadius: 95,
              spreadRadius: 75,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportHeroIcon extends StatelessWidget {
  const _ExportHeroIcon({
    required this.isExported,
  });

  final bool isExported;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 138,
      height: 138,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _ExportDataScreenState.accent.withOpacity(0.22),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: _ExportDataScreenState.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ExportDataScreenState.accent.withOpacity(0.20),
                ),
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: _ExportDataScreenState.accent,
                size: 62,
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF232626),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ExportDataScreenState.background,
                  width: 2,
                ),
              ),
              child: Icon(
                isExported
                    ? Icons.check_circle_rounded
                    : Icons.check_rounded,
                color: _ExportDataScreenState.success,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportDetailsCard extends StatelessWidget {
  const _ExportDetailsCard({
    required this.fileName,
    required this.estimatedSizeText,
    required this.gamesCount,
    required this.ratedCount,
    required this.stagesCount,
  });

  final String fileName;
  final String estimatedSizeText;
  final int gamesCount;
  final int ratedCount;
  final int stagesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _ExportDataScreenState.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x26464848),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.50),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const _ExportCardHeader(),
          const SizedBox(height: 22),
          _ExportFileNameRow(
            fileName: fileName,
          ),
          const SizedBox(height: 16),
          _ExportInfoRow(
            icon: Icons.storage_rounded,
            title: 'Примерный размер',
            value: estimatedSizeText,
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                _ExportTag(
                  icon: Icons.sports_esports_rounded,
                  text: 'Игры ($gamesCount)',
                ),
                _ExportTag(
                  icon: Icons.star_border_rounded,
                  text: 'Оценки ($ratedCount)',
                ),
                _ExportTag(
                  icon: Icons.history_rounded,
                  text: 'Прогресс ($stagesCount)',
                ),
                const _ExportTag(
                  icon: Icons.person_outline_rounded,
                  text: 'Профиль',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportCardHeader extends StatelessWidget {
  const _ExportCardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0x33464848),
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.description_rounded,
            color: _ExportDataScreenState.blue,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ФАЙЛ ЭКСПОРТА',
              style: TextStyle(
                color: _ExportDataScreenState.textSecondary,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Text(
            'JSON',
            style: TextStyle(
              color: _ExportDataScreenState.accent,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportFileNameRow extends StatelessWidget {
  const _ExportFileNameRow({
    required this.fileName,
  });

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.folder_open_rounded,
          color: _ExportDataScreenState.textSecondary,
          size: 22,
        ),
        const SizedBox(width: 12),
        const SizedBox(
          width: 54,
          child: Text(
            'Имя\nфайла',
            style: TextStyle(
              color: _ExportDataScreenState.textPrimary,
              fontSize: 14,
              height: 1.28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _ExportDataScreenState.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0x26464848),
              ),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ExportDataScreenState.textSecondary,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportInfoRow extends StatelessWidget {
  const _ExportInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: _ExportDataScreenState.textSecondary,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ExportDataScreenState.textPrimary,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: _ExportDataScreenState.textSecondary,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ExportTag extends StatelessWidget {
  const _ExportTag({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF232626),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x4D464848),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _ExportDataScreenState.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _ExportDataScreenState.textSecondary,
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionArea extends StatelessWidget {
  const _BottomActionArea({
    required this.isLoading,
    required this.isExporting,
    required this.onTap,
  });

  final bool isLoading;
  final bool isExporting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x000C0F0F),
            Color(0xFF0C0F0F),
            Color(0xFF0C0F0F),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: isLoading || isExporting ? null : onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isLoading ? 0.45 : 1,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    _ExportDataScreenState.accent,
                    Color(0xFF25B0BE),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _ExportDataScreenState.accent.withOpacity(0.40),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isExporting) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _ExportDataScreenState.accentDark,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: _ExportDataScreenState.accentDark,
                      size: 25,
                    ),
                  ],
                  const SizedBox(width: 12),
                  Text(
                    isExporting ? 'СОЗДАНИЕ АРХИВА' : 'ЗАПУСТИТЬ ЭКСПОРТ',
                    style: const TextStyle(
                      color: _ExportDataScreenState.accentDark,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
