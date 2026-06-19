class UserProfileModel {
  const UserProfileModel({
    required this.name,
    required this.status,
    required this.favoritePlatforms,
    this.avatarPath,
  });

  final String name;
  final String status;
  final List<String> favoritePlatforms;
  final String? avatarPath;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'favoritePlatforms': favoritePlatforms,
      'avatarPath': avatarPath,
    };
  }

  factory UserProfileModel.fromMap(Map<dynamic, dynamic> map) {
    return UserProfileModel(
      name: _readString(map['name']),
      status: _readString(map['status']),
      favoritePlatforms: _readStringList(map['favoritePlatforms']),
      avatarPath: _readOptionalString(map['avatarPath']),
    );
  }

  static String _readString(dynamic value) {
    if (value == null) return '';

    return value.toString().trim();
  }

  static String? _readOptionalString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
