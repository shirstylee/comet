import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile_model.dart';

class ProfileStorage {
  static const String _boxName = 'user_profile';
  static const String _profileKey = 'profile';

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }

    return Hive.openBox(_boxName);
  }

  static Future<UserProfileModel> getProfile() async {
    final box = await _openBox();

    final value = box.get(_profileKey);

    if (value is Map) {
      return UserProfileModel.fromMap(value);
    }

    return const UserProfileModel(
      name: '',
      status: '',
      favoriteGenres: [],
      avatarPath: null,
    );
  }

  static Future<void> saveProfile(UserProfileModel profile) async {
    final box = await _openBox();

    await box.put(_profileKey, profile.toMap());
  }

  static Future<bool> hasProfile() async {
    final box = await _openBox();

    return box.containsKey(_profileKey);
  }

  static Future<void> clearProfile() async {
    final box = await _openBox();

    await box.delete(_profileKey);
  }
}