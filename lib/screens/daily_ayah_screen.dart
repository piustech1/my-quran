import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_service.dart';
import '../services/daily_ayah_service.dart';
import '../services/prayer_time_service.dart';
import '../services/storage_service.dart';

class DailyAyahScreen extends StatefulWidget {
  final DateTime? date;
  final bool isEmbeddedInShell;
  final ValueChanged<int>? onNavigateTab;

  const DailyAyahScreen({
    super.key,
    this.date,
    this.isEmbeddedInShell = false,
    this.onNavigateTab,
  });

  @override
  State<DailyAyahScreen> createState() => _DailyAyahScreenState();
}

class _DailyAyahScreenState extends State<DailyAyahScreen> {
  final DailyAyahService _dailyAyahService = DailyAyahService();
  final QuranAudioService _audioService = QuranAudioService();
  final StorageService _storageService = StorageService();

  late final DailyAyahModel _dailyAyah;
  late TranslationEdition _selectedEdition;

  String _currentTranslationText = '';
  bool _isLoadingTranslation = false;
  bool _isBookmarked = false;
  double _playbackSpeed = 1.0;
  bool _hasAutoPlayed = false;
  bool _isShuffle = false;
  int _tafsirTab = 0; // 0: Exegesis, 1: Key Lessons, 2: Vocabulary

  @override
  void initState() {
    super.initState();
    _dailyAyah = _dailyAyahService.getDailyAyah(widget.date);
    _selectedEdition = DailyAyahService.supportedTranslations[0];
    _currentTranslationText = _dailyAyah.defaultTranslation;

    _loadPreferences();
    _initAutoAudio();
  }

