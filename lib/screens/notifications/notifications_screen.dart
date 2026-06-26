import 'package:flutter/material.dart';

import '../../models/app_notification_model.dart';
import '../../storage/library_storage.dart';
import '../../storage/notification_change_notifier.dart';
import '../../storage/notification_storage.dart';
import '../game_progress/game_progress_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color background = Color(0xFF0C0F0F);

  List<AppNotificationModel> notifications = [];

  @override
  void initState() {
    super.initState();

    _loadNotifications();
    NotificationChangeNotifier.version.addListener(_onNotificationsChanged);
  }

  void _onNotificationsChanged() {
    if (!mounted) return;

    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final loadedNotifications = await NotificationStorage.getAllNotifications();

      if (!mounted) return;

      setState(() {
        notifications = loadedNotifications;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        notifications = [];
      });
    }
  }

  Future<void> _deleteNotification(AppNotificationModel notification) async {
    await NotificationStorage.deleteNotification(notification.id);
  }

  Future<void> _clearNotifications() async {
    if (notifications.isEmpty) return;

    final shouldClear = await _showClearNotificationsDialog();

    if (!shouldClear) return;

    await NotificationStorage.clearNotifications();

    if (!mounted) return;

    _showMessage('Уведомления очищены');
  }

  Future<bool> _showClearNotificationsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: const BorderSide(
              color: Color(0x5532B8C6),
              width: 1.2,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0x1AFF716C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x99FF716C),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF716C).withOpacity(0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFFF716C),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Очистить уведомления?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Все уведомления будут удалены из центра уведомлений. Это действие нельзя отменить.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAAABAB),
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF081F23),
                          side: const BorderSide(
                            color: Color(0x6632B8C6),
                            width: 1.1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            color: Color(0xFF75EEFD),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5484D),
                          shadowColor: const Color(0xFFFF716C).withOpacity(0.24),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Очистить',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
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
      },
    );

    return result ?? false;
  }

  Future<void> _openNotificationGame(AppNotificationModel notification) async {
    final gameId = notification.gameId;

    if (gameId == null) {
      _showMessage('У этого уведомления нет привязанной игры');
      return;
    }

    final savedGame = await LibraryStorage.getGameById(gameId);

    if (!mounted) return;

    if (savedGame == null) {
      _showMessage('Игра уже удалена из библиотеки');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameProgressScreen(
          gameId: savedGame.id,
          title: savedGame.title,
          status: savedGame.status,
          userHours: savedGame.userHours,
          userMinutes: savedGame.userMinutes,
          apiHours: savedGame.apiHours,
          rating: savedGame.userRating ?? savedGame.apiRating ?? 0,
        ),
      ),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
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

  @override
  void dispose() {
    NotificationChangeNotifier.version.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNotifications = notifications.isNotEmpty;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _NotificationsHeader(
              showClearButton: hasNotifications,
              onBack: () => Navigator.pop(context),
              onClear: _clearNotifications,
            ),
            Expanded(
              child: hasNotifications
                  ? _NotificationsList(
                notifications: notifications,
                onDelete: _deleteNotification,
                onOpenGame: _openNotificationGame,
              )
                  : const _EmptyNotificationsState(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.showClearButton,
    required this.onBack,
    required this.onClear,
  });

  final bool showClearButton;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC0C0F0F),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 24,
                  child: GestureDetector(
                    onTap: onBack,
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
                        color: Color(0xFF75EEFD),
                        size: 23,
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Уведомления',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          if (showClearButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Центр событий',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFAAABAB),
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ClearAllNotificationsButton(
                    onTap: onClear,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ClearAllNotificationsButton extends StatelessWidget {
  const _ClearAllNotificationsButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: const Color(0x2275EEFD),
        highlightColor: const Color(0x1275EEFD),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF081F23),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0x6632B8C6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF75EEFD).withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_sweep_rounded,
                color: Color(0xFF75EEFD),
                size: 16,
              ),
              SizedBox(width: 7),
              Text(
                'Очистить всё',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: Color(0xFF75EEFD),
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EmptyRadarIcon extends StatelessWidget {
  const _EmptyRadarIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF75EEFD).withOpacity(0.08),
              ),
            ),
          ),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF081F23),
              border: Border.all(
                color: const Color(0x6675EEFD),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF75EEFD).withOpacity(0.16),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF12343A),
                  Color(0xFF071010),
                ],
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF75EEFD),
              size: 28,
            ),
          ),
          Positioned(
            right: 16,
            top: 20,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF75EEFD),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF75EEFD).withOpacity(0.75),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EmptyRadarIcon(),
            SizedBox(height: 24),
            Text(
              'На радарах всё\nспокойно',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF4F3F3),
                fontSize: 24,
                height: 1.33,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Здесь будут появляться важные системные сообщения, новости и напоминания о релизах',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFAAABAB),
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.notifications,
    required this.onDelete,
    required this.onOpenGame,
  });

  final List<AppNotificationModel> notifications;
  final ValueChanged<AppNotificationModel> onDelete;
  final ValueChanged<AppNotificationModel> onOpenGame;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 48),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final notification = notifications[index];

        return _NotificationCard(
          notification: notification,
          onDelete: () => onDelete(notification),
          onTap: () => onOpenGame(notification),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onDelete,
    required this.onTap,
  });

  final AppNotificationModel notification;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(notification);
    final title = _titleText(notification);
    final actionText = _actionText(notification);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withOpacity(0.10),
        highlightColor: color.withOpacity(0.06),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF081F23),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(
                notification.type == AppNotificationType.warning ? 0.46 : 0.32,
              ),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(
                  notification.type == AppNotificationType.warning ? 0.10 : 0.05,
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotificationIcon(
                    icon: notification.icon,
                    color: color,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NotificationTitlePill(
                            text: title,
                            color: color,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              color: Color(0xFFF4F3F3),
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _DeleteNotificationButton(
                    onTap: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _NotificationMetaPill(
                    icon: Icons.schedule_rounded,
                    text: _relativeDateText(notification.createdAt),
                    color: color,
                  ),
                  if (actionText != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _NotificationActionHint(
                          text: actionText,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleText(AppNotificationModel notification) {
    switch (notification.type) {
      case AppNotificationType.game:
        return 'Игра в библиотеке';
      case AppNotificationType.success:
        return 'Успешно';
      case AppNotificationType.restore:
        return 'Восстановление данных';
      case AppNotificationType.rating:
        return 'Оценка обновлена';
      case AppNotificationType.progress:
        return 'Этап прохождения';
      case AppNotificationType.completed:
        return 'Этап завершён';
      case AppNotificationType.warning:
        return 'Внимание';
    }
  }

  Color _notificationColor(AppNotificationModel notification) {
    if (notification.type == AppNotificationType.warning) {
      return const Color(0xFFFF716C);
    }

    return const Color(0xFF75EEFD);
  }

  String? _actionText(AppNotificationModel notification) {
    if (notification.gameId == null) {
      return null;
    }

    return 'Открыть';
  }

  String _relativeDateText(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Только что';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${_plural(minutes, 'минута', 'минуты', 'минут')} назад';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${_plural(hours, 'час', 'часа', 'часов')} назад';
    }

    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    final currentDate = DateTime(date.year, date.month, date.day);

    if (currentDate == yesterday) {
      return 'Вчера, ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    }

    return '${_twoDigits(date.day)}.${_twoDigits(date.month)}.${date.year}';
  }

  String _plural(
      int value,
      String one,
      String few,
      String many,
      ) {
    final lastDigit = value % 10;
    final lastTwoDigits = value % 100;

    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return many;
    }

    if (lastDigit == 1) {
      return one;
    }

    if (lastDigit >= 2 && lastDigit <= 4) {
      return few;
    }

    return many;
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.34),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }
}

class _NotificationTitlePill extends StatelessWidget {
  const _NotificationTitlePill({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF10262B),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withOpacity(0.34),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationMetaPill extends StatelessWidget {
  const _NotificationMetaPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

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
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationActionHint extends StatelessWidget {
  const _NotificationActionHint({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

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
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.open_in_new_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteNotificationButton extends StatelessWidget {
  const _DeleteNotificationButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x1AFF716C),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0x99FF716C),
          ),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFFF716C),
          size: 23,
        ),
      ),
    );
  }
}
