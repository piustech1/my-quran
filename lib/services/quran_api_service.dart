import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ayah.dart';

class QuranApiService {
  static const String _primaryBaseUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1';
  static const String _fallbackBaseUrl =
      'https://raw.githubusercontent.com/fawazahmed0/quran-api/1';

  static const String defaultArabicEdition = 'ara-quranuthmanienc';
  static const String defaultEnglishEdition = 'eng-abdelhaleem';
  static const String defaultTransliterationEdition = 'ara-quran-la';

  /// Fetches all Ayahs for a given chapter (Surah).
  /// Checks local cache first; if missing, fetches from API and caches locally.
  Future<List<Ayah>> getChapterAyahs(int chapterNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cache_chapter_${chapterNumber}_v1';

    // 1. Try reading from local device cache
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final List<dynamic> list = jsonDecode(cached);
        return list.map((e) => Ayah.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {
        // Corrupted cache, will refetch
      }
    }

    // 2. Fetch Arabic text & English translation concurrently
    try {
      final responses = await Future.wait([
        _fetchEndpoint('/editions/$defaultArabicEdition/$chapterNumber.json'),
        _fetchEndpoint('/editions/$defaultEnglishEdition/$chapterNumber.json'),
      ]);

      final arabicJson = responses[0];
      final englishJson = responses[1];

      final List<dynamic> arabicVerses =
          arabicJson['chapter'] as List<dynamic>? ?? [];
      final List<dynamic> englishVerses =
          englishJson['chapter'] as List<dynamic>? ?? [];

      final List<Ayah> ayahs = [];
      for (int i = 0; i < arabicVerses.length; i++) {
        final a = arabicVerses[i] as Map<String, dynamic>;
        final Map<String, dynamic>? e =
            i < englishVerses.length ? englishVerses[i] as Map<String, dynamic> : null;

        ayahs.add(Ayah.fromJson(
          arabicJson: a,
          translationJson: e,
        ));
      }

      // Save to cache
      if (ayahs.isNotEmpty) {
        final cacheData = ayahs.map((a) => a.toMap()).toList();
        await prefs.setString(cacheKey, jsonEncode(cacheData));
      }

      return ayahs;
    } catch (e) {
      // If network fails and it's Surah 1 (Al-Fatiha), provide built-in fallback
      if (chapterNumber == 1) {
        return _getFallbackAlFatiha();
      }
      rethrow;
    }
  }

  /// Helper to fetch from primary CDN with fallback to GitHub Raw
  Future<Map<String, dynamic>> _fetchEndpoint(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('$_primaryBaseUrl$endpoint'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback to secondary source
    }

    final fallbackResponse = await http
        .get(Uri.parse('$_fallbackBaseUrl$endpoint'))
        .timeout(const Duration(seconds: 10));
    if (fallbackResponse.statusCode == 200) {
      return jsonDecode(fallbackResponse.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load Quran data for $endpoint');
  }

  /// Built-in fallback for Al-Fatiha in case the app is opened without internet
  List<Ayah> _getFallbackAlFatiha() {
    return [
      Ayah(
        chapter: 1,
        verse: 1,
        arabicText: "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ",
        translation: "In the name of God, the Lord of Mercy, the Giver of Mercy",
      ),
      Ayah(
        chapter: 1,
        verse: 2,
        arabicText: "ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَـٰلَمِینَ",
        translation: "Praise belongs to God, Lord of the Worlds",
      ),
      Ayah(
        chapter: 1,
        verse: 3,
        arabicText: "ٱلرَّحۡمَـٰنِ ٱلرَّحِیمِ",
        translation: "The Lord of Mercy, the Giver of Mercy",
      ),
      Ayah(
        chapter: 1,
        verse: 4,
        arabicText: "مَـٰلِكِ یَوۡمِ ٱلدِّینِ",
        translation: "Master of the Day of Judgement",
      ),
      Ayah(
        chapter: 1,
        verse: 5,
        arabicText: "إِیَّاكَ نَعۡبُدُ وَإِیَّاكَ نَسۡتَعِینُ",
        translation: "It is You we worship; it is You we ask for help",
      ),
      Ayah(
        chapter: 1,
        verse: 6,
        arabicText: "ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِیمَ",
        translation: "Guide us to the straight path",
      ),
      Ayah(
        chapter: 1,
        verse: 7,
        arabicText:
            "صِرَٰطَ ٱلَّذِینَ أَنۡعَمۡتَ عَلَیۡهِمۡ غَیۡرِ ٱلۡمَغۡضُوبِ عَلَیۡهِمۡ وَلَا ٱلضَّآلِّینَ",
        translation:
            "The path of those You have blessed, not of those against whom there is anger, nor of those who are misguided",
      ),
    ];
  }
}
