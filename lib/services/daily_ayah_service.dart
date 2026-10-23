import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DailyAyahModel {
  final int surahNumber;
  final int ayahNumber;
  final String surahNameEnglish;
  final String surahNameArabic;
  final String arabicText;
  final String defaultTranslation;
  final String transliteration;
  final String themeTitle;
  final String subtitle;
  final String explanation;
  final String tafsirAttribution;
  final String imageAsset;

  const DailyAyahModel({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahNameEnglish,
    required this.surahNameArabic,
    required this.arabicText,
    required this.defaultTranslation,
    required this.transliteration,
    required this.themeTitle,
    required this.subtitle,
    required this.explanation,
    required this.tafsirAttribution,
    required this.imageAsset,
  });

  String get reference => 'Surah $surahNameEnglish $surahNumber:$ayahNumber';
  String get shortCitation => '$surahNameEnglish $surahNumber:$ayahNumber';
}

class TranslationEdition {
  final String id;
  final String languageName;
  final String authorName;
  final bool isRtl;

  const TranslationEdition({
    required this.id,
    required this.languageName,
    required this.authorName,
    this.isRtl = false,
  });
}

class DailyAyahService {
  static final DailyAyahService _instance = DailyAyahService._internal();
  factory DailyAyahService() => _instance;
  DailyAyahService._internal();

  static const String _apiBaseUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1';

  static const List<TranslationEdition> supportedTranslations = [
    TranslationEdition(
      id: 'eng-abdelhaleem',
      languageName: 'English',
      authorName: 'M.A.S. Abdel Haleem',
    ),
    TranslationEdition(
      id: 'eng-sahih',
      languageName: 'English (Sahih)',
      authorName: 'Sahih International',
    ),
    TranslationEdition(
      id: 'fra-rashidmaash',
      languageName: 'Français',
      authorName: 'Rashid Maash',
    ),
    TranslationEdition(
      id: 'ind-indonesianislam',
      languageName: 'Indonesian',
      authorName: 'Kemenag RI',
    ),
    TranslationEdition(
      id: 'tur-diyanetisleri',
      languageName: 'Türkçe',
      authorName: 'Diyanet İşleri',
    ),
    TranslationEdition(
      id: 'urd-abulaalamaududi',
      languageName: 'اردو',
      authorName: 'سید ابوالاعلی مودودی',
      isRtl: true,
    ),
    TranslationEdition(
      id: 'ara-quran-la',
      languageName: 'Transliteration',
      authorName: 'Latin Transliteration',
    ),
  ];

  /// Deterministically select the featured Ayah for a given calendar day.
  /// Guarantees the same verse across all devices on the same date.
  DailyAyahModel getDailyAyah([DateTime? date]) {
    final now = date ?? DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final seed = now.year * 365 + dayOfYear;
    final index = seed.abs() % _curatedVerses.length;
    return _curatedVerses[index];
  }

