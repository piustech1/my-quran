import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

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

  int _maxVersesInCurrentSurah = 7;
  bool autoPlayNext = true;

  StreamSubscription<PlayerState>? _playerStateSubscription;

  void _initAudioPlayer() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      isPlayingNotifier.value = state.playing;
      isLoadingNotifier.value = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;

      if (state.processingState == ProcessingState.completed) {
        _handleAyahCompleted();
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

    final url = getAyahAudioUrl(surahNumber, ayahNumber);
    try {
      isLoadingNotifier.value = true;
      await _player.setUrl(url);
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
    isPlayingNotifier.value = false;
  }

  Future<void> playNextAyah() async {
    if (currentPlayingSurah.value == null || currentPlayingAyah.value == null) return;
    final nextAyah = currentPlayingAyah.value! + 1;
    if (nextAyah <= _maxVersesInCurrentSurah) {
      await playAyah(
        surahNumber: currentPlayingSurah.value!,
        ayahNumber: nextAyah,
        maxVerses: _maxVersesInCurrentSurah,
      );
    } else {
      await stop();
    }
  }

  Future<void> playPreviousAyah() async {
    if (currentPlayingSurah.value == null || currentPlayingAyah.value == null) return;
    final prevAyah = currentPlayingAyah.value! - 1;
    if (prevAyah >= 1) {
      await playAyah(
        surahNumber: currentPlayingSurah.value!,
        ayahNumber: prevAyah,
        maxVerses: _maxVersesInCurrentSurah,
      );
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
    _player.dispose();
  }
}
