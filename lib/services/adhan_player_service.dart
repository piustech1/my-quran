import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_service.dart';

/// In-app Adhan Audio Service
/// Plays the authentic Adhan audio when prayer time arrives
/// and coordinates with QuranAudioService to prevent audio conflicts.
class AdhanPlayerService {
  static final AdhanPlayerService _instance = AdhanPlayerService._internal();
  factory AdhanPlayerService() => _instance;

  AdhanPlayerService._internal() {
    _initListener();
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> currentPrayerNotifier = ValueNotifier<String?>(null);

  bool get isPlaying => isPlayingNotifier.value;
  String? get currentPrayer => currentPrayerNotifier.value;

  void _initListener() {
    _player.playerStateStream.listen((state) {
      final playing = state.playing && state.processingState != ProcessingState.completed;
      if (isPlayingNotifier.value != playing) {
        isPlayingNotifier.value = playing;
      }
      if (state.processingState == ProcessingState.completed) {
        currentPrayerNotifier.value = null;
      }
    });
  }

  /// Triggers full Adhan playback for the specified prayer
  Future<void> playAdhan(String prayerName) async {
    try {
      // Pause ongoing Quran recitation if active
      try {
        QuranAudioService().player.pause();
      } catch (_) {}

      currentPrayerNotifier.value = prayerName;
      await _player.setAsset('assets/audio/adhan.mp3');
      await _player.play();
    } catch (e) {
      debugPrint('[AdhanPlayerService] Error playing Adhan: $e');
      isPlayingNotifier.value = false;
      currentPrayerNotifier.value = null;
    }
  }

  /// Stops current Adhan recitation
  Future<void> stopAdhan() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('[AdhanPlayerService] Error stopping Adhan: $e');
    } finally {
      isPlayingNotifier.value = false;
      currentPrayerNotifier.value = null;
    }
  }

  void dispose() {
    _player.dispose();
  }
}