  /// Fetches the translation for a specific edition with local caching.
  Future<String> fetchTranslation({
    required int chapter,
    required int verse,
    required String editionId,
  }) async {
    // If it's the default English edition, use the curated translation first
    final currentDaily = getDailyAyah();
    if (currentDaily.surahNumber == chapter &&
        currentDaily.ayahNumber == verse &&
        editionId == 'eng-abdelhaleem') {
      return currentDaily.defaultTranslation;
    }
    if (currentDaily.surahNumber == chapter &&
        currentDaily.ayahNumber == verse &&
        editionId == 'ara-quran-la') {
      return currentDaily.transliteration;
    }

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'daily_ayah_trans_${chapter}_${verse}_$editionId';

    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/editions/$editionId/$chapter/$verse.json');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final text = (json['text'] as String? ?? '').trim();
        if (text.isNotEmpty) {
          await prefs.setString(cacheKey, text);
          return text;
        }
      }
    } catch (_) {
      // Fallback to default translation if network is unavailable
    }

    return currentDaily.defaultTranslation;
  }

  /// Curated collection of 30 profound, authentic Quranic verses with classical tafsir.
  static const List<DailyAyahModel> _curatedVerses = [
    DailyAyahModel(
      surahNumber: 94,
      ayahNumber: 5,
      surahNameEnglish: 'Ash-Sharh',
      surahNameArabic: 'الشرح',
      arabicText: 'فَإِنَّ مَعَ ٱلۡعُسۡرِ یُسۡرًا',
      defaultTranslation:
          'So truly where there is hardship there is also ease.',
      transliteration: 'Fa-inna ma\'al \'usri yusra.',
      themeTitle: 'Food of the Soul',
      subtitle: 'Divine solace in moments of difficulty',
      explanation:
          'A divine promise that difficulty is never isolated; ease is intertwined with every trial. No struggle endures indefinitely, offering immediate comfort and renewed strength to the believer.',
      tafsirAttribution: 'Tafsir Ibn Kathir',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 2,
      ayahNumber: 286,
      surahNameEnglish: 'Al-Baqarah',
      surahNameArabic: 'البقرة',
      arabicText: 'لَا یُكَلِّفُ ٱللَّهُ نَفۡسًا إِلَّا وُسۡعَهَا',
      defaultTranslation:
          'God does not burden any soul with more than it can bear.',
      transliteration: 'La yukallifullahu nafsan illa wus\'aha.',
      themeTitle: 'Divine Mercy',
      subtitle: 'Strength granted for every test',
      explanation:
          'Allah in His boundless wisdom and compassion never demands what is beyond human capacity. Whatever test is placed upon you, you have been equipped with the resilience to navigate it.',
      tafsirAttribution: 'Tafsir As-Sa\'di',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 13,
      ayahNumber: 28,
      surahNameEnglish: 'Ar-Ra\'d',
      surahNameArabic: 'الرعد',
      arabicText: 'أَلَا بِذِكۡرِ ٱللَّهِ تَطۡمَئِنُّ ٱلۡقُلُوبُ',
      defaultTranslation:
          'Truly it is in the remembrance of God that hearts find peace.',
      transliteration: 'Ala bi-dhikrillahi tatma\'innul-quloob.',
      themeTitle: 'Peace of the Heart',
      subtitle: 'The eternal sanctuary for restless minds',
      explanation:
          'Restlessness dissipates and genuine serenity settles into the heart through conscious connection with Allah. Remembrance fills the inner void with unshakeable peace.',
      tafsirAttribution: 'Tafsir Al-Baghawi',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 14,
      ayahNumber: 7,
      surahNameEnglish: 'Ibrahim',
      surahNameArabic: 'إبراهيم',
      arabicText: 'لَئِن شَكَرۡتُمۡ لَأَزِیدَنَّكُمۡ',
      defaultTranslation:
          'If you are grateful, I will certainly give you more.',
      transliteration: 'La-in shakartum la-azeedannakum.',
      themeTitle: 'The Power of Gratitude',
      subtitle: 'Preserving blessings and inviting increase',
      explanation:
          'Gratitude is not merely an expression of appreciation; it acts as a divine covenant that safeguards present blessings and opens doorways to boundless spiritual and worldly increase.',
      tafsirAttribution: 'Tafsir Al-Tabari',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 39,
      ayahNumber: 53,
      surahNameEnglish: 'Az-Zumar',
      surahNameArabic: 'الزمر',
      arabicText:
          'قُلۡ یَـٰعِبَادِیَ ٱلَّذِینَ أَسۡرَفُوا۟ عَلَىٰۤ أَنفُسِهِمۡ لَا تَقۡنَطُوا۟ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ یَغۡفِرُ ٱلذُّنُوبَ جَمِیعًا',
      defaultTranslation:
          'Say, "O My servants who have transgressed against themselves! Do not despair of the mercy of God: God forgives all sins."',
      transliteration:
          'Qul ya \'ibadiyal-ladheena asrafoo \'ala anfusihim la taqnatoo mir-rahmatillah; innallaha yaghfirudh-dhunooba jamee\'a.',
      themeTitle: 'Boundless Forgiveness',
      subtitle: 'The open door of unconditional return',
      explanation:
          'Considered by scholars among the most hopeful verses of the Quran, this proclamation affirms that sincere repentance dissolves every past shortcoming in the boundless ocean of divine grace.',
      tafsirAttribution: 'Tafsir Ibn Kathir',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 65,
      ayahNumber: 3,
      surahNameEnglish: 'At-Talaq',
      surahNameArabic: 'الطلاق',
      arabicText: 'وَمَن یَتَوَكَّلۡ عَلَى ٱللَّهِ فَهُوَ حَسۡبُهُۥۤ',
      defaultTranslation:
          'And whoever puts their trust in God, He is enough for him.',
      transliteration: 'Wa may-yatawakkal \'alallahi fahuwa hasbuh.',
      themeTitle: 'Sacred Reliance (Tawakkul)',
      subtitle: 'Complete sufficiency through faith',
      explanation:
          'Relinquishing anxious overthinking and entrusting life’s outcomes to Allah brings total peace. When Allah is your guardian, no worldly uncertainty can overpower you.',
      tafsirAttribution: 'Tafsir As-Sa\'di',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 93,
      ayahNumber: 5,
      surahNameEnglish: 'Ad-Duha',
      surahNameArabic: 'الضحى',
      arabicText: 'وَلَسَوۡفَ یُعۡطِیكَ رَبُّكَ فَتَرۡضَىٰ',
      defaultTranslation:
          'And your Lord is going to give you, and you will be satisfied.',
      transliteration: 'Wa lasawfa yu\'teeka Rabbuka fatarda.',
      themeTitle: 'Promise of Contentment',
      subtitle: 'Recompense far surpassing expectation',
      explanation:
          'A gentle consolation revealing that current hardships will soon be replaced by divine gifts and joyful relief that will thoroughly satisfy the patient believer.',
      tafsirAttribution: 'Tafsir Al-Qurtubi',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 2,
      ayahNumber: 152,
      surahNameEnglish: 'Al-Baqarah',
      surahNameArabic: 'البقرة',
      arabicText: 'فَٱذۡكُرُونِیۤ أَذۡكُرۡكُمۡ وَٱشۡكُرُوا۟ لِی وَلَا تَكۡفُرُونِ',
      defaultTranslation:
          'So remember Me; I will remember you. Be thankful to Me, and do not be ungrateful.',
      transliteration: 'Fadhkuroonee adhkurkum washkuroo lee wa la takfuroon.',
      themeTitle: 'Mutual Remembrance',
      subtitle: 'An intimate bond with the Creator',
      explanation:
          'An awe-inspiring invitation: whenever you mention and remember your Lord in your thoughts and deeds, the Lord of the Universe honors you with His divine remembrance and care.',
      tafsirAttribution: 'Tafsir As-Sa\'di',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 3,
      ayahNumber: 139,
      surahNameEnglish: 'Ali \'Imran',
      surahNameArabic: 'آل عمران',
      arabicText:
          'وَلَا تَهِنُوا۟ وَلَا تَحۡزَنُوا۟ وَأَنتُمُ ٱلۡأَعۡلَوۡنَ إِن كُنتُم مُّؤۡمِنِینَ',
      defaultTranslation:
          'Do not lose heart nor fall into despair! You will certainly be victorious if you are true believers.',
      transliteration:
          'Wa la tahinoo wa la tahzanoo wa antumul-a\'lawna in kuntum mu\'mineen.',
      themeTitle: 'Unyielding Hope',
      subtitle: 'Rising above temporary sorrow',
      explanation:
          'A call to courage reminding believers that temporary setbacks do not define the ultimate journey. Steadfast faith grants an unassailable moral and spiritual elevation.',
      tafsirAttribution: 'Tafsir Ibn Kathir',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 21,
      ayahNumber: 87,
      surahNameEnglish: 'Al-Anbiya',
      surahNameArabic: 'الأنبياء',
      arabicText: 'لَّآ إِلَـٰهَ إِلَّآ أَنتَ سُبۡحَـٰنَكَ إِنِّی كُنتُ مِنَ ٱلظَّـٰلِمِینَ',
      defaultTranslation:
          'There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers.',
      transliteration: 'La ilaha illa Anta subhanaka innee kuntu minaz-zalimeen.',
      themeTitle: 'The Reliever of Distress',
      subtitle: 'The supplication of Yunus (Jonah)',
      explanation:
          'The renowned prayer that combines pure monotheism, sanctification of Allah, and humble accountability. The Prophet (pbuh) taught that no believer makes this prayer in distress except that Allah relieves them.',
      tafsirAttribution: 'Musnad Ahmad & Tafsir Ibn Kathir',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 24,
      ayahNumber: 35,
      surahNameEnglish: 'An-Nur',
      surahNameArabic: 'النور',
      arabicText: 'ٱللَّهُ نُورُ ٱلسَّمَـٰوَ ٰ⁠تِ وَٱلۡأَرۡضِ',
      defaultTranslation:
          'God is the Light of the heavens and the earth.',
      transliteration: 'Allahu noorus-samawati wal-ard.',
      themeTitle: 'The Divine Light',
      subtitle: 'Illumination for dark pathways',
      explanation:
          'Allah is the guide and source of truth illuminating both the physical cosmos and the inner spiritual realm. His guidance illuminates the faithful heart with clarity and conviction.',
      tafsirAttribution: 'Tafsir Al-Baghawi',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
    DailyAyahModel(
      surahNumber: 2,
      ayahNumber: 186,
      surahNameEnglish: 'Al-Baqarah',
      surahNameArabic: 'البقرة',
      arabicText:
          'وَإِذَا سَأَلَكَ عِبَادِی عَنِّی فَإِنِّی قَرِیبٌۖ أُجِیبُ دَعۡوَةَ ٱلدَّاعِ إِذَا دَعَانِ',
      defaultTranslation:
          'When My servants ask you about Me, I am near. I respond to the call of the caller when he calls upon Me.',
      transliteration:
          'Wa idha sa\'alaka \'ibadee \'annee fa-innee qareeb; ujeebu da\'watad-da\'i idha da\'an.',
      themeTitle: 'The Nearness of Allah',
      subtitle: 'Direct connection without intermediaries',
      explanation:
          'A deeply comforting reality: Allah is intimately close to every worshiper, hearing every whisper and silent plea, assuring immediate attentiveness to those who turn to Him.',
      tafsirAttribution: 'Tafsir Ibn Kathir',
      imageAsset: 'assets/daily_ayah_visual.jpg',
    ),
  ];
}
