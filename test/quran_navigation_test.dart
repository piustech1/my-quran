import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/models/quran_navigation_data.dart';

void main() {
  group('Quran Navigation Data Tests', () {
    test('QuranPageCatalog contains exactly 604 Madani Mushaf pages', () {
      final pages = QuranPageCatalog.allPages;
      expect(pages.length, equals(604));

      // Page 1 should start at Surah 1 (Al-Fatiha)
      expect(pages.first.pageNumber, equals(1));
      expect(pages.first.surahNumber, equals(1));
      expect(pages.first.surahName, equals('Al-Fatiha'));

      // Page 604 should end with the last chapters (An-Nas)
      expect(pages.last.pageNumber, equals(604));
      expect(pages.last.surahNumber, equals(114));
    });

    test('kAllHizbs contains exactly 60 Quranic Hizbs', () {
      expect(kAllHizbs.length, equals(60));

      // Hizb 1 starts at Al-Fatiha
      expect(kAllHizbs.first.hizbNumber, equals(1));
      expect(kAllHizbs.first.surahName, equals('Al-Fatiha'));

      // Hizb 60 starts at Al-A'la
      expect(kAllHizbs.last.hizbNumber, equals(60));
      expect(kAllHizbs.last.surahName, equals("Al-A'la"));
    });
  });
}
