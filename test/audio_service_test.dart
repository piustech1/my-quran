import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/constants/surah_data.dart';
import 'package:my_quran/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranAudioService & Surah Progression Tests', () {
    final audioService = QuranAudioService();

    test('QuranAudioService provides 3 master reciters with valid assets', () {
      expect(QuranAudioService.availableReciters.length, 3);
      expect(audioService.selectedReciter.id, 'Alafasy_128kbps');
      expect(audioService.selectedReciter.name, contains('Mishary'));
    });

    test('Ayah playback progress notifier is initialized and reactive', () {
      expect(audioService.ayahPlaybackProgress.value, 0.0);
      audioService.ayahPlaybackProgress.value = 0.45;
      expect(audioService.ayahPlaybackProgress.value, 0.45);
      audioService.ayahPlaybackProgress.value = 0.0;
    });

    test('EveryAyah audio URLs are constructed with proper zero-padding', () {
      final url1 = audioService.getAyahAudioUrl(1, 1);
      expect(url1, 'https://everyayah.com/data/Alafasy_128kbps/001001.mp3');

      final url2 = audioService.getAyahAudioUrl(114, 6);
      expect(url2, 'https://everyayah.com/data/Alafasy_128kbps/114006.mp3');
    });

    test('kAllSurahs contains accurate verse count metadata for auto-progression', () {
      final fatiha = kAllSurahs.firstWhere((s) => s.number == 1);
      expect(fatiha.numberOfAyahs, 7);

      final baqarah = kAllSurahs.firstWhere((s) => s.number == 2);
      expect(baqarah.numberOfAyahs, 286);

      final nas = kAllSurahs.firstWhere((s) => s.number == 114);
      expect(nas.numberOfAyahs, 6);
    });
  });
}
