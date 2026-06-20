import 'package:hive_flutter/hive_flutter.dart';

class LibraryPreferencesStorage {
  static const String _boxName = 'library_preferences';

  static const String _viewTypeKey = 'view_type';
  static const String _sortTypeKey = 'sort_type';

  static const String listViewType = 'list';
  static const String gridViewType = 'grid';

  static const String latestSortType = 'latest';
  static const String titleAscSortType = 'title_asc';
  static const String titleDescSortType = 'title_desc';
  static const String ratingAscSortType = 'rating_asc';
  static const String ratingDescSortType = 'rating_desc';
  static const String favoritesSortType = 'favorites';

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

  static Future<String> getSortType() async {
    final box = await _openBox();
    final value = box.get(_sortTypeKey);

    switch (value) {
      case titleAscSortType:
      case titleDescSortType:
      case ratingAscSortType:
      case ratingDescSortType:
      case favoritesSortType:
        return value.toString();
      case latestSortType:
      default:
        return latestSortType;
    }
  }

  static Future<void> saveSortType(String sortType) async {
    final box = await _openBox();

    final safeSortType = switch (sortType) {
      titleAscSortType => titleAscSortType,
      titleDescSortType => titleDescSortType,
      ratingAscSortType => ratingAscSortType,
      ratingDescSortType => ratingDescSortType,
      favoritesSortType => favoritesSortType,
      _ => latestSortType,
    };

    await box.put(_sortTypeKey, safeSortType);
  }

  static Future<void> clearPreferences() async {
    final box = await _openBox();

    await box.delete(_viewTypeKey);
    await box.delete(_sortTypeKey);
  }
}
