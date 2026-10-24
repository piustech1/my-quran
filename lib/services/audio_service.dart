import 'dart:async';
import 'package:flutter/foundation.dart';
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
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

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

  bool get isPaused => !_player.playing && currentPlayingAyah.value != null;

  int _maxVersesInCurrentSurah = 7;
  bool autoPlayNext = true;
  int? _lastCompletedSurah;
  int? _lastCompletedAyah;
  DateTime _lastCompletionTime = DateTime.fromMillisecondsSinceEpoch(0);

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  void _initAudioPlayer() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      final isActuallyPlaying = state.playing &&
          state.processingState != ProcessingState.completed &&
          state.processingState != ProcessingState.idle;
      isPlayingNotifier.value = isActuallyPlaying;
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
      isLoadingNotifier.value = false;
      // Do not await play(): in just_audio, play() returns a Future that only
      // completes when the audio finishes playing or pauses.
      _player.play();
    } catch (e) {
      debugPrint('Error playing ayah audio ($surahNumber:$ayahNumber): $e');
      if (currentPlayingSurah.value == surahNumber &&
          currentPlayingAyah.value == ayahNumber) {
        isLoadingNotifier.value = false;
        isPlayingNotifier.value = false;
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    currentPlayingAyah.value = null;
    currentPlayingSurah.value = null;
    ayahPlaybackProgress.value = 0.0;
    _lastCompletedSurah = null;
    _lastCompletedAyah = null;
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
      // Seamlessly advance to the next Surah!
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
    final currentSurah = currentPlayingSurah.value;
    final currentAyah = currentPlayingAyah.value;

    if (currentSurah == null || currentAyah == null) return;

    final now = DateTime.now();
    if (now.difference(_lastCompletionTime).inMilliseconds < 350) {
      return;
    }

    // Deduplication: prevent duplicate completion events for the exact same Ayah
    if (currentSurah == _lastCompletedSurah &&
        currentAyah == _lastCompletedAyah) {
      return;
    }
    _lastCompletionTime = now;
    _lastCompletedSurah = currentSurah;
    _lastCompletedAyah = currentAyah;

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
