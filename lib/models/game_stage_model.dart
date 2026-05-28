class GameStageModel {
  const GameStageModel({
    required this.title,
    required this.subtitle,
    required this.isDone,
    this.completedAt,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final DateTime? completedAt;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'isDone': isDone,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory GameStageModel.fromMap(Map<dynamic, dynamic> map) {
    return GameStageModel(
      title: map['title'] as String? ?? 'Этап',
      subtitle: map['subtitle'] as String? ?? 'В процессе',
      isDone: map['isDone'] as bool? ?? false,
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.tryParse(map['completedAt'].toString()),
    );
  }
}