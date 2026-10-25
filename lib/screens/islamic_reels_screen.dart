import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../models/islamic_video_item.dart';
import '../services/islamic_video_service.dart';
import '../services/audio_service.dart';

/// Full-screen TikTok/Reels-style Islamic Video Feed
/// Powered by IslamHouse Multilingual API
class IslamicReelsScreen extends StatefulWidget {
  final String initialLanguage;

  const IslamicReelsScreen({
    super.key,
    this.initialLanguage = 'en',
  });

  @override
  State<IslamicReelsScreen> createState() => _IslamicReelsScreenState();
}

class _IslamicReelsScreenState extends State<IslamicReelsScreen> {
  final IslamicVideoService _videoService = IslamicVideoService();
  late PageController _pageController;

  late String _currentLanguage;
  List<IslamicVideoItem> _videos = [];
  bool _isLoading = true;
  int _currentPageIndex = 0;
  bool _isGlobalMuted = false;

  // Active video controllers mapped by page index
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage;
    _pageController = PageController();

    // Pause background Quran recitation to avoid conflicting audio
    try {
      QuranAudioService().player.pause();
    } catch (_) {}

    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  Future<void> _loadVideos({bool append = false}) async {
    if (!append) {
      setState(() => _isLoading = true);
    }

    final newVideos = await _videoService.fetchVideos(
      language: _currentLanguage,
      page: append ? (_videos.length ~/ 20) + 1 : 1,
    );

    if (!mounted) return;

    setState(() {
      if (append) {
        _videos.addAll(newVideos);
      } else {
        _videos = newVideos;
        _currentPageIndex = 0;
      }
      _isLoading = false;
    });

    if (_videos.isNotEmpty) {
      _initControllerAtIndex(_currentPageIndex);
      // Pre-load next video for zero-delay scroll
      if (_videos.length > 1) {
        _initControllerAtIndex(1);
      }
    }
  }

