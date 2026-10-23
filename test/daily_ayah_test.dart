import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_quran/services/daily_ayah_service.dart';
import 'package:my_quran/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyAyahService Tests', () {
    late DailyAyahService service;

    setUp(() {
      service = DailyAyahService();
      SharedPreferences.setMockInitialValues({});
    });

    test('getDailyAyah returns valid complete Quran verse', () {
      final ayah = service.getDailyAyah();

      expect(ayah.surahNumber, greaterThan(0));
      expect(ayah.ayahNumber, greaterThan(0));
      expect(ayah.arabicText.isNotEmpty, isTrue);
      expect(ayah.defaultTranslation.isNotEmpty, isTrue);
      expect(ayah.surahNameEnglish.isNotEmpty, isTrue);
      expect(ayah.surahNameArabic.isNotEmpty, isTrue);
      expect(ayah.explanation.isNotEmpty, isTrue);
      expect(ayah.tafsirAttribution.isNotEmpty, isTrue);
      expect(ayah.imageAsset.isNotEmpty, isTrue);
    });

    test('getDailyAyah is deterministic for the same date', () {
      final date1 = DateTime(2026, 10, 23, 8, 30);
      final date2 = DateTime(2026, 10, 23, 23, 59);

      final ayah1 = service.getDailyAyah(date1);
      final ayah2 = service.getDailyAyah(date2);

      expect(ayah1.surahNumber, equals(ayah2.surahNumber));
      expect(ayah1.ayahNumber, equals(ayah2.ayahNumber));
      expect(ayah1.arabicText, equals(ayah2.arabicText));
    });

    test('supported translations list contains real editions', () {
      const editions = DailyAyahService.supportedTranslations;
      expect(editions.length, greaterThanOrEqualTo(5));

      final ids = editions.map((e) => e.id).toList();
      expect(ids, contains('eng-abdelhaleem'));
      expect(ids, contains('fra-rashidmaash'));
      expect(ids, contains('urd-abulaalamaududi'));
    });

    test('StorageService daily ayah bookmark toggle works', () async {
      final storage = StorageService();

      expect(await storage.isDailyAyahBookmarked(94, 5), isFalse);

      final bookmarked = await storage.toggleDailyAyahBookmark(94, 5);
      expect(bookmarked, isTrue);
      expect(await storage.isDailyAyahBookmarked(94, 5), isTrue);

      final unbookmarked = await storage.toggleDailyAyahBookmark(94, 5);
      expect(unbookmarked, isFalse);
      expect(await storage.isDailyAyahBookmarked(94, 5), isFalse);
    });

    test('StorageService daily ayah font size preference works', () async {
      final storage = StorageService();

      expect(await storage.getDailyAyahFontSize(), equals(26.0));

      await storage.saveDailyAyahFontSize(30.0);
      expect(await storage.getDailyAyahFontSize(), equals(30.0));
    });
  });
}
