import 'package:flutter/material.dart';

enum AppNotificationType {
  game,
  success,
  restore,
  release,
  rating,
  progress,
  completed,
  warning,
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.createdAt,
    this.gameId,
    this.gameTitle,
    this.isRead = false,
  });

  final String id;
  final String message;
  final AppNotificationType type;
  final DateTime createdAt;
  final int? gameId;
  final String? gameTitle;
  final bool isRead;

  IconData get icon {
    switch (type) {
      case AppNotificationType.game:
        return Icons.sports_esports_rounded;
      case AppNotificationType.success:
        return Icons.done_rounded;
      case AppNotificationType.restore:
        return Icons.history_rounded;
      case AppNotificationType.release:
        return Icons.calendar_month_rounded;
      case AppNotificationType.rating:
        return Icons.star_rounded;
      case AppNotificationType.progress:
        return Icons.flag_rounded;
      case AppNotificationType.completed:
        return Icons.check_circle_rounded;
      case AppNotificationType.warning:
        return Icons.priority_high_rounded;
    }
  }

  Color get accentColor {
    switch (type) {
      case AppNotificationType.game:
        return const Color(0xFF75EEFD);
      case AppNotificationType.success:
        return const Color(0xFFBBFFB3);
      case AppNotificationType.restore:
        return const Color(0xFFBBFFB3);
      case AppNotificationType.release:
        return const Color(0xFF61ACFE);
      case AppNotificationType.rating:
        return const Color(0xFFFACC15);
      case AppNotificationType.progress:
        return const Color(0xFF75EEFD);
      case AppNotificationType.completed:
        return const Color(0xFFBBFFB3);
      case AppNotificationType.warning:
        return const Color(0xFFF97316);
    }
  }

  AppNotificationModel copyWith({
    String? id,
    String? message,
    AppNotificationType? type,
    DateTime? createdAt,
    int? gameId,
    String? gameTitle,
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      gameId: gameId ?? this.gameId,
      gameTitle: gameTitle ?? this.gameTitle,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'gameId': gameId,
      'gameTitle': gameTitle,
      'isRead': isRead,
    };
  }

  factory AppNotificationModel.fromMap(Map<dynamic, dynamic> map) {
    return AppNotificationModel(
      id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      message: map['message']?.toString() ?? '',
      type: _parseType(map['type']),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      gameId: map['gameId'] is num ? (map['gameId'] as num).toInt() : null,
      gameTitle: map['gameTitle']?.toString(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  static AppNotificationType _parseType(dynamic value) {
    final rawType = value?.toString();

    for (final type in AppNotificationType.values) {
      if (type.name == rawType) {
        return type;
      }
    }

    return AppNotificationType.game;
  }
}
