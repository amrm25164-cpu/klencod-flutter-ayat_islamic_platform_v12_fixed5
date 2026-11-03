import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _lastPageKey = 'last_page';
  static const _lastSurahKey = 'last_surah';
  static const _bookmarksKey = 'bookmarked_pages';

  Future<int> getLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPageKey) ?? 1;
  }

  Future<void> saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPageKey, page.clamp(1, 604));
  }

  Future<List<int>> getBookmarkedPages() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_bookmarksKey) ?? <String>[];
    return values.map((value) => int.tryParse(value)).whereType<int>()
        .where((page) => page >= 1 && page <= 604).toSet().toList()..sort();
  }

  Future<bool> toggleBookmarkedPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final pages = (prefs.getStringList(_bookmarksKey) ?? <String>[]).toSet();
    final key = page.clamp(1, 604).toString();
    final added = !pages.remove(key);
    if (added) pages.add(key);
    await prefs.setStringList(_bookmarksKey, pages.toList());
    return added;
  }

  Future<int> getLastSurah() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSurahKey) ?? 1;
  }

  Future<void> saveLastSurah(int surah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSurahKey, surah.clamp(1, 114));
  }
}
