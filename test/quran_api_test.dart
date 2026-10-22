import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/constants/surah_data.dart';
import 'package:my_quran/models/ayah.dart';
import 'package:my_quran/models/juz.dart';

void main() {
  group('Quran Data & Models Test', () {
    test('114 Surahs are accurately loaded', () {
      expect(kAllSurahs.length, 114);
      expect(kAllSurahs.first.englishName, 'Al-Fatiha');
      expect(kAllSurahs.first.numberOfAyahs, 7);
      expect(kAllSurahs.last.englishName, 'An-Nas');
      expect(kAllSurahs.last.numberOfAyahs, 6);
    });

    test('30 Juzs are accurately loaded', () {
      expect(kAllJuzs.length, 30);
      expect(kAllJuzs.first.number, 1);
      expect(kAllJuzs.last.number, 30);
    });

    test('Ayah fromJson and toMap parsing works', () {
      final arabicJson = {
        'chapter': 1,
        'verse': 1,
        'text': 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ',
      };
      final englishJson = {
        'chapter': 1,
        'verse': 1,
        'text': 'In the name of God, the Lord of Mercy, the Giver of Mercy',
      };

      final ayah = Ayah.fromJson(
        arabicJson: arabicJson,
        translationJson: englishJson,
      );

      expect(ayah.chapter, 1);
      expect(ayah.verse, 1);
      expect(ayah.arabicText, 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ');
      expect(ayah.translation, 'In the name of God, the Lord of Mercy, the Giver of Mercy');

      final map = ayah.toMap();
      final fromMap = Ayah.fromMap(map);
      expect(fromMap.chapter, ayah.chapter);
      expect(fromMap.verse, ayah.verse);
      expect(fromMap.arabicText, ayah.arabicText);
      expect(fromMap.translation, ayah.translation);
    });
  });
}
