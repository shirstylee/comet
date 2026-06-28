import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class AvatarStorageService {
  const AvatarStorageService._();

  static const String _profileFolderName = 'profile';

  static Future<String> saveAvatar(File sourceFile) async {
    if (!await sourceFile.exists()) {
      throw const FileSystemException('Файл аватара не найден');
    }

    final bytes = await sourceFile.readAsBytes();

    if (bytes.isEmpty) {
      throw const FileSystemException('Файл аватара пустой');
    }

    return saveAvatarBytes(
      bytes,
      sourcePath: sourceFile.path,
    );
  }

  static Future<String> saveAvatarBytes(
      Uint8List bytes, {
        String? sourcePath,
      }) async {
    if (bytes.isEmpty) {
      throw const FileSystemException('Файл аватара пустой');
    }

    final directory = await _getProfileDirectory();
    final extension = _safeExtension(sourcePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/profile_avatar_$timestamp$extension');

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file.path;
  }

  static Future<void> deleteAvatar(String? avatarPath) async {
    if (!await isManagedAvatarPath(avatarPath)) {
      return;
    }

    try {
      final file = File(avatarPath!);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
    }
  }

  static Future<bool> isManagedAvatarPath(String? avatarPath) async {
    if (avatarPath == null || avatarPath.trim().isEmpty) {
      return false;
    }

    final directory = await _getProfileDirectory();
    final normalizedAvatarPath = _normalizePath(avatarPath);
    final normalizedDirectoryPath = _normalizePath(directory.path);

    return normalizedAvatarPath.startsWith('$normalizedDirectoryPath/');
  }

  static Future<Directory> _getProfileDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final profileDirectory = Directory(
      '${appDirectory.path}/$_profileFolderName',
    );

    if (!await profileDirectory.exists()) {
      await profileDirectory.create(recursive: true);
    }

    return profileDirectory;
  }

  static String _safeExtension(String? sourcePath) {
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return '.jpg';
    }

    final normalizedPath = sourcePath.toLowerCase();
    final extensionStart = normalizedPath.lastIndexOf('.');

    if (extensionStart < 0 || extensionStart == normalizedPath.length - 1) {
      return '.jpg';
    }

    final extension = normalizedPath.substring(extensionStart);
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

    if (!allowedExtensions.contains(extension)) {
      return '.jpg';
    }

    return extension;
  }

  static String _normalizePath(String path) {
    return path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  }
}