  Future<void> _initControllerAtIndex(int index) async {
    if (index < 0 || index >= _videos.length) return;
    if (_controllers.containsKey(index)) return;

    final videoItem = _videos[index];
    final uri = Uri.tryParse(videoItem.videoUrl);
    if (uri == null || videoItem.videoUrl.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(uri);
    _controllers[index] = controller;

    try {
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(_isGlobalMuted ? 0.0 : 1.0);

      // Only auto-play if this is still the active visible index
      if (_currentPageIndex == index && mounted) {
        controller.play();
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('[IslamicReels] Failed to initialize video at index $index: $e');
    }
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();

    // Pause previous video
    if (_controllers.containsKey(_currentPageIndex)) {
      _controllers[_currentPageIndex]?.pause();
    }

    setState(() {
      _currentPageIndex = index;
    });

    // Play active video
    if (_controllers.containsKey(index)) {
      final controller = _controllers[index]!;
      if (controller.value.isInitialized) {
        controller.play();
      }
    } else {
      _initControllerAtIndex(index);
    }

    // Preload next video
    if (index + 1 < _videos.length) {
      _initControllerAtIndex(index + 1);
    }

    // Dispose faraway controllers to save memory
    _controllers.removeWhere((idx, ctrl) {
      if ((idx - index).abs() > 2) {
        ctrl.dispose();
        return true;
      }
      return false;
    });

    // Infinite pagination load when near end
    if (index >= _videos.length - 2 && !_isLoading) {
      _loadVideos(append: true);
    }
  }

  void _toggleGlobalMute() {
    HapticFeedback.lightImpact();
    setState(() {
      _isGlobalMuted = !_isGlobalMuted;
    });
    for (final ctrl in _controllers.values) {
      ctrl.setVolume(_isGlobalMuted ? 0.0 : 1.0);
    }
  }

  void _showLanguageSelector() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2418).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.language_rounded, color: Color(0xFFE5B850), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Select Islamic Feed Language',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: IslamicVideoService.supportedLanguages.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (ctx, i) {
                      final lang = IslamicVideoService.supportedLanguages[i];
                      final isSelected = lang.code == _currentLanguage;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(
                          lang.englishName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFFE5B850) : Colors.white,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang.nativeName,
                              style: GoogleFonts.amiri(
                                fontSize: 16,
                                color: isSelected ? const Color(0xFFE5B850) : Colors.white60,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle_rounded, color: Color(0xFFE5B850), size: 18),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          if (_currentLanguage != lang.code) {
                            setState(() {
                              _currentLanguage = lang.code;
                            });
                            // Clear controllers
                            for (final ctrl in _controllers.values) {
                              ctrl.dispose();
                            }
                            _controllers.clear();
                            _loadVideos();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVideoDescription(IslamicVideoItem video) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F261B).withOpacity(0.96),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white12, width: 1),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4D36),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'IslamHouse Verified',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE5B850),
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    video.description.isNotEmpty
                        ? video.description
                        : 'Beneficial authentic Islamic video providing practical instruction, spiritual wisdom, and prophetic Sunnah guidance.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: video.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          '#$tag',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE5B850),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Source: IslamHouse.com Multilingual API Hub',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-screen Vertical Feed
          if (_isLoading && _videos.isEmpty)
            _buildLoadingState()
          else if (_videos.isEmpty)
            _buildEmptyState()
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _videos.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final video = _videos[index];
                final controller = _controllers[index];
                final isCurrent = index == _currentPageIndex;

                return _ReelItemView(
                  video: video,
                  controller: controller,
                  isCurrent: isCurrent,
                  isMuted: _isGlobalMuted,
                  onShowDescription: () => _showVideoDescription(video),
                  onShowLanguages: _showLanguageSelector,
                  onToggleMute: _toggleGlobalMute,
                );
              },
            ),

          // 2. Top Header Overlay (Back Button, Feed Title, Mute, Language)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildTopHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        // Back Button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),

        const Spacer(),

        // Islamic Reels Title Badge with Live indicator
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hikmah Reels',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // Mute / Unmute Button
        GestureDetector(
          onTap: _toggleGlobalMute,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Icon(
                  _isGlobalMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Language Pill
        GestureDetector(
          onTap: _showLanguageSelector,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4D36).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5B850).withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, color: Color(0xFFE5B850), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _currentLanguage.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFE5B850),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 18),
          Text(
            'Fetching Islamic Clips from IslamHouse...',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'No Videos Available for This Language',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try switching to another language like English or Arabic.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showLanguageSelector,
              icon: const Icon(Icons.language_rounded, size: 18),
              label: const Text('Change Language'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4D36),
                foregroundColor: const Color(0xFFE5B850),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual Vertical Video Reel Item with TikTok-Style Overlays
class _ReelItemView extends StatefulWidget {
  final IslamicVideoItem video;
  final VideoPlayerController? controller;
  final bool isCurrent;
  final bool isMuted;
  final VoidCallback onShowDescription;
  final VoidCallback onShowLanguages;
  final VoidCallback onToggleMute;

  const _ReelItemView({
    required this.video,
    required this.controller,
    required this.isCurrent,
    required this.isMuted,
    required this.onShowDescription,
    required this.onShowLanguages,
    required this.onToggleMute,
  });

  @override
  State<_ReelItemView> createState() => _ReelItemViewState();
}

class _ReelItemViewState extends State<_ReelItemView> with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  bool _showPlayPauseOverlay = false;
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;
  bool _showDoubleTapHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4).chain(CurveTween(curve: Curves.easeOutBack)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
    ]).animate(_heartAnimController);

    widget.controller?.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant _ReelItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerUpdate);
      widget.controller?.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerUpdate);
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted && widget.controller != null) {
      final isPlaying = widget.controller!.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() => _isPlaying = isPlaying);
      }
    }
  }

  void _handleTap() {
    final ctrl = widget.controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    HapticFeedback.lightImpact();
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }

    setState(() {
      _showPlayPauseOverlay = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showPlayPauseOverlay = false);
      }
    });
  }

  void _handleDoubleTap() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (!widget.video.isLiked) {
        widget.video.isLiked = true;
        widget.video.likesCount += 1;
      }
      _showDoubleTapHeart = true;
    });

    _heartAnimController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _showDoubleTapHeart = false);
        }
      });
    });
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      widget.video.isLiked = !widget.video.isLiked;
      if (widget.video.isLiked) {
        widget.video.likesCount += 1;
      } else {
        widget.video.likesCount -= 1;
      }
    });
  }

  void _shareVideo() {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(
      text: '${widget.video.title}\nWatch authentic Islamic guidance: ${widget.video.videoUrl}\nSource: IslamHouse.com',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Video link copied to clipboard!',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1D4D36),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final isInitialized = ctrl != null && ctrl.value.isInitialized;

    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Player Surface
          if (isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ctrl.value.size.width,
                  height: ctrl.value.size.height,
                  child: VideoPlayer(ctrl),
                ),
              ),
            )
          else
            // Poster / Thumbnail fallback while buffering
            _buildPosterPlaceholder(),

          // 2. Cinematic Gradient Shadows (top & bottom)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.22, 0.65, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Center Animated Play/Pause Feedback Icon
          if (_showPlayPauseOverlay && isInitialized)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _showPlayPauseOverlay ? 1.0 : 0.0,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
            ),

          // 4. Double-Tap Animated Heart Overlay
          if (_showDoubleTapHeart)
            Center(
              child: ScaleTransition(
                scale: _heartScaleAnimation,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF4B72),
                  size: 110,
                ),
              ),
            ),

          // 5. Right TikTok Action Column
          Positioned(
            right: 12,
            bottom: 60,
            child: _buildRightActionColumn(),
          ),

          // 6. Bottom Information Metadata
          Positioned(
            left: 16,
            right: 84,
            bottom: 30,
            child: _buildBottomMetadata(),
          ),

          // 7. Video Progress Scrubber Bar
          if (isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildProgressBar(ctrl),
            ),
        ],
      ),
    );
  }

  Widget _buildPosterPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.video.imageUrl.isNotEmpty)
          Image.network(
            widget.video.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0C1F15)),
          )
        else
          Container(color: const Color(0xFF0C1F15)),
        Container(color: Colors.black.withOpacity(0.4)),
        const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE5B850),
            strokeWidth: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildRightActionColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Scholar / Channel Avatar
        GestureDetector(
          onTap: widget.onShowDescription,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5B850), width: 2),
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4D36), Color(0xFF0F261B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.mosque_rounded, color: Color(0xFFE5B850), size: 22),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Like Heart Button
        GestureDetector(
          onTap: _toggleLike,
          child: Column(
            children: [
              Icon(
                widget.video.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: widget.video.isLiked ? const Color(0xFFFF4B72) : Colors.white,
                size: 34,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.video.likesCount}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Share Button
        GestureDetector(
          onTap: _shareVideo,
          child: Column(
            children: [
              const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(height: 4),
              Text(
                'Share',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Info / Tafsir Details Button
        GestureDetector(
          onTap: widget.onShowDescription,
          child: Column(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Topic Tags Row
        Wrap(
          spacing: 6,
          children: widget.video.tags.take(2).map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1D4D36).withOpacity(0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5B850).withOpacity(0.4), width: 0.6),
              ),
              child: Text(
                '#$tag',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE5B850),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        // Author / Channel Handle
        Row(
          children: [
            Text(
              '@${widget.video.author}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFF38BDF8),
              size: 15,
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Video Title
        Text(
          widget.video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
            shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
          ),
        ),

        const SizedBox(height: 6),

        // Description Preview with "more" link
        GestureDetector(
          onTap: widget.onShowDescription,
          child: Text(
            widget.video.description.isNotEmpty
                ? widget.video.description
                : 'Click details to read complete Islamic explanation and scholarly notes...',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.85),
              height: 1.35,
              shadows: [const Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(VideoPlayerController ctrl) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: ctrl,
      builder: (context, value, _) {
        final position = value.position.inMilliseconds;
        final duration = value.duration.inMilliseconds;
        final progress = duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: 3,
          color: Colors.white.withOpacity(0.2),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 3,
              color: const Color(0xFFE5B850),
            ),
          ),
        );
      },
    );
  }
}
