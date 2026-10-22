class JuzMeta {
  final int number;
  final String startSurahName;
  final int startSurahNumber;
  final int startAyah;
  final String arabicName;

  const JuzMeta({
    required this.number,
    required this.startSurahName,
    required this.startSurahNumber,
    required this.startAyah,
    required this.arabicName,
  });
}

const List<JuzMeta> kAllJuzs = [
  JuzMeta(number: 1, startSurahName: "Al-Fatiha", startSurahNumber: 1, startAyah: 1, arabicName: "الم"),
  JuzMeta(number: 2, startSurahName: "Al-Baqarah", startSurahNumber: 2, startAyah: 142, arabicName: "سَيَقُولُ"),
  JuzMeta(number: 3, startSurahName: "Al-Baqarah", startSurahNumber: 2, startAyah: 253, arabicName: "تِلْكَ الرُّسُلُ"),
  JuzMeta(number: 4, startSurahName: "Ali 'Imran", startSurahNumber: 3, startAyah: 93, arabicName: "لَنْ تَنَالُوا"),
  JuzMeta(number: 5, startSurahName: "An-Nisa", startSurahNumber: 4, startAyah: 24, arabicName: "وَالْمُحْصَنَاتُ"),
  JuzMeta(number: 6, startSurahName: "An-Nisa", startSurahNumber: 4, startAyah: 148, arabicName: "لَا يُحِبُّ اللَّهُ"),
  JuzMeta(number: 7, startSurahName: "Al-Ma'idah", startSurahNumber: 5, startAyah: 82, arabicName: "وَإِذَا سَمِعُوا"),
  JuzMeta(number: 8, startSurahName: "Al-An'am", startSurahNumber: 6, startAyah: 111, arabicName: "وَلَوْ أَنَّنَا"),
  JuzMeta(number: 9, startSurahName: "Al-A'raf", startSurahNumber: 7, startAyah: 88, arabicName: "قَالَ الْمَلَأُ"),
  JuzMeta(number: 10, startSurahName: "Al-Anfal", startSurahNumber: 8, startAyah: 41, arabicName: "وَاعْلَمُوا"),
  JuzMeta(number: 11, startSurahName: "At-Tawbah", startSurahNumber: 9, startAyah: 93, arabicName: "يَعْتَذِرُونَ"),
  JuzMeta(number: 12, startSurahName: "Hud", startSurahNumber: 11, startAyah: 6, arabicName: "وَمَا مِنْ دَابَّةٍ"),
  JuzMeta(number: 13, startSurahName: "Yusuf", startSurahNumber: 12, startAyah: 53, arabicName: "وَمَا أُبَرِّئُ"),
  JuzMeta(number: 14, startSurahName: "Al-Hijr", startSurahNumber: 15, startAyah: 1, arabicName: "رُبَمَا"),
  JuzMeta(number: 15, startSurahName: "Al-Isra", startSurahNumber: 17, startAyah: 1, arabicName: "سُبْحَانَ الَّذِي"),
  JuzMeta(number: 16, startSurahName: "Al-Kahf", startSurahNumber: 18, startAyah: 75, arabicName: "قَالَ أَلَمْ"),
  JuzMeta(number: 17, startSurahName: "Al-Anbiya", startSurahNumber: 21, startAyah: 1, arabicName: "اقْتَرَبَ"),
  JuzMeta(number: 18, startSurahName: "Al-Mu'minun", startSurahNumber: 23, startAyah: 1, arabicName: "قَدْ أَفْلَحَ"),
  JuzMeta(number: 19, startSurahName: "Al-Furqan", startSurahNumber: 25, startAyah: 21, arabicName: "وَقَالَ الَّذِينَ"),
  JuzMeta(number: 20, startSurahName: "An-Naml", startSurahNumber: 27, startAyah: 56, arabicName: "فَمَا كَانَ"),
  JuzMeta(number: 21, startSurahName: "Al-'Ankabut", startSurahNumber: 29, startAyah: 46, arabicName: "وَلَا تُجَادِلُوا"),
  JuzMeta(number: 22, startSurahName: "Al-Ahzab", startSurahNumber: 33, startAyah: 31, arabicName: "وَمَنْ يَقْنُتْ"),
  JuzMeta(number: 23, startSurahName: "Ya-Sin", startSurahNumber: 36, startAyah: 28, arabicName: "وَمَا أَنْزَلْنَا"),
  JuzMeta(number: 24, startSurahName: "Az-Zumar", startSurahNumber: 39, startAyah: 32, arabicName: "فَمَنْ أَظْلَمُ"),
  JuzMeta(number: 25, startSurahName: "Fussilat", startSurahNumber: 41, startAyah: 47, arabicName: "إِلَيْهِ يُرَدُّ"),
  JuzMeta(number: 26, startSurahName: "Al-Ahqaf", startSurahNumber: 46, startAyah: 1, arabicName: "حم"),
  JuzMeta(number: 27, startSurahName: "Adh-Dhariyat", startSurahNumber: 51, startAyah: 31, arabicName: "قَالَ فَمَا خَطْبُكُمْ"),
  JuzMeta(number: 28, startSurahName: "Al-Mujadila", startSurahNumber: 58, startAyah: 1, arabicName: "قَدْ سَمِعَ اللَّهُ"),
  JuzMeta(number: 29, startSurahName: "Al-Mulk", startSurahNumber: 67, startAyah: 1, arabicName: "تَبَارَكَ الَّذِي"),
  JuzMeta(number: 30, startSurahName: "An-Naba", startSurahNumber: 78, startAyah: 1, arabicName: "عَمَّ"),
];
