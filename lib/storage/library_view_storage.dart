import 'package:hive_flutter/hive_flutter.dart';

class LibraryViewStorage {
  static const String _boxName = 'library_view_preferences';
  static const String _viewTypeKey = 'view_type';

  static const String listViewType = 'list';
  static const String gridViewType = 'grid';

  static Future<Box> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }

    return Hive.openBox(_boxName);
  }

  static Future<String> getViewType() async {
    final box = await _openBox();
    final value = box.get(_viewTypeKey);

    if (value == gridViewType) {
      return gridViewType;
    }

    return listViewType;
  }

  static Future<void> saveViewType(String viewType) async {
    final box = await _openBox();

    await box.put(
      _viewTypeKey,
      viewType == gridViewType ? gridViewType : listViewType,
    );
  }

  static Future<void> clearViewType() async {
    final box = await _openBox();

    await box.delete(_viewTypeKey);
  }
}
