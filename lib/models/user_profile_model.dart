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
    final rawPlatforms = map['favoritePlatforms'] ?? map['favoriteGenres'];

    return UserProfileModel(
      name: map['name'] as String? ?? '',
      status: map['status'] as String? ?? '',
      favoritePlatforms: rawPlatforms is List
          ? rawPlatforms.map((platform) => platform.toString()).toList()
          : const [],
      avatarPath: map['avatarPath'] as String?,
    );
  }
}