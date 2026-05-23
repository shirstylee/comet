import 'package:flutter/material.dart';

import 'widgets/action_card.dart';
import 'widgets/progress_card.dart';
import 'widgets/stat_card.dart';
import 'widgets/timeline_item.dart';

class GameProgressScreen extends StatefulWidget {
  const GameProgressScreen({
    super.key,
    required this.title,
    this.status = 'Играю',
    this.userHours = 42,
    this.userMinutes = 30,
    this.apiHours = 80,
    this.rating = 4.8,
  });

  final String title;
  final String status;
  final int userHours;
  final int userMinutes;
  final int apiHours;
  final double rating;

  @override
  State<GameProgressScreen> createState() => _GameProgressScreenState();
}

class _GameProgressScreenState extends State<GameProgressScreen> {
  static const Color background = Color(0xFF0C0F0F);
  static const Color accent = Color(0xFF75EEFD);
  static const Color textPrimary = Color(0xFFF4F3F3);
  static const Color textSecondary = Color(0xFFAAABAB);

  bool isFavorite = true;

  late int userHours = widget.userHours;
  late int userMinutes = widget.userMinutes;

  late List<_GameStage> stages = [
    _GameStage(
      title: 'Начало игры',
      subtitle: 'В процессе',
      type: TimelineItemType.current,
    ),
  ];

  double get progressValue {
    final played = userHours + userMinutes / 60;
    final calculated = played / widget.apiHours;

    if (calculated > 1) return 1;
    if (calculated < 0) return 0;

    return calculated;
  }

  int get progressPercent => (progressValue * 100).round();

  String get playedTimeText {
    return '$userHours ч.\n$userMinutes мин.';
  }

  int get lastStageIndex => stages.length - 1;

  String get todayText {
    final now = DateTime.now();

    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'мая',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];