  Future<void> _loadPreferences() async {
    final bookmarked = await _storageService.isDailyAyahBookmarked(
      _dailyAyah.surahNumber,
      _dailyAyah.ayahNumber,
    );
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  void _initAutoAudio() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoPlayed && mounted) {
        _hasAutoPlayed = true;
        // Audio isolation: only start auto-play if audio is not already playing in another screen
        if (!_audioService.isPlayingNotifier.value) {
          _audioService.playAyah(
            surahNumber: _dailyAyah.surahNumber,
            ayahNumber: _dailyAyah.ayahNumber,
            maxVerses: 286,
          );
        }
      }
    });
  }

  bool _isThisAyahPlaying() {
    return _audioService.isPlayingNotifier.value &&
        _audioService.currentPlayingSurah.value == _dailyAyah.surahNumber &&
        _audioService.currentPlayingAyah.value == _dailyAyah.ayahNumber;
  }

  void _onPlayPauseTap() {
    HapticFeedback.lightImpact();
    if (_isThisAyahPlaying()) {
      _audioService.pause();
    } else if (_audioService.currentPlayingSurah.value == _dailyAyah.surahNumber &&
        _audioService.currentPlayingAyah.value == _dailyAyah.ayahNumber) {
      _audioService.resume();
    } else {
      _audioService.playAyah(
        surahNumber: _dailyAyah.surahNumber,
        ayahNumber: _dailyAyah.ayahNumber,
        maxVerses: 286,
      );
    }
  }

  Future<void> _onSelectTranslation(TranslationEdition edition) async {
    if (_selectedEdition.id == edition.id) return;

    setState(() {
      _selectedEdition = edition;
      _isLoadingTranslation = true;
    });

    final text = await _dailyAyahService.fetchTranslation(
      chapter: _dailyAyah.surahNumber,
      verse: _dailyAyah.ayahNumber,
      editionId: edition.id,
    );

    if (mounted) {
      setState(() {
        _currentTranslationText = text;
        _isLoadingTranslation = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    HapticFeedback.mediumImpact();
    final newState = await _storageService.toggleDailyAyahBookmark(
      _dailyAyah.surahNumber,
      _dailyAyah.ayahNumber,
    );
    if (mounted) {
      setState(() => _isBookmarked = newState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newState ? 'Ayah saved to bookmarks' : 'Ayah removed from bookmarks',
            style: GoogleFonts.plusJakartaSans(),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF0F3624),
        ),
      );
    }
  }

  void _copyToClipboard() {
    HapticFeedback.lightImpact();
    final formatted = '''
${_dailyAyah.arabicText}

"$_currentTranslationText"

— ${_dailyAyah.reference}
(${_selectedEdition.authorName})

Reflection: ${_dailyAyah.subtitle}

Tafsir: ${_dailyAyah.explanation}
(${_dailyAyah.tafsirAttribution})

Shared via My Quran
''';

    Clipboard.setData(ClipboardData(text: formatted));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFF3B84C), size: 18),
            const SizedBox(width: 8),
            Text(
              'Ayah & reflection copied to clipboard',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F3624),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _togglePlaybackSpeed() {
    HapticFeedback.selectionClick();
    final speeds = [0.75, 1.0, 1.25, 1.5];
    final nextIndex = (speeds.indexOf(_playbackSpeed) + 1) % speeds.length;
    final newSpeed = speeds[nextIndex];
    setState(() => _playbackSpeed = newSpeed);
    _audioService.player.setSpeed(newSpeed);
  }

  String _formatDateWithHijri(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final hijriFull = PrayerSchedule.calculateHijriDate(dt);
    final match = RegExp(r'(\d{4}\s*AH)').firstMatch(hijriFull);
    final hijriYear = match != null ? match.group(1) : '1447 AH';
    return '$dayName, $monthName ${dt.day} • $hijriYear';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071C12),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF061A10),
              Color(0xFF0A291A),
              Color(0xFF0F3624),
              Color(0xFF14402B),
            ],
            stops: [0.0, 0.45, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final isShortScreen = availableHeight < 720;
              final verticalSpacing = isShortScreen ? 6.0 : 8.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // 1. Now Playing Header
                    _buildNowPlayingHeader(),

                    SizedBox(height: verticalSpacing),

                    // 2. Immersive Ayah Artwork (Mihrab Shape with Glowing Gold Trim)
                    Expanded(
                      flex: isShortScreen ? 10 : 12,
                      child: _buildArtworkCard(isShortScreen),
                    ),

                    SizedBox(height: verticalSpacing),

                    // 3. Spotify-Inspired Quran Audio Player Surface
                    _buildSpotifyAudioPlayer(isShortScreen),

                    SizedBox(height: verticalSpacing),

                    // 4. Compact Reflection Takeaway Card
                    _buildReflectionCard(),

                    SizedBox(height: verticalSpacing),

                    // 5. Bottom Action Row (Tafsir, Translation, Save)
                    _buildBottomActionRow(),

                    SizedBox(
                      height: widget.isEmbeddedInShell ? 8.0 : (isShortScreen ? 6.0 : 10.0),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. NOW PLAYING HEADER
  // ===========================================================================
  Widget _buildNowPlayingHeader() {
    final now = widget.date ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular frosted glass back button [<]
          _buildFrostedCircleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 38,
            iconSize: 16,
            onTap: () {
              if (widget.isEmbeddedInShell) {
                widget.onNavigateTab?.call(0);
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),

          // Center: Title + Dynamic Hijri Date
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily Ayah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                _formatDateWithHijri(now),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFD2E6D8),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),

          // Right: Frosted glass bookmark button [🔖]
          _buildFrostedCircleButton(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            iconColor: _isBookmarked ? const Color(0xFFF3B84C) : Colors.white,
            size: 38,
            iconSize: 18,
            onTap: _toggleBookmark,
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    double size = 38,
    double iconSize = 18,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. IMMERSIVE AYAH ARTWORK (Mihrab Shape with Glowing Gold Trim)
  // ===========================================================================
  Widget _buildArtworkCard(bool isShortScreen) {
    return Stack(
      children: [
        // Ornate Islamic Mihrab clipped card
        ClipPath(
          clipper: const IslamicMihrabClipper(
            cornerRadius: 26.0,
            archDepth: 26.0,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Serene Islamic Scenery / Mosque Artwork
              Image.asset(
                _dailyAyah.imageAsset.isNotEmpty
                    ? _dailyAyah.imageAsset
                    : 'assets/daily_ayah_visual.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),

              // Rich dark contrast overlay for crystal-clear readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.38),
                      Colors.black.withOpacity(0.64),
                      const Color(0xFF072115).withOpacity(0.92),
                    ],
                    stops: const [0.0, 0.48, 1.0],
                  ),
                ),
              ),

              // Text & Badge Content over Artwork
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16.0,
                  isShortScreen ? 20.0 : 26.0,
                  16.0,
                  isShortScreen ? 10.0 : 14.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: "⭐ Verse of the Day" badge
                    _buildVerseOfTheDayBadge(),

                    // Center: Arabic verse, flourish divider, transliteration, and translation
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Arabic Verse
                          Flexible(
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Text(
                                _dailyAyah.arabicText,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.amiri(
                                  color: Colors.white,
                                  fontSize: isShortScreen ? 20.0 : 23.5,
                                  fontWeight: FontWeight.bold,
                                  height: 1.7,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.8),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isShortScreen ? 6.0 : 8.0),

                          // Decorative Islamic Arch Flourish Divider
                          CustomPaint(
                            size: const Size(60, 10),
                            painter: GoldFlourishPainter(),
                          ),

                          SizedBox(height: isShortScreen ? 6.0 : 8.0),

                          // Transliteration (Italic)
                          if (_dailyAyah.transliteration.isNotEmpty)
                            Text(
                              _dailyAyah.transliteration,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: isShortScreen ? 11.0 : 12.0,
                                fontStyle: FontStyle.italic,
                                height: 1.35,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: isShortScreen ? 4.0 : 6.0),

                          // English Translation
                          if (_isLoadingTranslation)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFF3B84C),
                                ),
                              ),
                            )
                          else
                            Text(
                              _currentTranslationText,
                              textAlign: TextAlign.center,
                              maxLines: isShortScreen ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: isShortScreen ? 12.0 : 13.5,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Bottom Citation (— Surah Name Chapter:Verse)
                    Text(
                      '— ${_dailyAyah.shortCitation}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFF3B84C),
                        fontSize: isShortScreen ? 11.0 : 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Glowing Golden Islamic Arch Border
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: IslamicMihrabBorderPainter(
                cornerRadius: 26.0,
                archDepth: 26.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerseOfTheDayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: Color(0xFFF3B84C),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            'Verse of the Day',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11.0,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SPOTIFY-INSPIRED QURAN AUDIO PLAYER SURFACE
  // ===========================================================================
  Widget _buildSpotifyAudioPlayer(bool isShortScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: isShortScreen ? 8.0 : 10.0,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF163E2A),
            Color(0xFF0F301F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A. Reciter info + Playback speed button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reciter avatar & name dropdown
              ValueListenableBuilder<Reciter>(
                valueListenable: _audioService.selectedReciterNotifier,
                builder: (context, reciter, _) {
                  return GestureDetector(
                    onTap: _showReciterBottomSheet,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        // Avatar emblem with subtle glow
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E5238),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF3B84C).withOpacity(0.5),
                              width: 1.2,
                            ),
                          ),
                          child: ClipOval(
                            child: reciter.imageAsset.isNotEmpty
                                ? Image.asset(
                                    reciter.imageAsset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.mosque_rounded,
                                      color: Color(0xFFF3B84C),
                                      size: 18,
                                    ),
                                  )
                                : const Icon(
                                    Icons.mosque_rounded,
                                    color: Color(0xFFF3B84C),
                                    size: 18,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reciter',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  reciter.name.split(' ').first,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Speed selector pill button [ 1.0x › ]
              GestureDetector(
                onTap: _togglePlaybackSpeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_playbackSpeed.toStringAsFixed(_playbackSpeed == _playbackSpeed.roundToDouble() ? 1 : 2)}× ›',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isShortScreen ? 4.0 : 6.0),

          // B. Real-time Scrubber Slider & Duration Labels
          StreamBuilder<Duration>(
            stream: _audioService.player.positionStream,
            builder: (context, posSnapshot) {
              final pos = posSnapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: _audioService.player.durationStream,
                builder: (context, durSnapshot) {
                  final dur = durSnapshot.data ?? const Duration(seconds: 12);
                  final maxMs = math.max(dur.inMilliseconds.toDouble(), 1000.0);
                  final currentMs = pos.inMilliseconds.toDouble().clamp(0.0, maxMs);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                          activeTrackColor: const Color(0xFFF3B84C),
                          inactiveTrackColor: Colors.white.withOpacity(0.18),
                          thumbColor: const Color(0xFFF3B84C),
                          overlayColor: const Color(0xFFF3B84C).withOpacity(0.2),
                        ),
                        child: Slider(
                          value: currentMs,
                          min: 0.0,
                          max: maxMs,
                          onChanged: (val) {
                            _audioService.player.seek(Duration(milliseconds: val.toInt()));
                          },
                        ),
                      ),

                      // Time Labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(pos),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white60,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(dur),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white60,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          SizedBox(height: isShortScreen ? 4.0 : 6.0),

          // C. Playback Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Shuffle / Replay
              IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  size: 20,
                  color: _isShuffle ? const Color(0xFFF3B84C) : Colors.white60,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isShuffle = !_isShuffle);
                },
              ),

              // Skip Previous [|◀]
              IconButton(
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  size: 28,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _audioService.playPreviousAyah();
                },
              ),

              // Prominent Golden Play/Pause Button (52x52)
              ValueListenableBuilder<bool>(
                valueListenable: _audioService.isPlayingNotifier,
                builder: (context, _, __) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _audioService.isLoadingNotifier,
                    builder: (context, isLoading, ___) {
                      final isPlaying = _isThisAyahPlaying();

                      return GestureDetector(
                        onTap: _onPlayPauseTap,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3B84C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF3B84C).withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF092015),
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: const Color(0xFF092015),
                                  size: 32,
                                ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Skip Next [▶|]
              IconButton(
                icon: const Icon(
                  Icons.skip_next_rounded,
                  size: 28,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _audioService.playNextAyah();
                },
              ),

              // Repeat / Loop [🔁]
              IconButton(
                icon: Icon(
                  Icons.repeat_rounded,
                  size: 20,
                  color: _audioService.autoPlayNext
                      ? const Color(0xFFF3B84C)
                      : Colors.white60,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _audioService.autoPlayNext = !_audioService.autoPlayNext;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. TRANSLATION AND REFLECTION PANEL
  // ===========================================================================
  Widget _buildReflectionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Amber lightbulb icon in subtle circle
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE5D2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFFC88A22),
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          // Vertical amber accent bar
          Container(
            width: 1.5,
            height: 32,
            color: const Color(0xFFC88A22).withOpacity(0.4),
          ),

          const SizedBox(width: 10),

          // Reflection headline & meaningful takeaway
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reflection',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF133624),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dailyAyah.subtitle.isNotEmpty
                      ? _dailyAyah.subtitle
                      : 'A reminder that faith gives strength through every challenge.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF223629),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Vertical separator
          Container(
            width: 1,
            height: 28,
            color: Colors.black.withOpacity(0.08),
          ),

          const SizedBox(width: 8),

          // Share button
          GestureDetector(
            onTap: _copyToClipboard,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.share_outlined,
                  color: Color(0xFF133624),
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text(
                  'Share',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF133624),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. BOTTOM ACTION ROW ([📖 Tafsir], [🌐 Translation], [🔖 Save])
  // ===========================================================================
  Widget _buildBottomActionRow() {
    return Row(
      children: [
        // Tafsir Pill
        Expanded(
          child: _buildActionPill(
            icon: Icons.menu_book_rounded,
            label: 'Tafsir',
            onTap: _showTafsirBottomSheet,
          ),
        ),

        const SizedBox(width: 8),

        // Translation Pill
        Expanded(
          child: _buildActionPill(
            icon: Icons.translate_rounded,
            label: 'Translation',
            onTap: _showTranslationBottomSheet,
          ),
        ),

        const SizedBox(width: 8),

        // Save Pill
        Expanded(
          child: _buildActionPill(
            icon: _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            iconColor: _isBookmarked ? const Color(0xFFF3B84C) : Colors.white,
            label: 'Save',
            onTap: _toggleBookmark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF133624),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL BOTTOM SHEETS: TAFSIR, TRANSLATION, RECITERS
  // ===========================================================================

  /// Dedicated Full Tafsir Bottom Sheet
  void _showTafsirBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.76,
              decoration: const BoxDecoration(
                color: Color(0xFF0C2418),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Grab Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3B84C).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 16,
                                color: Color(0xFFF3B84C),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TAFSIR & REFLECTION',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFFF3B84C),
                                  ),
                                ),
                                Text(
                                  'Understanding this ayah',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _dailyAyah.tafsirAttribution,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD2E6D8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Segmented Tabs: Exegesis, Key Lessons, Vocabulary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _buildSheetTabItem('Exegesis', 0, setSheetState),
                          _buildSheetTabItem('Key Lessons', 1, setSheetState),
                          _buildSheetTabItem('Vocabulary', 2, setSheetState),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 16),

                  // Tab Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: _buildSheetTabContent(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetTabItem(String title, int index, StateSetter setSheetState) {
    final isSelected = _tafsirTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setSheetState(() => _tafsirTab = index);
          setState(() => _tafsirTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF14402B) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFFF3B84C) : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTabContent() {
    switch (_tafsirTab) {
      case 0: // Exegesis
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arabic Highlight Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF133624),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _dailyAyah.arabicText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 19,
                  height: 1.8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Classical Exegesis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF3B84C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _dailyAyah.explanation,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.6,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Attribution: ${_dailyAyah.tafsirAttribution}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: Colors.white54,
              ),
            ),
          ],
        );

      case 1: // Key Lessons
        return Column(
          children: [
            _buildLessonTile(
              'Spiritual Resilience',
              'Setbacks and grief are temporary trials in human life. Sincere faith elevates the believer above despair.',
              Icons.shield_outlined,
            ),
            _buildLessonTile(
              'Unshakable Optimism',
              'True believers find hope and moral victory through steadfast trust in Allah\'s wisdom and ultimate promise.',
              Icons.wb_sunny_outlined,
            ),
            _buildLessonTile(
              'Active Faith',
              'Faith is not merely passive belief, but an active inner fortitude that conquers fear and apathy.',
              Icons.favorite_border_rounded,
            ),
          ],
        );

      case 2: // Vocabulary
      default:
        return Column(
          children: [
            _buildVocabTile('وَلَا تَهِنُوا۟', 'wa lā tahinū', 'Do not lose heart / weaken', 'Root: و-ه-ن'),
            _buildVocabTile('وَلَا تَحۡزَنُوا۟', 'wa lā taḥzanū', 'Do not grieve / sorrow', 'Root: ح-ز-ن'),
            _buildVocabTile('ٱلۡأَعۡلَوۡنَ', 'al-a\'lawn', 'The superior / exalted ones', 'Root: ع-ل-و'),
            _buildVocabTile('مُّؤۡمِنِینَ', 'mu\'minīn', 'True believers in faith', 'Root: أ-م-ن'),
          ],
        );
    }
  }

  Widget _buildLessonTile(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF133624),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3B84C).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFF3B84C), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabTile(String arabic, String translit, String meaning, String root) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF133624),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF3B84C),
                ),
              ),
              Text(
                meaning,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: Colors.white70,
                ),
              ),
              Text(
                root,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          Text(
            arabic,
            style: GoogleFonts.amiri(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Translation Edition Selector Modal Sheet
  void _showTranslationBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C2418),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select Translation',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...DailyAyahService.supportedTranslations.map((edition) {
                final isSelected = edition.id == _selectedEdition.id;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected ? const Color(0xFFF3B84C) : Colors.white38,
                    size: 20,
                  ),
                  title: Text(
                    edition.languageName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFFF3B84C) : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    edition.authorName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: Colors.white60,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _onSelectTranslation(edition);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Reciter Selection Modal Sheet
  void _showReciterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0C2418),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Choose Reciter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              ...QuranAudioService.availableReciters.map((reciter) {
                final isSelected =
                    reciter.id == _audioService.selectedReciter.id;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: ClipOval(
                    child: reciter.imageAsset.isNotEmpty
                        ? Image.asset(
                            reciter.imageAsset,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.mosque_rounded,
                              color: Color(0xFFF3B84C),
                            ),
                          )
                        : const Icon(
                            Icons.mosque_rounded,
                            color: Color(0xFFF3B84C),
                          ),
                  ),
                  title: Text(
                    reciter.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFFF3B84C) : Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    reciter.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: Colors.white60,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFF3B84C),
                        )
                      : null,
                  onTap: () {
                    _audioService.setReciter(reciter);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// ISLAMIC MIHRAB CLIPPER & BORDER PAINTER
// =============================================================================
class IslamicMihrabClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double archDepth;

  const IslamicMihrabClipper({
    this.cornerRadius = 26.0,
    this.archDepth = 26.0,
  });

  @override
  Path getClip(Size size) {
    return _buildMihrabPath(size, cornerRadius, archDepth);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class IslamicMihrabBorderPainter extends CustomPainter {
  final double cornerRadius;
  final double archDepth;

  const IslamicMihrabBorderPainter({
    this.cornerRadius = 26.0,
    this.archDepth = 26.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildMihrabPath(size, cornerRadius, archDepth);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF3B84C),
          Color(0xFFE5A93C),
          Color(0x33F3B84C),
        ],
        stops: [0.0, 0.35, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _buildMihrabPath(Size size, double r, double archDepth) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  // Bottom left corner
  path.moveTo(0, h - r);
  path.quadraticBezierTo(0, h, r, h);

  // Bottom straight edge
  path.lineTo(w - r, h);
  path.quadraticBezierTo(w, h, w, h - r);

  // Right vertical edge going up to arch shoulder start
  final archStartY = archDepth + 8.0;
  path.lineTo(w, archStartY);

  // Right outer shoulder lobe
  path.quadraticBezierTo(w, archStartY - 12.0, w - 18.0, archStartY - 14.0);

  // Right inner scallop notch
  final midRightX = w * 0.72;
  final midRightY = archStartY - 8.0;
  path.quadraticBezierTo(w * 0.85, archStartY - 16.0, midRightX, midRightY);

  // Pointed center arch (right to peak)
  final peakX = w / 2;
  path.cubicTo(
    w * 0.60, midRightY - 2.0,
    w * 0.54, 2.0,
    peakX, 0,
  );

  // Pointed center arch (peak to left)
  final midLeftX = w * 0.28;
  final midLeftY = midRightY;
  path.cubicTo(
    w * 0.46, 2.0,
    w * 0.40, midRightY - 2.0,
    midLeftX, midLeftY,
  );

  // Left inner scallop notch
  path.quadraticBezierTo(w * 0.15, archStartY - 16.0, 18.0, archStartY - 14.0);
  path.quadraticBezierTo(0, archStartY - 12.0, 0, archStartY);

  // Left edge down to bottom left corner
  path.lineTo(0, h - r);
  path.close();

  return path;
}

// =============================================================================
// DECORATIVE GOLD FLOURISH PAINTER
// =============================================================================
class GoldFlourishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF3B84C).withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final w = size.width;
    final h = size.height;
    final path = Path();

    // Left tapered line
    path.moveTo(0, h * 0.8);
    path.lineTo(w * 0.42, h * 0.8);

    // Center dome curve
    path.quadraticBezierTo(w * 0.5, 0, w * 0.58, h * 0.8);

    // Right tapered line
    path.lineTo(w, h * 0.8);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
