import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../constants/surah_data.dart';

class Reciter {
  final String id;
  final String name;
  final String description;
  final String imageAsset;

  const Reciter({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
  });
}

class QuranAudioService {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal() {
    _initAudioPlayer();
    _initTts();
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  FlutterTts? _tts;

  static const List<Reciter> availableReciters = [
    Reciter(
      id: 'Alafasy_128kbps',
      name: 'Mishary Rashid Alafasy',
      description: 'Clear, modern Tajweed pronunciation',
      imageAsset: 'assets/reciters/alafasy.jpg',
    ),
    Reciter(
      id: 'Abdul_Basit_Murattal_192kbps',
      name: 'Abdul Basit Murattal',
      description: 'Legendary classical Egyptian master',
      imageAsset: 'assets/reciters/basit.jpg',
    ),
    Reciter(
      id: 'Abu_Bakr_Ash-Shaatree_128kbps',
      name: 'Abu Bakr Ash-Shatri',
      description: 'Warm, melodious and heartfelt',
      imageAsset: 'assets/reciters/shatri.jpg',
    ),
  ];

  late final ValueNotifier<Reciter> selectedReciterNotifier =
      ValueNotifier<Reciter>(availableReciters[0]);
  Reciter get selectedReciter => selectedReciterNotifier.value;

  final ValueNotifier<int?> currentPlayingAyah = ValueNotifier<int?>(null);
  final ValueNotifier<int?> currentPlayingSurah = ValueNotifier<int?>(null);
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> ayahPlaybackProgress = ValueNotifier<double>(0.0);

  int _maxVersesInCurrentSurah = 7;
  bool autoPlayNext = true;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();
      await _tts?.setLanguage('en-US');
      await _tts?.setSpeechRate(0.48);
      await _tts?.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS initialization notice: $e');
    }
  }

  /// Announces the name of the Surah before reciting its first Ayah
  Future<void> announceSurah(String surahName) async {
    try {
      if (_tts == null) {
        await _initTts();
      }
      await _tts?.stop();
      await _tts?.speak('Surah $surahName');
      await Future.delayed(const Duration(milliseconds: 1400));
    } catch (e) {
      debugPrint('Error speaking Surah name: $e');
    }
  }

  void _initAudioPlayer() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;
      isLoadingNotifier.value =
          state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading;

      if (state.processingState == ProcessingState.completed) {
        _handleAyahCompleted();
      }
    });

    _positionSubscription = _player.positionStream.listen((pos) {
      final dur = _player.duration;
      if (dur != null && dur.inMilliseconds > 0) {
        ayahPlaybackProgress.value =
            (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
      } else {
        ayahPlaybackProgress.value = 0.0;
      }
    });
  }

  void setReciter(Reciter reciter) {
    selectedReciterNotifier.value = reciter;
    // If currently playing, replay current ayah with new reciter
    if (currentPlayingSurah.value != null && currentPlayingAyah.value != null) {
      playAyah(
        surahNumber: currentPlayingSurah.value!,
        ayahNumber: currentPlayingAyah.value!,
        maxVerses: _maxVersesInCurrentSurah,
      );
    }
  }

  String getAyahAudioUrl(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/${selectedReciter.id}/$s$a.mp3';
  }

  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
    required int maxVerses,
    bool announce = false,
  }) async {
    _maxVersesInCurrentSurah = maxVerses;
    currentPlayingSurah.value = surahNumber;
    currentPlayingAyah.value = ayahNumber;
    ayahPlaybackProgress.value = 0.0;

    final surahMeta = kAllSurahs.firstWhere(
      (s) => s.number == surahNumber,
      orElse: () =>
          kAllSurahs[(surahNumber - 1).clamp(0, kAllSurahs.length - 1)],
    );

    if (announce) {
      await announceSurah(surahMeta.englishName);
    }

    final url = getAyahAudioUrl(surahNumber, ayahNumber);
    try {
      isLoadingNotifier.value = true;
      final audioSource = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: '${surahNumber}_$ayahNumber',
          album: 'Holy Quran',
          title:
              '${surahMeta.englishName} (${surahMeta.name}) • Verse $ayahNumber',
          artist: selectedReciter.name,
          artUri: Uri.parse(
              'https://raw.githubusercontent.com/piustech1/my-quran/main/assets/images/app_logo.png'),
        ),
      );
      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      isLoadingNotifier.value = false;
      isPlayingNotifier.value = false;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    currentPlayingAyah.value = null;
    currentPlayingSurah.value = null;
    ayahPlaybackProgress.value = 0.0;
    isPlayingNotifier.value = false;
  }

  Future<void> playNextAyah() async {
    if (currentPlayingSurah.value == null || currentPlayingAyah.value == null) {
      return;
    }
    final nextAyah = currentPlayingAyah.value! + 1;
    if (nextAyah <= _maxVersesInCurrentSurah) {
      await playAyah(
        surahNumber: currentPlayingSurah.value!,
        ayahNumber: nextAyah,
        maxVerses: _maxVersesInCurrentSurah,
      );
    } else {
      // Seamlessly advance to the next Surah with voice announcement!
      final currentSurah = currentPlayingSurah.value!;
      if (currentSurah < 114) {
        final nextSurahNum = currentSurah + 1;
        final nextSurahMeta = kAllSurahs.firstWhere(
          (s) => s.number == nextSurahNum,
          orElse: () => kAllSurahs[nextSurahNum - 1],
        );
        await playAyah(
          surahNumber: nextSurahNum,
          ayahNumber: 1,
          maxVerses: nextSurahMeta.numberOfAyahs,
          announce: true,
        );
      } else {
        await stop();
      }
    }
  }

  Future<void> playPreviousAyah() async {
    if (currentPlayingSurah.value == null || currentPlayingAyah.value == null) {
      return;
    }
    final prevAyah = currentPlayingAyah.value! - 1;
    if (prevAyah >= 1) {
      await playAyah(
        surahNumber: currentPlayingSurah.value!,
        ayahNumber: prevAyah,
        maxVerses: _maxVersesInCurrentSurah,
      );
    } else {
      // If at Ayah 1 and previous is pressed, move to previous Surah's last Ayah if available
      final currentSurah = currentPlayingSurah.value!;
      if (currentSurah > 1) {
        final prevSurahNum = currentSurah - 1;
        final prevSurahMeta = kAllSurahs.firstWhere(
          (s) => s.number == prevSurahNum,
          orElse: () => kAllSurahs[prevSurahNum - 1],
        );
        await playAyah(
          surahNumber: prevSurahNum,
          ayahNumber: prevSurahMeta.numberOfAyahs,
          maxVerses: prevSurahMeta.numberOfAyahs,
        );
      }
    }
  }

  void _handleAyahCompleted() {
    if (autoPlayNext) {
      playNextAyah();
    } else {
      isPlayingNotifier.value = false;
    }
  }

  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _player.dispose();
  }
}
