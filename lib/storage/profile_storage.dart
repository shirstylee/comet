import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile_model.dart';
import '../services/avatar_storage_service.dart';

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
      favoritePlatforms: [],
      avatarPath: null,
    );
  }

  static Future<void> saveProfile(UserProfileModel profile) async {
    final box = await _openBox();
    final oldValue = box.get(_profileKey);
    String? oldAvatarPath;

    if (oldValue is Map) {
      oldAvatarPath = UserProfileModel.fromMap(oldValue).avatarPath;
    }

    await box.put(
      _profileKey,
      profile.toMap(),
    );

    await _deleteOldAvatarIfNeeded(
      oldAvatarPath: oldAvatarPath,
      newAvatarPath: profile.avatarPath,
    );
  }

  static Future<bool> hasProfile() async {
    final box = await _openBox();

    return box.containsKey(_profileKey);
  }

  static Future<bool> hasCompleteProfile() async {
    final box = await _openBox();
    final value = box.get(_profileKey);

    if (value is! Map) {
      return false;
    }

    final profile = UserProfileModel.fromMap(value);

    return _isCompleteProfile(profile);
  }

  static Future<bool> _isCompleteProfile(UserProfileModel profile) async {
    final avatarPath = profile.avatarPath?.trim();

    if (profile.name.trim().isEmpty) {
      return false;
    }

    if (profile.status.trim().isEmpty) {
      return false;
    }

    if (profile.favoritePlatforms
        .where((platform) => platform.trim().isNotEmpty)
        .isEmpty) {
      return false;
    }

    if (avatarPath == null || avatarPath.isEmpty) {
      return false;
    }

    try {
      return File(avatarPath).exists();
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearProfile() async {
    final box = await _openBox();
    final value = box.get(_profileKey);

    if (value is Map) {
      final profile = UserProfileModel.fromMap(value);

      await AvatarStorageService.deleteAvatar(profile.avatarPath);
    }

    await box.delete(_profileKey);
  }

  static Future<void> _deleteOldAvatarIfNeeded({
    required String? oldAvatarPath,
    required String? newAvatarPath,
  }) async {
    if (oldAvatarPath == null || oldAvatarPath.trim().isEmpty) {
      return;
    }

    if (oldAvatarPath == newAvatarPath) {
      return;
    }

    await AvatarStorageService.deleteAvatar(oldAvatarPath);
  }
}
