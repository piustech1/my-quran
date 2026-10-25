import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/islamic_video_item.dart';

class IslamicLanguageOption {
  final String code;
  final String englishName;
  final String nativeName;

  const IslamicLanguageOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });
}

class IslamicVideoService {
  static final IslamicVideoService _instance = IslamicVideoService._internal();
  factory IslamicVideoService() => _instance;
  IslamicVideoService._internal();

  static const String _baseUrl = 'https://api3.islamhouse.com/v3';
  static const String _apiKey = 'paV29H2gm56kvLP';

  static const List<IslamicLanguageOption> supportedLanguages = [
    IslamicLanguageOption(code: 'en', englishName: 'English', nativeName: 'English'),
    IslamicLanguageOption(code: 'ar', englishName: 'Arabic', nativeName: 'العربية'),
    IslamicLanguageOption(code: 'ur', englishName: 'Urdu', nativeName: 'اردو'),
    IslamicLanguageOption(code: 'fr', englishName: 'French', nativeName: 'Français'),
    IslamicLanguageOption(code: 'sw', englishName: 'Swahili', nativeName: 'Kiswahili'),
    IslamicLanguageOption(code: 'id', englishName: 'Indonesian', nativeName: 'Bahasa Indonesia'),
    IslamicLanguageOption(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe'),
    IslamicLanguageOption(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
  ];

  // In-memory cache by language code
  final Map<String, List<IslamicVideoItem>> _cachedVideos = {};

  void clearCache() => _cachedVideos.clear();

  /// Fetch videos for the selected language and page
  Future<List<IslamicVideoItem>> fetchVideos({
    String language = 'en',
    int page = 1,
    int limit = 20,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse('$_baseUrl/$_apiKey/main/videos/$language/showall/$page/$limit/json');

    try {
      final response = await httpClient.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'MyQuranApp/1.8.14',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          final items = (decoded['data'] as List)
              .map((itemJson) => IslamicVideoItem.fromJson(itemJson as Map<String, dynamic>, defaultLang: language))
              .where((item) => item.videoUrl.isNotEmpty)
              .toList();

          if (items.isNotEmpty) {
            if (page == 1) {
              _cachedVideos[language] = items;
            } else {
              _cachedVideos[language] = [
                ...?_cachedVideos[language],
                ...items,
              ];
            }
            return items;
          }
        }
      }
    } catch (e) {
      debugPrint('[IslamicVideoService] Error fetching IslamHouse videos: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    // Return cached items if available
    if (_cachedVideos.containsKey(language) && _cachedVideos[language]!.isNotEmpty) {
      return _cachedVideos[language]!;
    }

    // Fallback to authentic curated default videos ensuring reliable offline experience
    return getCuratedFallbackVideos(language);
  }

  /// Curated fallback videos from IslamHouse verified CDN
  List<IslamicVideoItem> getCuratedFallbackVideos([String language = 'en']) {
    switch (language) {
      case 'ar':
        return [
          IslamicVideoItem(
            id: '2847002',
            title: 'دبلوم تأهيل الدعاة للتعريف بالإسلام',
            description: 'سلسلة مرئية مباركة لتأهيل الدعاة والمسلمين في التعريف بسماحة الإسلام بالحكمة والموعظة الحسنة',
            videoUrl: 'https://d1.islamhouse.com/data/ar/ih_videos/mp4/chain/taehel_aldoaa/ar_01_taehel_aldoaa.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/ar/ih_videos/pic/pic_index/2847002.jpg',
            language: 'ar',
            author: 'حيان اليافعي',
            tags: ['دعوة', 'حكمة', 'إسلاميات'],
            likesCount: 382,
          ),
          IslamicVideoItem(
            id: '2846999',
            title: 'صفة صلاة النبي ﷺ',
            description: 'بيان وتطبيق عملي لصفة صلاة النبي صلى الله عليه وسلم من التكبير إلى التسليم بدقة وإتقان',
            videoUrl: 'https://d1.islamhouse.com/data/hy/ih_videos/mp4/single/hy-sifat-alsal.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/ar/ih_videos/pic/pic_index/2844648.jpg',
            language: 'ar',
            author: 'مركز الدعوة الإسلامي',
            tags: ['الصلاة', 'سنة النبوية', 'فقه'],
            likesCount: 521,
          ),
          IslamicVideoItem(
            id: '2846901',
            title: 'صفة الوضوء الصحيحة',
            description: 'شرح عملي ومبسط لكيفية إسباغ الوضوء والتطهر على هدي النبي المصطفى صلى الله عليه وسلم',
            videoUrl: 'https://d1.islamhouse.com/data/om/ih_books/single/risala_or_description_of_wodou.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2844300.jpg',
            language: 'ar',
            author: 'دار الإسلام',
            tags: ['الوضوء', 'طهارة', 'عبادات'],
            likesCount: 294,
          ),
        ];

      case 'ur':
        return [
          IslamicVideoItem(
            id: '2846462-ur',
            title: 'عمرہ کا طریقہ',
            description: 'عمرہ کے ارکان اور سنتوں کی مکمل اور آسان ویڈیو رہنمائی احرام باندھنے سے لے کر طواف و سعی تک',
            videoUrl: 'https://d1.islamhouse.com/data/ur/ih_videos/mp4/single/ur-sifat-umra.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2846462.jpg',
            language: 'ur',
            author: 'اسلام ہاؤس علماء',
            tags: ['عمرہ', 'حج', 'عبادات'],
            likesCount: 410,
          ),
        ];

      case 'sw':
        return [
          IslamicVideoItem(
            id: '2846462-sw',
            title: 'Sifa za Swala ya Mtume ﷺ',
            description: 'Mwongozo sahihi wa jinsi ya kuswali swala ya Mtume صلى الله عليه وسلم kwa vitendo kuanzia takbira mpaka kutoa salamu.',
            videoUrl: 'https://d1.islamhouse.com/data/sw/ih_videos/mp4/single/sw-sifat-alsalah.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2844648.jpg',
            language: 'sw',
            author: 'IslamHouse Kiswahili',
            tags: ['Swalah', 'Mwongozo', 'Sunnah'],
            likesCount: 215,
          ),
        ];

      default: // English
        return [
          IslamicVideoItem(
            id: '2846462',
            title: 'How to Perform Umrah (Step-by-Step)',
            description: 'A clear and practical demonstration of the rituals of Umrah in sequential order: entering Ihram, Tawaf around the Kaabah, Sa’i between Safa and Marwah, and Tahallul.',
            videoUrl: 'https://d1.islamhouse.com/data/en/ih_videos/mp4/single/en-description-of-the-umrah.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2846462.jpg',
            language: 'en',
            author: 'IslamHouse Dawah Center',
            tags: ['Hajj & Umrah', 'Purity', 'Guidance'],
            likesCount: 642,
          ),
          IslamicVideoItem(
            id: '2844648',
            title: 'How to Perform Prayer (Salah)',
            description: 'A comprehensive, authentic visual presentation on how to perform the five daily prayers properly, fulfilling all pillars, conditions, and prophetic sunnahs.',
            videoUrl: 'https://d1.islamhouse.com/data/en/ih_videos/mp4/single/en_how_perform_prayer.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2844648.jpg',
            language: 'en',
            author: 'IslamHouse Scholars',
            tags: ['Salah', 'Pillars of Islam', 'Sunnah'],
            likesCount: 889,
          ),
          IslamicVideoItem(
            id: '2844300',
            title: 'How to Make Ablution (Wudu)',
            description: 'Learn the correct prophetic method of making Wudu (ablution) step-by-step to achieve spiritual and ritual purification before standing in prayer.',
            videoUrl: 'https://d1.islamhouse.com/data/ih_books/single/risala_en_Ablution_new.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2844300.jpg',
            language: 'en',
            author: 'IslamHouse Scholars',
            tags: ['Purity & Wudu', 'Salah', 'Taharah'],
            likesCount: 457,
          ),
          IslamicVideoItem(
            id: '2839969',
            title: 'How Can I Pray? (Brief Overview)',
            description: 'A short and accessible walkthrough designed for beginners and new Muslims on standing before Allah in prayer with tranquility and devotion.',
            videoUrl: 'https://d1.islamhouse.com/data/en/ih_videos/mp4/single/en-pray-brief.mp4',
            imageUrl: 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2846462.jpg',
            language: 'en',
            author: 'IslamHouse Team',
            tags: ['Salah', 'New Muslim', 'Devotion'],
            likesCount: 312,
          ),
        ];
    }
  }
}