    return '${now.day} ${months[now.month - 1]}, ${now.year}';
  }

  void _showTemporaryMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1A1D1D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _openTimeEditor() {
    final hoursController = TextEditingController(text: userHours.toString());
    final minutesController =
    TextEditingController(text: userMinutes.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF111414),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.16),
                  blurRadius: 34,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Изменить время',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Укажите, сколько вы уже играли',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeInputField(
                          controller: hoursController,
                          label: 'Часы',
                          suffix: 'ч.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeInputField(
                          controller: minutesController,
                          label: 'Минуты',
                          suffix: 'мин.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF75EEFD),
                            Color(0xFF25B0BE),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final newHours =
                              int.tryParse(hoursController.text.trim()) ?? 0;
                          final newMinutes =
                              int.tryParse(minutesController.text.trim()) ?? 0;

                          setState(() {
                            userHours = newHours;
                            userMinutes = newMinutes.clamp(0, 59);
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Сохранить',
                          style: TextStyle(
                            color: Color(0xFF00575F),
                            fontSize: 17,
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
      },
    );
  }

  void _openStageActions(int index) {
    final stage = stages[index];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111414),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.16),
                  blurRadius: 34,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textSecondary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    stage.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _StageMenuItem(
                    icon: Icons.edit_rounded,
                    title: 'Переименовать',
                    subtitle: 'Изменить название этапа',
                    onTap: () {
                      Navigator.pop(context);
                      _showTemporaryMessage(
                        'Переименование будет добавлено позже',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _StageMenuItem(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Завершить',
                    subtitle: 'Отметить этап как пройденный',
                    onTap: () {
                      setState(() {
                        stages[index] = stage.copyWith(
                          type: TimelineItemType.done,
                          subtitle: todayText,
                        );
                      });

                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _StageMenuItem(
                    icon: Icons.delete_outline_rounded,
                    title: 'Удалить',
                    subtitle: 'Убрать этап из истории',
                    danger: true,
                    onTap: () {
                      if (stages.length <= 1) {
                        Navigator.pop(context);
                        return;
                      }

                      setState(() {
                        stages.removeAt(index);

                        final newLastIndex = stages.length - 1;

                        if (stages[newLastIndex].type ==
                            TimelineItemType.done) {
                          stages[newLastIndex] = stages[newLastIndex].copyWith(
                            type: TimelineItemType.current,
                            subtitle: 'В процессе',
                          );
                        }
                      });

                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addStage() {
    setState(() {
      stages[lastStageIndex] = stages.last.copyWith(
        type: TimelineItemType.done,
        subtitle: todayText,
      );

      stages.add(
        const _GameStage(
          title: 'Новый этап',
          subtitle: 'В процессе',
          type: TimelineItemType.current,
        ),
      );
    });

    _showTemporaryMessage('Новый этап добавлен');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 96, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GameHeroImage(),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GenreBadge(text: 'ACTION RPG'),
                    SizedBox(width: 12),
                    _GenreBadge(text: 'OPEN WORLD'),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GameStatCard(
                        title: 'Статус',
                        value: widget.status,
                        valueColor: accent,
                        compactValue: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GameStatCard(
                        title: 'Время',
                        value: playedTimeText,
                        onTap: _openTimeEditor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GameStatCard(
                        title: 'Оценка',
                        value: '${widget.rating.toStringAsFixed(1)} ★',
                        valueColor: const Color(0xFFBBFFB3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GameProgressCard(
                  progress: progressValue,
                  percent: progressPercent,
                ),
                const SizedBox(height: 48),
                const Text(
                  'История прохождения',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 32),
                for (int i = 0; i < stages.length; i++)
                  TimelineItem(
                    title: stages[i].title,
                    subtitle: stages[i].subtitle,
                    type: stages[i].type,
                    isLast: i == stages.length - 1,
                    onTap: () => _openStageActions(i),
                  ),
                const SizedBox(height: 4),
                _AddStageButton(onTap: _addStage),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GameActionCard(
                        icon: Icons.star_rate_rounded,
                        title: 'Оставить оценку',
                        subtitle: 'Оценить игру',
                        onTap: () {
                          _showTemporaryMessage('Оценка будет добавлена позже');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GameActionCard(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Закончить',
                        subtitle: 'Завершить прохождение',
                        onTap: () {
                          _showTemporaryMessage(
                            'Завершение прохождения будет добавлено позже',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _TopBar(
            title: widget.title,
            isFavorite: isFavorite,
            onFavoriteTap: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _TimeInputField extends StatelessWidget {
  const _TimeInputField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2020),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        cursorColor: const Color(0xFF75EEFD),
        style: const TextStyle(
          color: Color(0xFFF4F3F3),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: InputBorder.none,
          labelStyle: const TextStyle(
            color: Color(0xFFAAABAB),
            fontSize: 13,
          ),
          suffixStyle: const TextStyle(
            color: Color(0xFF75EEFD),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StageMenuItem extends StatelessWidget {
  const _StageMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF716C) : const Color(0xFF75EEFD);

    return Material(
      color: const Color(0xFF1D2020),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? color : const Color(0xFFF4F3F3),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameStage {
  const _GameStage({
    required this.title,
    required this.subtitle,
    required this.type,
  });

  final String title;
  final String subtitle;
  final TimelineItemType type;

  _GameStage copyWith({
    String? title,
    String? subtitle,
    TimelineItemType? type,
  }) {
    return _GameStage(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
    );
  }
}

class _AddStageButton extends StatelessWidget {
  const _AddStageButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1A75EEFD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF75EEFD),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF75EEFD).withOpacity(0.18),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF75EEFD),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Добавить этап прохождения',
                  style: TextStyle(
                    color: Color(0xFF75EEFD),
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final String title;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: const Color(0xCC0C0F0F),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF75EEFD),
                size: 28,
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            GestureDetector(
              onTap: onFavoriteTap,
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: const Color(0xFF75EEFD),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHeroImage extends StatelessWidget {
  const _GameHeroImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 358,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF162323),
            Color(0xFF39432C),
            Color(0xFF0C0F0F),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white.withOpacity(0.18),
          size: 120,
        ),
      ),
    );
  }
}

class _GenreBadge extends StatelessWidget {
  const _GenreBadge({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2020),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF4F3F3),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}