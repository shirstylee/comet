import 'package:flutter/material.dart';

import '../../models/app_notification_model.dart';
import '../../storage/notification_change_notifier.dart';
import '../../storage/notification_storage.dart';

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
      final loadedNotifications =
      await NotificationStorage.getAllNotifications();

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

    await NotificationStorage.clearNotifications();
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final emptyTop = constraints.maxHeight * 177 / 884;
            final emptyHeight = constraints.maxHeight * 530.39 / 884;

            return Stack(
              children: [
                if (hasNotifications)
                  _NotificationsList(
                    notifications: notifications,
                    onDelete: _deleteNotification,
                  )
                else
                  Positioned(
                    left: 16,
                    right: 16,
                    top: emptyTop,
                    height: emptyHeight,
                    child: const _EmptyNotificationsState(),
                  ),
                _NotificationsTopBar(
                  showClearButton: hasNotifications,
                  onBack: () => Navigator.pop(context),
                  onClear: _clearNotifications,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsTopBar extends StatelessWidget {
  const _NotificationsTopBar({
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
      width: double.infinity,
      height: showClearButton ? 112 : 64,
      color: const Color(0xCC0C0F0F),
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF75EEFD),
                  size: 32,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 20,
            child: IgnorePointer(
              child: Text(
                'Уведомления',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFF4F3F3),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (showClearButton)
            Positioned(
              right: 16,
              top: 72,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Очистить всё',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF75EEFD),
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
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

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.notifications,
    required this.onDelete,
  });

  final List<AppNotificationModel> notifications;
  final ValueChanged<AppNotificationModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 112, 16, 48),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final notification = notifications[index];

        return _NotificationCard(
          notification: notification,
          onDelete: () => onDelete(notification),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onDelete,
  });

  final AppNotificationModel notification;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = notification.accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2020),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(
            icon: notification.icon,
            color: color,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFFF4F3F3),
                      fontSize: 16,
                      height: 1.62,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _relativeDateText(notification.createdAt),
                    style: const TextStyle(
                      color: Color(0xFFAAABAB),
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
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
    );
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: const SizedBox(
          width: 32,
          height: 34,
          child: Icon(
            Icons.delete_outline_rounded,
            color: Color(0xFFAAABAB),
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 91,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 296,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'На радарах всё\nспокойно',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF4F3F3),
                    fontSize: 24,
                    height: 1.33,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 312,
              child: Text(
                'Здесь будут появляться важные системные сообщения, новости и напоминания о релизах',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFAAABAB),
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
