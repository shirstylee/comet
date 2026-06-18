import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/library_game_model.dart';
import '../../storage/backup_storage.dart';
import '../../storage/notification_storage.dart';
import '../main/main_screen.dart';

class ImportDataScreen extends StatefulWidget {
  const ImportDataScreen({
    super.key,
    this.openMainAfterImport = false,
  });

  final bool openMainAfterImport;

  @override
  State<ImportDataScreen> createState() => _ImportDataScreenState();
}

class _ImportDataScreenState extends State<ImportDataScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color headerBackground = Color(0xCC0C0F0F);
  static const Color surface = Color(0xFF111414);
  static const Color surfaceLight = Color(0xFF1D2020);
  static const Color accent = Color(0xFF75EEFD);
  static const Color accentDark = Color(0xFF00575F);
  static const Color success = Color(0xFF83E881);
  static const Color blue = Color(0xFF61ACFE);
  static const Color danger = Color(0xFFFF716C);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  BackupImportPreview? preview;
  bool isChecking = false;
  bool isImporting = false;
  double importProgress = 0;

  Timer? _progressTimer;

  bool get hasPreview => preview != null;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (isChecking || isImporting) return;

    _progressTimer?.cancel();

    setState(() {
      isChecking = true;
      importProgress = 0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Выберите архив Comet',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        _showMessage('Выбор файла отменён');
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());

      if (bytes == null) {
        _showMessage('Не удалось прочитать выбранный файл');
        return;
      }

      final loadedPreview = await BackupStorage.readImportPreview(
        fileName: file.name,
        bytes: bytes,
      );

      if (!mounted) return;

      setState(() {
        preview = loadedPreview;
        importProgress = 0;
      });

      _showMessage('Файл проверен и готов к импорту');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        preview = null;
        importProgress = 0;
      });

      _showMessage('Выбран неподходящий JSON-файл');
    } finally {
      if (!mounted) return;

      setState(() {
        isChecking = false;
      });
    }
  }

  Future<void> _showPreviewDialog() async {
    final currentPreview = preview;
    if (currentPreview == null) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.68),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.78,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: accent.withOpacity(0.20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: accent,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Предпросмотр импорта',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _PreviewSummaryCard(
                        preview: currentPreview,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Все игры из архива',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (currentPreview.games.isEmpty)
                        const _PreviewEmptyGames()
                      else
                        ...currentPreview.games.map((game) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PreviewGameCard(
                              game: game,
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                      const Text(
                        'При запуске импорта текущая библиотека будет полностью заменена данными из файла.',
                        style: TextStyle(
                          color: danger,
                          fontSize: 13,
                          height: 1.42,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF081F23),
                        side: const BorderSide(
                          color: Color(0x6632B8C6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Закрыть',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startImport() async {
    final currentPreview = preview;

    if (currentPreview == null || isImporting) {
      _showMessage('Сначала выберите JSON-файл');
      return;
    }

    final confirmed = await _showImportConfirmation();

    if (confirmed != true || !mounted) return;

    _progressTimer?.cancel();

    setState(() {
      isImporting = true;
      importProgress = 0;
    });

    _startProgressAnimation();

    try {
      await BackupStorage.importBackup(currentPreview);

      if (!mounted) return;

      _progressTimer?.cancel();

      setState(() {
        importProgress = 1;
      });

      await Future.delayed(const Duration(milliseconds: 450));

      if (!mounted) return;

      _showMessage('Данные успешно импортированы');

      if (widget.openMainAfterImport) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
              (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;

      _progressTimer?.cancel();

      setState(() {
        importProgress = 0;
      });

      await NotificationStorage.addImportFailedNotification();

      _showMessage('Не удалось импортировать данные');
    } finally {
      if (!mounted) return;

      setState(() {
        isImporting = false;
      });
    }
  }

  void _startProgressAnimation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (!mounted || !isImporting) {
        timer.cancel();
        return;
      }

      if (importProgress >= 0.92) {
        return;
      }

      setState(() {
        importProgress = (importProgress + 0.04).clamp(0.0, 0.92).toDouble();
      });
    });
  }

  Future<bool?> _showImportConfirmation() {
    final currentPreview = preview;

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.68),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: danger.withOpacity(0.28),
            ),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: danger,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Заменить данные?',
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
            'Текущая библиотека будет полностью заменена. Будет импортировано игр: ${currentPreview?.gamesCount ?? 0}.',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
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
                Icons.restore_rounded,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'Заменить',
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
  }

  void _removeSelectedFile() {
    _progressTimer?.cancel();

    setState(() {
      preview = null;
      importProgress = 0;
      isImporting = false;
    });

    _showMessage('Файл убран');
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

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 KB';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final progressText = '${(importProgress * 100).round()}%';

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 104, 24, 136),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _ImportDropZone(
                      isChecking: isChecking,
                      onTap: _pickFile,
                    ),
                    if (!hasPreview) ...[
                      const SizedBox(height: 34),
                      const Text(
                        'Восстановление\nархива',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.75,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Выберите ранее экспортированный файл JSON для восстановления вашей библиотеки, оценок и игрового прогресса.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 16,
                          height: 1.62,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 24),
                      _SelectedFileCard(
                        fileName: preview!.fileName,
                        fileSizeText: _formatSize(preview!.sizeBytes),
                        gamesCount: preview!.gamesCount,
                        ratedCount: preview!.ratedCount,
                        stagesCount: preview!.stagesCount,
                        profileIncluded: preview!.profileIncluded,
                        onRemove: isImporting ? null : _removeSelectedFile,
                      ),
                      const SizedBox(height: 24),
                      _PreviewButton(
                        onTap: isImporting ? null : _showPreviewDialog,
                      ),
                      const SizedBox(height: 24),
                      _ImportProgressIndicator(
                        value: importProgress,
                        percentText: progressText,
                        isImporting: isImporting,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const _ImportHeader(),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomActionArea(
                isEnabled: hasPreview && !isChecking,
                isImporting: isImporting,
                onTap: _startImport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportHeader extends StatelessWidget {
  const _ImportHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      color: _ImportDataScreenState.headerBackground,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 24,
            child: _ImportBackButton(),
          ),
          const Text(
            'Импорт данных',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ImportDataScreenState.textPrimary,
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

class _ImportBackButton extends StatelessWidget {
  const _ImportBackButton();

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
          color: _ImportDataScreenState.accent,
          size: 23,
        ),
      ),
    );
  }
}

class _ImportHeroIcon extends StatelessWidget {
  const _ImportHeroIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _ImportDataScreenState.accent.withOpacity(0.20),
                  blurRadius: 45,
                  spreadRadius: 12,
                ),
              ],
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF232626),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x26464848),
              ),
              boxShadow: [
                BoxShadow(
                  color: _ImportDataScreenState.accent.withOpacity(0.15),
                  blurRadius: 40,
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_sync_rounded,
              color: _ImportDataScreenState.accent,
              size: 44,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportDropZone extends StatelessWidget {
  const _ImportDropZone({
    required this.isChecking,
    required this.onTap,
  });

  final bool isChecking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isChecking ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          height: 184,
          decoration: BoxDecoration(
            color: _ImportDataScreenState.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x4D464848),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isChecking) ...[
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: _ImportDataScreenState.accent,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.upload_file_rounded,
                  color: _ImportDataScreenState.textSecondary,
                  size: 34,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                isChecking ? 'Проверка файла' : 'Выбрать файл',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ImportDataScreenState.textPrimary,
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Поддерживается формат .json',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ImportDataScreenState.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedFileCard extends StatelessWidget {
  const _SelectedFileCard({
    required this.fileName,
    required this.fileSizeText,
    required this.gamesCount,
    required this.ratedCount,
    required this.stagesCount,
    required this.profileIncluded,
    required this.onRemove,
  });

  final String fileName;
  final String fileSizeText;
  final int gamesCount;
  final int ratedCount;
  final int stagesCount;
  final bool profileIncluded;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
        boxShadow: [
          BoxShadow(
            color: _ImportDataScreenState.accent.withOpacity(0.08),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _FileSmallPill(
                icon: Icons.description_rounded,
                text: 'JSON',
              ),
              const SizedBox(width: 8),
              const _FileStatusPill(),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: onRemove == null
                      ? _ImportDataScreenState.textSecondary.withOpacity(0.35)
                      : _ImportDataScreenState.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ImportDataScreenState.textPrimary,
              fontSize: 18,
              height: 1.18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FileMetaPill(
                icon: Icons.storage_rounded,
                text: fileSizeText,
              ),
              _FileMetaPill(
                icon: Icons.sports_esports_rounded,
                text: 'Игры: $gamesCount',
              ),
              _FileMetaPill(
                icon: Icons.star_rounded,
                text: 'Оценки: $ratedCount',
              ),
              _FileMetaPill(
                icon: Icons.timeline_rounded,
                text: 'Этапы: $stagesCount',
              ),
              if (profileIncluded)
                const _FileMetaPill(
                  icon: Icons.person_outline_rounded,
                  text: 'Профиль',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FileSmallPill extends StatelessWidget {
  const _FileSmallPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10262B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _ImportDataScreenState.accent,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _ImportDataScreenState.accent,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileStatusPill extends StatelessWidget {
  const _FileStatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _ImportDataScreenState.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _ImportDataScreenState.success.withOpacity(0.35),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: _ImportDataScreenState.success,
            size: 14,
          ),
          SizedBox(width: 5),
          Text(
            'ПРОВЕРЕНО',
            style: TextStyle(
              color: _ImportDataScreenState.success,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FileMetaPill extends StatelessWidget {
  const _FileMetaPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10262B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0x5532B8C6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _ImportDataScreenState.textSecondary,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _ImportDataScreenState.textSecondary,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _ImportDataScreenState.accent.withOpacity(0.35),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_rounded,
                color: onTap == null
                    ? _ImportDataScreenState.accent.withOpacity(0.35)
                    : _ImportDataScreenState.accent,
                size: 25,
              ),
              const SizedBox(width: 12),
              Text(
                'ПРЕДПРОСМОТР',
                style: TextStyle(
                  color: onTap == null
                      ? _ImportDataScreenState.accent.withOpacity(0.35)
                      : _ImportDataScreenState.accent,
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
    );
  }
}

class _ImportProgressIndicator extends StatelessWidget {
  const _ImportProgressIndicator({
    required this.value,
    required this.percentText,
    required this.isImporting,
  });

  final double value;
  final String percentText;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isImporting ? 'ИМПОРТ ДАННЫХ' : 'ГОТОВ К ИМПОРТУ',
                  style: const TextStyle(
                    color: _ImportDataScreenState.accent,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                percentText,
                style: const TextStyle(
                  color: _ImportDataScreenState.accent,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safeValue,
              minHeight: 6,
              color: _ImportDataScreenState.accent,
              backgroundColor: const Color(0xFF232626),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionArea extends StatelessWidget {
  const _BottomActionArea({
    required this.isEnabled,
    required this.isImporting,
    required this.onTap,
  });

  final bool isEnabled;
  final bool isImporting;
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
            Color(0xF20C0F0F),
            Color(0xFF0C0F0F),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: isEnabled && !isImporting ? onTap : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isEnabled ? 1 : 0.42,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    _ImportDataScreenState.accent,
                    Color(0xFF25B0BE),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _ImportDataScreenState.accent.withOpacity(0.40),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isImporting) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _ImportDataScreenState.accentDark,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: _ImportDataScreenState.accentDark,
                      size: 25,
                    ),
                  ],
                  const SizedBox(width: 12),
                  Text(
                    isImporting ? 'ИМПОРТ ДАННЫХ' : 'ЗАПУСТИТЬ ИМПОРТ',
                    style: const TextStyle(
                      color: _ImportDataScreenState.accentDark,
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

class _PreviewSummaryCard extends StatelessWidget {
  const _PreviewSummaryCard({
    required this.preview,
  });

  final BackupImportPreview preview;

  String get profileText {
    if (!preview.profileIncluded) return 'нет';

    final name = preview.profile?.name.trim();

    if (name == null || name.isEmpty) {
      return 'Имя не указано';
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF081F23),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x6632B8C6),
        ),
      ),
      child: Column(
        children: [
          _PreviewLine(
            label: 'Файл',
            value: preview.fileName,
          ),
          _PreviewLine(
            label: 'Игры',
            value: preview.gamesCount.toString(),
          ),
          _PreviewLine(
            label: 'Оценки',
            value: preview.ratedCount.toString(),
          ),
          _PreviewLine(
            label: 'Этапы',
            value: preview.stagesCount.toString(),
          ),
          _PreviewLine(
            label: 'Профиль',
            value: profileText,
          ),
        ],
      ),
    );
  }
}

class _PreviewEmptyGames extends StatelessWidget {
  const _PreviewEmptyGames();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2020),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'В архиве нет игр.',
        style: TextStyle(
          color: _ImportDataScreenState.textSecondary,
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewGameCard extends StatelessWidget {
  const _PreviewGameCard({
    required this.game,
  });

  final LibraryGameModel game;

  String get ratingText {
    final rating = game.userRating;

    if (rating == null || rating <= 0) return 'без оценки';

    final rounded = double.parse(rating.toStringAsFixed(1));

    if (rounded == rounded.roundToDouble()) {
      return '${rounded.toInt()}/10';
    }

    return '${rounded.toStringAsFixed(1)}/10';
  }

  String get stagesText {
    final count = game.stages.length;

    if (count == 0) return '0 этапов';

    return '$count этапов';
  }

  String get timeText {
    if (game.userHours <= 0 && game.userMinutes <= 0) return '0ч.';
    if (game.userMinutes <= 0) return '${game.userHours}ч.';

    return '${game.userHours}ч. ${game.userMinutes}м.';
  }

  @override
  Widget build(BuildContext context) {
    final status = game.status.trim().isEmpty ? 'Без статуса' : game.status.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x2632B8C6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10262B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: _ImportDataScreenState.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ImportDataScreenState.textPrimary,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$status • $ratingText • $stagesText • $timeText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ImportDataScreenState.textSecondary,
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ImportDataScreenState.textSecondary,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ImportDataScreenState.textPrimary,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
