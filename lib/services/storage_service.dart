import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyLastReadSurah = 'last_read_surah';
  static const String _keyLastReadSurahName = 'last_read_surah_name';
  static const String _keyLastReadAyah = 'last_read_ayah';
  static const String _keyBookmarks = 'saved_bookmarks';
  static const String _keyArabicFontSize = 'arabic_font_size';
  static const String _keyShowTranslation = 'show_translation';

  Future<void> saveLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastReadSurah, surahNumber);
    await prefs.setString(_keyLastReadSurahName, surahName);
    await prefs.setInt(_keyLastReadAyah, ayahNumber);
  }

  Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt(_keyLastReadSurah);
    if (surah == null) return null;
    return {
      'surah': surah,
      'surahName': prefs.getString(_keyLastReadSurahName) ?? 'Al-Fatiha',
      'ayah': prefs.getInt(_keyLastReadAyah) ?? 1,
    };
  }

  Future<List<int>> getBookmarkedSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBookmarks);
    if (list == null) return [];
    return list.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0).toList();
  }

  Future<bool> toggleBookmark(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBookmarks) ?? [];
    final str = surahNumber.toString();
    final exists = list.contains(str);
    if (exists) {
      list.remove(str);
    } else {
      list.add(str);
    }
    await prefs.setStringList(_keyBookmarks, list);
    return !exists;
  }

  Future<bool> isBookmarked(int surahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBookmarks) ?? [];
    return list.contains(surahNumber.toString());
  }

  Future<double> getArabicFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyArabicFontSize) ?? 24.0;
  }

  Future<void> saveArabicFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyArabicFontSize, size);
  }

  Future<bool> getShowTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowTranslation) ?? false;
  }

  Future<void> saveShowTranslation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTranslation, value);
  }
}
