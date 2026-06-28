import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CoverCacheService {
  static const int _maxCoverWidth = 500;
  static const int _jpegQuality = 72;
  static const String _coversFolderName = 'covers';

  static Future<String?> saveCompressedCover({
    required int gameId,
    required String? imageUrl,
  }) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return null;
    }

    try {
      final uri = Uri.tryParse(imageUrl);

      if (uri == null) {
        return null;
      }

      final response = await http
          .get(
        uri,
        headers: const {
          'User-Agent': 'CometApp/1.0',
        },
      )
          .timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      final coversDirectory = await _getCoversDirectory();
      final file = File('${coversDirectory.path}/game_$gameId.jpg');

      final compressedBytes = await _compressCover(response.bodyBytes);

      if (compressedBytes.isNotEmpty) {
        await file.writeAsBytes(
          compressedBytes,
          flush: true,
        );

        return file.path;
      }

      await file.writeAsBytes(
        response.bodyBytes,
        flush: true,
      );

      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> _compressCover(Uint8List originalBytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: _maxCoverWidth,
        quality: _jpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      return Uint8List.fromList(compressedBytes);
    } catch (_) {
      return Uint8List(0);
    }
  }

  static Future<void> deleteCover(String? localImagePath) async {
    if (localImagePath == null || localImagePath.trim().isEmpty) {
      return;
    }

    try {
      final file = File(localImagePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
    }
  }

  static Future<Directory> _getCoversDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final coversDirectory = Directory(
      '${appDirectory.path}/$_coversFolderName',
    );

    if (!await coversDirectory.exists()) {
      await coversDirectory.create(recursive: true);
    }

    return coversDirectory;
  }
}