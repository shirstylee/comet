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

    await NotificationStorage.clearNotifications();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 64,
          color: const Color(0xCC0C0F0F),
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
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        if (showClearButton)
          Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xCC0C0F0F),
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'Очистить всё',
                  style: TextStyle(
                    color: Color(0xFF75EEFD),
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
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
    final color = notification.accentColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
        ),
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
