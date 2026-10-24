import '../constants/surah_data.dart';

/// Metadata for a standard Madani Mushaf Page (1 to 604)
class PageMeta {
  final int pageNumber;
  final int juzNumber;
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int startAyah;

  const PageMeta({
    required this.pageNumber,
    required this.juzNumber,
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.startAyah,
  });
}

/// Metadata for a Quranic Hizb (1 to 60)
class HizbMeta {
  final int hizbNumber;
  final int juzNumber;
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int startAyah;
  final String arabicOpening;

  const HizbMeta({
    required this.hizbNumber,
    required this.juzNumber,
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.startAyah,
    required this.arabicOpening,
  });
}

/// Standard verified starting Surah and Ayah for the 60 Quranic Hizbs
const List<HizbMeta> kAllHizbs = [
  HizbMeta(hizbNumber: 1, juzNumber: 1, surahNumber: 1, surahName: "Al-Fatiha", surahNameArabic: "الفاتحة", startAyah: 1, arabicOpening: "الم"),
  HizbMeta(hizbNumber: 2, juzNumber: 1, surahNumber: 2, surahName: "Al-Baqarah", surahNameArabic: "البقرة", startAyah: 75, arabicOpening: "أَفَتَطْمَعُونَ"),
  HizbMeta(hizbNumber: 3, juzNumber: 2, surahNumber: 2, surahName: "Al-Baqarah", surahNameArabic: "البقرة", startAyah: 142, arabicOpening: "سَيَقُولُ السُّفَهَاءُ"),
  HizbMeta(hizbNumber: 4, juzNumber: 2, surahNumber: 2, surahName: "Al-Baqarah", surahNameArabic: "البقرة", startAyah: 203, arabicOpening: "وَاذْكُرُوا اللَّهَ"),
  HizbMeta(hizbNumber: 5, juzNumber: 3, surahNumber: 2, surahName: "Al-Baqarah", surahNameArabic: "البقرة", startAyah: 253, arabicOpening: "تِلْكَ الرُّسُلُ"),
  HizbMeta(hizbNumber: 6, juzNumber: 3, surahNumber: 3, surahName: "Ali 'Imran", surahNameArabic: "آل عمران", startAyah: 15, arabicOpening: "قُلْ أَؤُنَبِّئُكُمْ"),
  HizbMeta(hizbNumber: 7, juzNumber: 4, surahNumber: 3, surahName: "Ali 'Imran", surahNameArabic: "آل عمران", startAyah: 93, arabicOpening: "كُلُّ الطَّعَامِ"),
  HizbMeta(hizbNumber: 8, juzNumber: 4, surahNumber: 3, surahName: "Ali 'Imran", surahNameArabic: "آل عمران", startAyah: 171, arabicOpening: "يَسْتَبْشِرُونَ"),
  HizbMeta(hizbNumber: 9, juzNumber: 5, surahNumber: 4, surahName: "An-Nisa", surahNameArabic: "النساء", startAyah: 24, arabicOpening: "وَالْمُحْصَنَاتُ"),
  HizbMeta(hizbNumber: 10, juzNumber: 5, surahNumber: 4, surahName: "An-Nisa", surahNameArabic: "النساء", startAyah: 88, arabicOpening: "فَمَا لَكُمْ فِي الْمُنَافِقِينَ"),
  HizbMeta(hizbNumber: 11, juzNumber: 6, surahNumber: 4, surahName: "An-Nisa", surahNameArabic: "النساء", startAyah: 148, arabicOpening: "لَا يُحِبُّ اللَّهُ"),
  HizbMeta(hizbNumber: 12, juzNumber: 6, surahNumber: 5, surahName: "Al-Ma'idah", surahNameArabic: "المائدة", startAyah: 27, arabicOpening: "وَاتْلُ عَلَيْهِمْ"),
  HizbMeta(hizbNumber: 13, juzNumber: 7, surahNumber: 5, surahName: "Al-Ma'idah", surahNameArabic: "المائدة", startAyah: 82, arabicOpening: "لَتَجِدَنَّ أَشَدَّ"),
  HizbMeta(hizbNumber: 14, juzNumber: 7, surahNumber: 6, surahName: "Al-An'am", surahNameArabic: "الأنعام", startAyah: 36, arabicOpening: "إِنَّمَا يَسْتَجِيبُ"),
  HizbMeta(hizbNumber: 15, juzNumber: 8, surahNumber: 6, surahName: "Al-An'am", surahNameArabic: "الأنعام", startAyah: 111, arabicOpening: "وَلَوْ أَنَّنَا نَزَّلْنَا"),
  HizbMeta(hizbNumber: 16, juzNumber: 8, surahNumber: 7, surahName: "Al-A'raf", surahNameArabic: "الأعراف", startAyah: 1, arabicOpening: "المص"),
  HizbMeta(hizbNumber: 17, juzNumber: 9, surahNumber: 7, surahName: "Al-A'raf", surahNameArabic: "الأعراف", startAyah: 88, arabicOpening: "قَالَ الْمَلَأُ"),
  HizbMeta(hizbNumber: 18, juzNumber: 9, surahNumber: 7, surahName: "Al-A'raf", surahNameArabic: "الأعراف", startAyah: 171, arabicOpening: "وَإِذْ نَتَقْنَا الْجَبَلَ"),
  HizbMeta(hizbNumber: 19, juzNumber: 10, surahNumber: 8, surahName: "Al-Anfal", surahNameArabic: "الأنفال", startAyah: 41, arabicOpening: "وَاعْلَمُوا أَنَّمَا"),
  HizbMeta(hizbNumber: 20, juzNumber: 10, surahNumber: 9, surahName: "At-Tawbah", surahNameArabic: "التوبة", startAyah: 34, arabicOpening: "يَا أَيُّهَا الَّذِينَ آمَنُوا"),
  HizbMeta(hizbNumber: 21, juzNumber: 11, surahNumber: 9, surahName: "At-Tawbah", surahNameArabic: "التوبة", startAyah: 93, arabicOpening: "إِنَّمَا السَّبِيلُ"),
  HizbMeta(hizbNumber: 22, juzNumber: 11, surahNumber: 10, surahName: "Yunus", surahNameArabic: "يونس", startAyah: 26, arabicOpening: "لِلَّذِينَ أَحْسَنُوا"),
  HizbMeta(hizbNumber: 23, juzNumber: 12, surahNumber: 11, surahName: "Hud", surahNameArabic: "هود", startAyah: 6, arabicOpening: "وَمَا مِنْ دَابَّةٍ"),
  HizbMeta(hizbNumber: 24, juzNumber: 12, surahNumber: 11, surahName: "Hud", surahNameArabic: "هود", startAyah: 84, arabicOpening: "وَإِلَى مَدْيَنَ"),
  HizbMeta(hizbNumber: 25, juzNumber: 13, surahNumber: 12, surahName: "Yusuf", surahNameArabic: "يوسف", startAyah: 53, arabicOpening: "وَمَا أُبَرِّئُ نَفْسِي"),
  HizbMeta(hizbNumber: 26, juzNumber: 13, surahNumber: 13, surahName: "Ar-Ra'd", surahNameArabic: "الرعد", startAyah: 19, arabicOpening: "أَفَمَنْ يَعْلَمُ"),
  HizbMeta(hizbNumber: 27, juzNumber: 14, surahNumber: 15, surahName: "Al-Hijr", surahNameArabic: "الحجر", startAyah: 1, arabicOpening: "الر تِلْكَ"),
  HizbMeta(hizbNumber: 28, juzNumber: 14, surahNumber: 16, surahName: "An-Nahl", surahNameArabic: "النحل", startAyah: 51, arabicOpening: "وَقَالَ اللَّهُ لَا تَتَّخِذُوا"),
  HizbMeta(hizbNumber: 29, juzNumber: 15, surahNumber: 17, surahName: "Al-Isra", surahNameArabic: "الإسراء", startAyah: 1, arabicOpening: "سُبْحَانَ الَّذِي"),
  HizbMeta(hizbNumber: 30, juzNumber: 15, surahNumber: 17, surahName: "Al-Isra", surahNameArabic: "الإسراء", startAyah: 99, arabicOpening: "أَوَلَمْ يَرَوْا"),
  HizbMeta(hizbNumber: 31, juzNumber: 16, surahNumber: 18, surahName: "Al-Kahf", surahNameArabic: "الكهف", startAyah: 75, arabicOpening: "قَالَ أَلَمْ أَقُلْ لَكَ"),
  HizbMeta(hizbNumber: 32, juzNumber: 16, surahNumber: 19, surahName: "Maryam", surahNameArabic: "مريم", startAyah: 59, arabicOpening: "فَخَلَفَ مِنْ بَعْدِهِمْ"),
  HizbMeta(hizbNumber: 33, juzNumber: 17, surahNumber: 21, surahName: "Al-Anbiya", surahNameArabic: "الأنبياء", startAyah: 1, arabicOpening: "اقْتَرَبَ لِلنَّاسِ"),
  HizbMeta(hizbNumber: 34, juzNumber: 17, surahNumber: 22, surahName: "Al-Hajj", surahNameArabic: "الحج", startAyah: 19, arabicOpening: "هَذَانِ خَصْمَانِ"),
  HizbMeta(hizbNumber: 35, juzNumber: 18, surahNumber: 23, surahName: "Al-Mu'minun", surahNameArabic: "المؤمنون", startAyah: 1, arabicOpening: "قَدْ أَفْلَحَ"),
  HizbMeta(hizbNumber: 36, juzNumber: 18, surahNumber: 24, surahName: "An-Nur", surahNameArabic: "النور", startAyah: 21, arabicOpening: "يَا أَيُّهَا الَّذِينَ آمَنُوا"),
  HizbMeta(hizbNumber: 37, juzNumber: 19, surahNumber: 25, surahName: "Al-Furqan", surahNameArabic: "الفرقان", startAyah: 21, arabicOpening: "وَقَالَ الَّذِينَ لَا يَرْجُونَ"),
  HizbMeta(hizbNumber: 38, juzNumber: 19, surahNumber: 26, surahName: "Ash-Shu'ara", surahNameArabic: "الشعراء", startAyah: 111, arabicOpening: "قَالُوا أَنُؤْمِنُ لَكَ"),
  HizbMeta(hizbNumber: 39, juzNumber: 20, surahNumber: 27, surahName: "An-Naml", surahNameArabic: "النمل", startAyah: 56, arabicOpening: "فَمَا كَانَ جَوَابَ"),
  HizbMeta(hizbNumber: 40, juzNumber: 20, surahNumber: 28, surahName: "Al-Qasas", surahNameArabic: "القصص", startAyah: 51, arabicOpening: "وَلَقَدْ وَصَّلْنَا"),
  HizbMeta(hizbNumber: 41, juzNumber: 21, surahNumber: 29, surahName: "Al-'Ankabut", surahNameArabic: "العنكبوت", startAyah: 46, arabicOpening: "وَلَا تُجَادِلُوا"),
  HizbMeta(hizbNumber: 42, juzNumber: 21, surahNumber: 31, surahName: "Luqman", surahNameArabic: "لقمان", startAyah: 22, arabicOpening: "وَمَنْ يُسْلِمْ وَجْهَهُ"),
  HizbMeta(hizbNumber: 43, juzNumber: 22, surahNumber: 33, surahName: "Al-Ahzab", surahNameArabic: "الأحزاب", startAyah: 31, arabicOpening: "وَمَنْ يَقْنُتْ مِنْكُنَّ"),
  HizbMeta(hizbNumber: 44, juzNumber: 22, surahNumber: 34, surahName: "Saba", surahNameArabic: "سبإ", startAyah: 24, arabicOpening: "قُلْ مَنْ يَرْزُقُكُمْ"),
  HizbMeta(hizbNumber: 45, juzNumber: 23, surahNumber: 36, surahName: "Ya-Sin", surahNameArabic: "يس", startAyah: 28, arabicOpening: "وَمَا أَنْزَلْنَا"),
  HizbMeta(hizbNumber: 46, juzNumber: 23, surahNumber: 37, surahName: "As-Saffat", surahNameArabic: "الصافات", startAyah: 145, arabicOpening: "فَنَبَذْنَاهُ بِالْعَرَاءِ"),
  HizbMeta(hizbNumber: 47, juzNumber: 24, surahNumber: 39, surahName: "Az-Zumar", surahNameArabic: "الزمر", startAyah: 32, arabicOpening: "فَمَنْ أَظْلَمُ"),
  HizbMeta(hizbNumber: 48, juzNumber: 24, surahNumber: 40, surahName: "Ghafir", surahNameArabic: "غافر", startAyah: 41, arabicOpening: "وَيَا قَوْمِ مَا لِي"),
  HizbMeta(hizbNumber: 49, juzNumber: 25, surahNumber: 41, surahName: "Fussilat", surahNameArabic: "فصلت", startAyah: 47, arabicOpening: "إِلَيْهِ يُرَدُّ"),
  HizbMeta(hizbNumber: 50, juzNumber: 25, surahNumber: 43, surahName: "Az-Zukhruf", surahNameArabic: "الزخرف", startAyah: 24, arabicOpening: "قَالَ أَوَلَوْ جِئْتُكُمْ"),
  HizbMeta(hizbNumber: 51, juzNumber: 26, surahNumber: 46, surahName: "Al-Ahqaf", surahNameArabic: "الأحقاف", startAyah: 1, arabicOpening: "حم تَنْزِيلُ"),
  HizbMeta(hizbNumber: 52, juzNumber: 26, surahNumber: 48, surahName: "Al-Fath", surahNameArabic: "الفتح", startAyah: 18, arabicOpening: "لَقَدْ رَضِيَ اللَّهُ"),
  HizbMeta(hizbNumber: 53, juzNumber: 27, surahNumber: 51, surahName: "Adh-Dhariyat", surahNameArabic: "الذاريات", startAyah: 31, arabicOpening: "قَالَ فَمَا خَطْبُكُمْ"),
  HizbMeta(hizbNumber: 54, juzNumber: 27, surahNumber: 55, surahName: "Ar-Rahman", surahNameArabic: "الرحمن", startAyah: 1, arabicOpening: "الرَّحْمَنُ"),
  HizbMeta(hizbNumber: 55, juzNumber: 28, surahNumber: 58, surahName: "Al-Mujadila", surahNameArabic: "المجادلة", startAyah: 1, arabicOpening: "قَدْ سَمِعَ اللَّهُ"),
  HizbMeta(hizbNumber: 56, juzNumber: 28, surahNumber: 62, surahName: "Al-Jumu'ah", surahNameArabic: "الجمعة", startAyah: 1, arabicOpening: "يُسَبِّحُ لِلَّهِ"),
  HizbMeta(hizbNumber: 57, juzNumber: 29, surahNumber: 67, surahName: "Al-Mulk", surahNameArabic: "الملك", startAyah: 1, arabicOpening: "تَبَارَكَ الَّذِي"),
  HizbMeta(hizbNumber: 58, juzNumber: 29, surahNumber: 72, surahName: "Al-Jinn", surahNameArabic: "الجن", startAyah: 1, arabicOpening: "قُلْ أُوحِيَ إِلَيَّ"),
  HizbMeta(hizbNumber: 59, juzNumber: 30, surahNumber: 78, surahName: "An-Naba", surahNameArabic: "النبأ", startAyah: 1, arabicOpening: "عَمَّ يَتَسَاءَلُونَ"),
  HizbMeta(hizbNumber: 60, juzNumber: 30, surahNumber: 87, surahName: "Al-A'la", surahNameArabic: "الأعلى", startAyah: 1, arabicOpening: "سَبِّحِ اسْمَ رَبِّكَ"),
];

