class UserProfileModel {
  const UserProfileModel({
    required this.name,
    required this.status,
    required this.favoriteGenres,
    this.avatarPath,
  });

  final String name;
  final String status;
  final List<String> favoriteGenres;
  final String? avatarPath;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'favoriteGenres': favoriteGenres,
      'avatarPath': avatarPath,
    };
  }

  factory UserProfileModel.fromMap(Map<dynamic, dynamic> map) {
    final rawGenres = map['favoriteGenres'];

    return UserProfileModel(
      name: map['name'] as String? ?? 'GamerOne',
      status: map['status'] as String? ?? 'Master Explorer',
      favoriteGenres: rawGenres is List
          ? rawGenres.map((genre) => genre.toString()).toList()
          : const [],
      avatarPath: map['avatarPath'] as String?,
    );
  }
}