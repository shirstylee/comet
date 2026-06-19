class GameStageModel {
  const GameStageModel({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.description = '',
    this.completedAt,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final String description;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'isDone': isDone,
      'description': description,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory GameStageModel.fromMap(Map<dynamic, dynamic> map) {
    return GameStageModel(
      title: _readString(map['title'], fallback: 'Этап'),
      subtitle: _readString(map['subtitle'], fallback: 'В процессе'),
      isDone: _readBool(map['isDone']),
      description: _readString(map['description'], fallback: ''),
      completedAt: _readDateTime(map['completedAt']),
    );
  }

  static String _readString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final text = value.trim().toLowerCase();

      if (text == 'true' || text == '1' || text == 'yes') {
        return true;
      }

      if (text == 'false' || text == '0' || text == 'no') {
        return false;
      }
    }

    return false;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }
}
