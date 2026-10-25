import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_quran/models/islamic_video_item.dart';
import 'package:my_quran/services/islamic_video_service.dart';

void main() {
  group('IslamicVideoItem Model Tests', () {
    test('Correctly parses IslamHouse API v3 JSON format', () {
      final sampleJson = {
        'id': 2846462,
        'source_id': 2846462,
        'title': 'How to perform Umrah',
        'description': 'A clip explaining the rituals of Umrah step by step.',
        'image': 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2846462.jpg',
        'source_language': 'en',
        'prepared_by': [
          {
            'id': 2828466,
            'title': 'Sheikh Ahmad',
            'type': 'author',
          }
        ],
        'attachments': [
          {
            'order': 0,
            'size': '190.52 MB',
            'extension_type': 'MP4',
            'url': 'https://d1.islamhouse.com/data/en/ih_videos/mp4/single/en-description-of-the-umrah.mp4',
          }
        ],
      };

      final item = IslamicVideoItem.fromJson(sampleJson, defaultLang: 'en');

      expect(item.id, '2846462');
      expect(item.title, 'How to perform Umrah');
      expect(item.videoUrl, 'https://d1.islamhouse.com/data/en/ih_videos/mp4/single/en-description-of-the-umrah.mp4');
      expect(item.imageUrl, 'https://d1.islamhouse.com/data/en/ih_videos/pic/pic_index/2846462.jpg');
      expect(item.author, 'Sheikh Ahmad');
      expect(item.size, '190.52 MB');
      expect(item.tags, contains('Hajj & Umrah'));
      expect(item.likesCount, greaterThan(0));
      expect(item.isLiked, false);
    });

    test('toJson serialization produces valid representation', () {
      final item = IslamicVideoItem(
        id: '999',
        title: 'Test Video',
        description: 'Test Description',
        videoUrl: 'https://example.com/video.mp4',
        imageUrl: 'https://example.com/image.jpg',
        author: 'Test Scholar',
      );

      final map = item.toJson();
      expect(map['id'], '999');
      expect(map['title'], 'Test Video');
      expect(map['videoUrl'], 'https://example.com/video.mp4');
      expect(map['author'], 'Test Scholar');
    });
  });

  group('IslamicVideoService Tests', () {
    setUp(() {
      IslamicVideoService().clearCache();
    });

    test('fetchVideos parses response from mocked IslamHouse client', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/main/videos/en/showall/1/20/json'));
        final responseData = {
          'data': [
            {
              'id': 101,
              'title': 'How to Pray Salah',
              'description': 'Prayer tutorial',
              'image': 'https://d1.islamhouse.com/img1.jpg',
              'source_language': 'en',
              'attachments': [
                {
                  'extension_type': 'MP4',
                  'url': 'https://d1.islamhouse.com/prayer.mp4',
                }
              ],
            }
          ]
        };
        return http.Response(json.encode(responseData), 200, headers: {'content-type': 'application/json'});
      });

      final service = IslamicVideoService();
      final videos = await service.fetchVideos(language: 'en', page: 1, limit: 20, client: mockClient);

      expect(videos.length, 1);
      expect(videos.first.title, 'How to Pray Salah');
      expect(videos.first.videoUrl, 'https://d1.islamhouse.com/prayer.mp4');
    });

    test('Returns curated fallback videos when API request fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = IslamicVideoService();
      final fallbackVideos = await service.fetchVideos(language: 'en', page: 1, limit: 20, client: mockClient);

      expect(fallbackVideos.isNotEmpty, true);
      expect(fallbackVideos.first.videoUrl.isNotEmpty, true);
      expect(fallbackVideos.any((v) => v.title.contains('Umrah') || v.title.contains('Prayer')), true);
    });

    test('Provides curated fallback videos for different languages', () {
      final service = IslamicVideoService();

      final arVideos = service.getCuratedFallbackVideos('ar');
      expect(arVideos.isNotEmpty, true);
      expect(arVideos.first.language, 'ar');

      final urVideos = service.getCuratedFallbackVideos('ur');
      expect(urVideos.isNotEmpty, true);
      expect(urVideos.first.language, 'ur');

      final enVideos = service.getCuratedFallbackVideos('en');
      expect(enVideos.isNotEmpty, true);
      expect(enVideos.first.language, 'en');
    });
  });
}
