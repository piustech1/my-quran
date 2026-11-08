import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_sync_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  StorageService._internal() {
    _initNotifiers();
    _hookFirebaseSync();
  }

  static const String _keyLastReadSurah = 'last_read_surah';
  static const String _keyLastReadSurahName = 'last_read_surah_name';
  static const String _keyLastReadAyah = 'last_read_ayah';
  static const String _keyBookmarks = 'saved_bookmarks';
  static const String _keyArabicFontSize = 'arabic_font_size';
  static const String _keyShowTranslation = 'show_translation';
  static const String _keyDailyAyahBookmarks = 'saved_daily_ayah_bookmarks';

  // ---------------------------------------------------------------------------
  // Reactive Notifiers for immediate app-level UI updates
  // ---------------------------------------------------------------------------
  final ValueNotifier<Map<String, dynamic>?> lastReadNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<List<int>> bookmarksNotifier =
      ValueNotifier<List<int>>(<int>[]);
  final ValueNotifier<List<String>> dailyBookmarksNotifier =
      ValueNotifier<List<String>>(<String>[]);

  Future<void> _initNotifiers() async {
    final lr = await getLastRead();
    lastReadNotifier.value = lr;

    final bm = await getBookmarkedSurahs();
    bookmarksNotifier.value = bm;

    final dbm = await getDailyAyahBookmarks();
    dailyBookmarksNotifier.value = dbm;
  }

  void _hookFirebaseSync() {
    final sync = FirebaseSyncService();
    sync.onRemoteProgressUpdated = (prog) async {
      final surah = prog['surahNumber'] as int?;
      final surahName = prog['surahName'] as String?;
      final ayah = prog['ayahNumber'] as int?;
      if (surah != null && surahName != null && ayah != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyLastReadSurah, surah);
        await prefs.setString(_keyLastReadSurahName, surahName);
        await prefs.setInt(_keyLastReadAyah, ayah);
        lastReadNotifier.value = {
          'surah': surah,
          'surahName': surahName,
          'ayah': ayah,
        };
      }
    };

    sync.onRemoteBookmarksUpdated = (surahs, ayahs) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _keyBookmarks,
        surahs.map((s) => s.toString()).toList(),
      );
      bookmarksNotifier.value = surahs;

      await prefs.setStringList(_keyDailyAyahBookmarks, ayahs);
      dailyBookmarksNotifier.value = ayahs;
    };
  }

  Future<void> saveLastRead({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastReadSurah, surahNumber);
    await prefs.setString(_keyLastReadSurahName, surahName);
    await prefs.setInt(_keyLastReadAyah, ayahNumber);

    final updated = {
      'surah': surahNumber,
      'surahName': surahName,
      'ayah': ayahNumber,
    };
    lastReadNotifier.value = updated;

    // Trigger cloud synchronization if available
    FirebaseSyncService().syncReadingProgress(
      surahNumber: surahNumber,
      surahName: surahName,
      ayahNumber: ayahNumber,
    );
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

    final updatedInts =
        list.map((e) => int.tryParse(e) ?? 0).where((n) => n > 0).toList();
    bookmarksNotifier.value = updatedInts;

    // Trigger cloud synchronization
    final daily = await getDailyAyahBookmarks();
    FirebaseSyncService().syncBookmarks(surahs: updatedInts, ayahs: daily);

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

  Future<List<String>> getDailyAyahBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyDailyAyahBookmarks) ?? [];
  }

  Future<bool> toggleDailyAyahBookmark(int chapter, int verse) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyDailyAyahBookmarks) ?? [];
    final id = '$chapter:$verse';
    final exists = list.contains(id);
    if (exists) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await prefs.setStringList(_keyDailyAyahBookmarks, list);
    dailyBookmarksNotifier.value = List<String>.from(list);

    // Trigger cloud synchronization
    final surahs = await getBookmarkedSurahs();
    FirebaseSyncService().syncBookmarks(surahs: surahs, ayahs: list);

    return !exists;
  }

  Future<bool> isDailyAyahBookmarked(int chapter, int verse) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyDailyAyahBookmarks) ?? [];
    return list.contains('$chapter:$verse');
  }

  Future<double> getDailyAyahFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('daily_ayah_font_size') ?? 26.0;
  }

  Future<void> saveDailyAyahFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_ayah_font_size', size);
  }

  Future<bool> getShowTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowTranslation) ?? false;
  }

  Future<void> saveShowTranslation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTranslation, value);
  }

  // ---------------------------------------------------------------------------
  // Onboarding & Auth State
  // ---------------------------------------------------------------------------
  static const String _keyCompletedOnboarding = 'has_completed_onboarding';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCompletedOnboarding) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompletedOnboarding, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<void> saveUserSession({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setBool(_keyCompletedOnboarding, true);

    // Merge any local reading progress / bookmarks to the user's cloud account
    final lr = await getLastRead();
    final surahs = await getBookmarkedSurahs();
    final daily = await getDailyAyahBookmarks();
    await FirebaseSyncService().mergeLocalDataToCloud(
      lastRead: lr,
      surahBookmarks: surahs,
      dailyAyahBookmarks: daily,
    );
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await FirebaseSyncService().signOut();
  }
}