/// Helper to get the standard 604 Madani Mushaf page metadata
class QuranPageCatalog {
  static final List<PageMeta> _pages = _generatePages();

  static List<PageMeta> get allPages => _pages;

  static List<PageMeta> _generatePages() {
    final List<PageMeta> list = [];

    // Standard starting page references for the 114 Surahs in Madani Mushaf
    const Map<int, int> surahStartPages = {
      1: 1, 2: 2, 3: 50, 4: 77, 5: 106, 6: 128, 7: 151, 8: 177, 9: 187, 10: 208,
      11: 221, 12: 235, 13: 249, 14: 255, 15: 262, 16: 267, 17: 282, 18: 293,
      19: 305, 20: 312, 21: 322, 22: 332, 23: 342, 24: 350, 25: 359, 26: 367,
      27: 377, 28: 385, 29: 396, 30: 404, 31: 411, 32: 415, 33: 418, 34: 428,
      35: 434, 36: 440, 37: 446, 38: 453, 39: 458, 40: 467, 41: 477, 42: 483,
      43: 489, 44: 496, 45: 499, 46: 502, 47: 507, 48: 511, 49: 515, 50: 518,
      51: 520, 52: 523, 53: 526, 54: 528, 55: 531, 56: 534, 57: 537, 58: 542,
      59: 545, 60: 549, 61: 551, 62: 553, 63: 554, 64: 556, 65: 558, 66: 560,
      67: 562, 68: 564, 69: 566, 70: 568, 71: 570, 72: 572, 73: 574, 74: 575,
      75: 577, 76: 578, 77: 580, 78: 582, 79: 583, 80: 585, 81: 586, 82: 587,
      83: 587, 84: 589, 85: 590, 86: 591, 87: 591, 88: 592, 89: 593, 90: 594,
      91: 595, 92: 595, 93: 596, 94: 596, 95: 597, 96: 597, 97: 598, 98: 598,
      99: 599, 100: 599, 101: 600, 102: 600, 103: 601, 104: 601, 105: 601,
      106: 602, 107: 602, 108: 602, 109: 603, 110: 603, 111: 603, 112: 604,
      113: 604, 114: 604,
    };

    int currentSurah = 1;
    for (int p = 1; p <= 604; p++) {
      // Find surah that starts on or before page p
      for (int s = 114; s >= 1; s--) {
        if (surahStartPages[s] != null && surahStartPages[s]! <= p) {
          currentSurah = s;
          break;
        }
      }

      final surahMeta = kAllSurahs.firstWhere(
        (s) => s.number == currentSurah,
        orElse: () => kAllSurahs.first,
      );

      // Standard Juz mapping (~20 pages per Juz)
      final juzNum = ((p - 1) ~/ 20 + 1).clamp(1, 30);

      list.add(PageMeta(
        pageNumber: p,
        juzNumber: juzNum,
        surahNumber: currentSurah,
        surahName: surahMeta.englishName,
        surahNameArabic: surahMeta.name,
        startAyah: (p == surahStartPages[currentSurah]) ? 1 : 1,
      ));
    }

    return list;
  }
}
