import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/location_weather_service.dart';
import '../services/mosque_service.dart';

class MosqueFinderScreen extends StatefulWidget {
  const MosqueFinderScreen({super.key});

  @override
  State<MosqueFinderScreen> createState() => _MosqueFinderScreenState();
}

class _MosqueFinderScreenState extends State<MosqueFinderScreen>
    with SingleTickerProviderStateMixin {
  final MosqueService _mosqueService = MosqueService();
  final LocationWeatherService _weatherService = LocationWeatherService();
  final TextEditingController _searchController = TextEditingController();
  final TransformationController _mapController = TransformationController();

  List<MosqueModel> _mosques = [];
  MosqueModel? _selectedMosque;
  bool _isLoading = true;
  String _activeFilter = 'All';
  UserLocation? _userLocation;

  final List<String> _filters = [
    'All',
    'Open Now',
    "Women's Area",
    'Parking',
  ];

  late PageController _pageController;
  AnimationController? _flyAnimationController;
  Animation<Matrix4>? _flyAnimation;

  // Virtual map canvas dimensions
  static const double _canvasSize = 2400.0;
  static const Offset _userCenter = Offset(_canvasSize / 2, _canvasSize / 2);
  static const double _pixelsPerKm = 90.0; // 1 km = 90 canvas pixels

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
    _flyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _mapController.dispose();
    _flyAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final loc = await _weatherService.detectLocation();
    _userLocation = loc;

    final results = await _mosqueService.fetchNearbyMosques(
      userLat: loc.lat,
      userLon: loc.lon,
      filterTag: _activeFilter,
    );

    if (mounted) {
      setState(() {
        _mosques = results;
        _selectedMosque = results.isNotEmpty ? results.first : null;
        _isLoading = false;
      });

      // Recenter on user beacon after layout is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recenterOnUser();
      });
    }
  }

  void _onFilterSelected(String filter) async {
    setState(() {
      _activeFilter = filter;
      _isLoading = true;
    });

    final results = await _mosqueService.fetchNearbyMosques(
      userLat: _userLocation?.lat ?? 0.3163,
      userLon: _userLocation?.lon ?? 32.5822,
      searchQuery: _searchController.text,
      filterTag: filter,
    );

    if (mounted) {
      setState(() {
        _mosques = results;
        _selectedMosque = results.isNotEmpty ? results.first : null;
        _isLoading = false;
      });
      if (_mosques.isNotEmpty && _pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      if (_selectedMosque != null) {
        _flyToMosque(_selectedMosque!);
      }
    }
  }

  void _onSearchChanged(String query) async {
    final results = await _mosqueService.fetchNearbyMosques(
      userLat: _userLocation?.lat ?? 0.3163,
      userLon: _userLocation?.lon ?? 32.5822,
      searchQuery: query,
      filterTag: _activeFilter,
    );

    if (mounted) {
      setState(() {
        _mosques = results;
        _selectedMosque = results.isNotEmpty ? results.first : null;
      });
      if (_mosques.isNotEmpty && _pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      // If user searched a matching mosque, smoothly fly the map right to it!
      if (_selectedMosque != null) {
        _flyToMosque(_selectedMosque!);
      }
    }
  }

  void _selectMosque(MosqueModel m) {
    HapticFeedback.selectionClick();
    setState(() => _selectedMosque = m);
    final idx = _mosques.indexOf(m);
    if (idx != -1 && _pageController.hasClients) {
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
    _flyToMosque(m);
  }

  Offset _computeMosqueCanvasPosition(MosqueModel m) {
    final uLat = _userLocation?.lat ?? 0.3163;
    final uLon = _userLocation?.lon ?? 32.5822;

    final dLatKm = (m.lat - uLat) * 110.574;
    final dLonKm = (m.lon - uLon) * 111.320 * math.cos(uLat * math.pi / 180);

    return Offset(
      _userCenter.dx + (dLonKm * _pixelsPerKm),
      _userCenter.dy - (dLatKm * _pixelsPerKm),
    );
  }

  void _recenterOnUser() {
    final size = MediaQuery.of(context).size;
    final target = Matrix4.identity()
      ..translate(
        (size.width / 2) - _userCenter.dx,
        (size.height * 0.42) - _userCenter.dy,
      );
    _animateCameraTo(target);
  }

  void _flyToMosque(MosqueModel m) {
    final size = MediaQuery.of(context).size;
    final pos = _computeMosqueCanvasPosition(m);

    // Zoom in slightly (1.25x) and center on the mosque
    const scale = 1.25;
    final target = Matrix4.identity()
      ..scale(scale)
      ..translate(
        (size.width / (2 * scale)) - pos.dx,
        (size.height * 0.38 / scale) - pos.dy,
      );
    _animateCameraTo(target);
  }

  void _animateCameraTo(Matrix4 target) {
    final start = _mapController.value;
    _flyAnimationController?.stop();
    _flyAnimation = Matrix4Tween(begin: start, end: target).animate(
      CurvedAnimation(
        parent: _flyAnimationController!,
        curve: Curves.easeOutCubic,
      ),
    );
    _flyAnimationController?.reset();
    _flyAnimation?.addListener(() {
      _mapController.value = _flyAnimation!.value;
    });
    _flyAnimationController?.forward();
  }

  void _zoomIn() {
    HapticFeedback.lightImpact();
    final matrix = _mapController.value.clone()..scale(1.3);
    _mapController.value = matrix;
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    final matrix = _mapController.value.clone()..scale(0.77);
    _mapController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Interactive Zoomable & Pannable Vector Map
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _mapController,
              boundaryMargin: const EdgeInsets.all(1200),
              minScale: 0.5,
              maxScale: 4.5,
              child: SizedBox(
                width: _canvasSize,
                height: _canvasSize,
                child: Stack(
                  children: [
                    // A. Map Background, Streets, Water, Parks & Concentric Distance Rings
                    CustomPaint(
                      size: const Size(_canvasSize, _canvasSize),
                      painter: _InteractiveMapPainter(
                        isDark: isDark,
                        userCenter: _userCenter,
                        pixelsPerKm: _pixelsPerKm,
                        selectedMosquePos: _selectedMosque != null
                            ? _computeMosqueCanvasPosition(_selectedMosque!)
                            : null,
                      ),
                    ),

                    // B. User GPS Beacon (Blue Pulsing Location Dot)
                    Positioned(
                      left: _userCenter.dx - 18,
                      top: _userCenter.dy - 18,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.24),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade600,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.6),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // C. Interactive Mosque Pins Plotted at Exact Geographic Projections
                    ..._mosques.map((m) {
                      final pos = _computeMosqueCanvasPosition(m);
                      final isSelected = _selectedMosque?.id == m.id;

                      return Positioned(
                        left: pos.dx - 30,
                        top: pos.dy - 56,
                        child: GestureDetector(
                          onTap: () => _selectMosque(m),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Name pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF133827)
                                      : (isDark
                                          ? const Color(0xFF1B3224)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accentGold
                                        : Colors.black12,
                                    width: isSelected ? 1.8 : 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  m.name.length > 20
                                      ? '${m.name.substring(0, 18)}...'
                                      : m.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.accentGold
                                        : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Pin Icon with gold highlight when active
                              Container(
                                width: isSelected ? 44 : 34,
                                height: isSelected ? 44 : 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFF133827)
                                      : const Color(0xFF1C4933),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accentGold
                                        : Colors.white,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isSelected
                                              ? AppColors.accentGold
                                              : Colors.black)
                                          .withOpacity(0.4),
                                      blurRadius: isSelected ? 12 : 6,
                                      spreadRadius: isSelected ? 2 : 0,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.mosque_rounded,
                                  size: isSelected ? 22 : 17,
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // 2. Top Google Maps Search Bar & Filter Chips
          Positioned(
            top: topPadding + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGoogleMapsSearchBar(isDark),
                const SizedBox(height: 10),
                _buildFilterChips(isDark),
              ],
            ),
          ),

          // 3. Map Controls (Zoom In, Zoom Out, Recenter on Me)
          Positioned(
            right: 16,
            bottom: 270 + bottomPadding,
            child: Column(
              children: [
                _buildMapActionButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom in',
                  isDark: isDark,
                  onTap: _zoomIn,
                ),
                const SizedBox(height: 8),
                _buildMapActionButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom out',
                  isDark: isDark,
                  onTap: _zoomOut,
                ),
                const SizedBox(height: 12),
                _buildMapActionButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter on my location',
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _recenterOnUser();
                  },
                ),
              ],
            ),
          ),

          // 4. In-App Directions HUD & Bottom Mosque Card Carousel
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding > 0 ? bottomPadding + 10 : 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedMosque != null) ...[
                  _buildDirectionsHud(_selectedMosque!, isDark),
                  const SizedBox(height: 8),
                ],
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                        ),
                      )
                    : _mosques.isEmpty
                        ? _buildEmptyState(isDark)
                        : SizedBox(
                            height: 185,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _mosques.length,
                              onPageChanged: (idx) {
                                setState(() => _selectedMosque = _mosques[idx]);
                                _flyToMosque(_mosques[idx]);
                              },
                              itemBuilder: (context, idx) {
                                final m = _mosques[idx];
                                return _buildMosqueCard(m, isDark);
                              },
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMapsSearchBar(bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14291E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: isDark ? Colors.white : Colors.black87,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (query) => _onSearchChanged(query),
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search mosque, street, or area...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: isDark ? Colors.white60 : Colors.black45,
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _activeFilter == filter;

          return GestureDetector(
            onTap: () => _onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentGold
                    : (isDark ? const Color(0xFF14291E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                filter,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF0D281C)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14291E) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        color: isDark ? Colors.white : Colors.black87,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildDirectionsHud(MosqueModel m, bool isDark) {
    final driveMins = (m.distanceKm * 2.8).round().clamp(2, 60);
    final walkMins = (m.distanceKm * 12).round().clamp(4, 180);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F261B),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🚗 ~$driveMins min drive • 🚶 ~$walkMins min walk',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${m.distanceKm.toStringAsFixed(1)} km to ${m.name}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: const Color(0xFF0F261B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.navigation_rounded, size: 16),
            label: Text(
              'Navigate',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              MosqueService.launchGoogleMapsDirections(m.lat, m.lon, m.name);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMosqueCard(MosqueModel m, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14291E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  m.imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.address,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${m.distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.accentGold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${m.rating} (${m.reviewCount})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Jamaat at ${m.nextJamaat}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF133827),
                  foregroundColor: AppColors.accentGold,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.directions_rounded, size: 16),
                label: Text(
                  'Directions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  MosqueService.launchGoogleMapsDirections(
                    m.lat,
                    m.lon,
                    m.name,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14291E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          'No mosques found for this filter in your area.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

/// Interactive Vector Map Painter rendering Google Maps-style terrain, streets,
/// distance rings, and in-app navigation trajectory
class _InteractiveMapPainter extends CustomPainter {
  final bool isDark;
  final Offset userCenter;
  final double pixelsPerKm;
  final Offset? selectedMosquePos;

  _InteractiveMapPainter({
    required this.isDark,
    required this.userCenter,
    required this.pixelsPerKm,
    this.selectedMosquePos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Terrain base
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF111D16) : const Color(0xFFE8ECE9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Parks & Greenery
    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF162B1F) : const Color(0xFFD2E6D5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(userCenter.dx - 450, userCenter.dy - 350, 320, 280),
        const Radius.circular(50),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(userCenter.dx + 180, userCenter.dy + 120, 420, 340),
        const Radius.circular(60),
      ),
      parkPaint,
    );

    // 3. Water Channels / River
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF102830) : const Color(0xFFC7DEEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final river = Path()
      ..moveTo(userCenter.dx - 800, userCenter.dy + 400)
      ..cubicTo(
        userCenter.dx - 200,
        userCenter.dy + 350,
        userCenter.dx + 300,
        userCenter.dy + 600,
        userCenter.dx + 850,
        userCenter.dy + 550,
      );
    canvas.drawPath(river, waterPaint);

    // 4. Street Grid
    final streetPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (double y = 0; y <= size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }
    for (double x = 0; x <= size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
    }

    // 5. Major Arterial Highways
    final highwayPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3E33) : const Color(0xFFFBE4A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawLine(
      Offset(0, userCenter.dy - 60),
      Offset(size.width, userCenter.dy - 30),
      highwayPaint,
    );
    canvas.drawLine(
      Offset(userCenter.dx + 80, 0),
      Offset(userCenter.dx + 40, size.height),
      highwayPaint,
    );

    // 6. Concentric Distance Radius Rings around User (1 km, 3 km, 5 km)
    final ringPaint = Paint()
      ..color = AppColors.accentGold.withOpacity(isDark ? 0.12 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final km in [1.0, 3.0, 5.0]) {
      final radius = km * pixelsPerKm;
      canvas.drawCircle(userCenter, radius, ringPaint);
    }

    // 7. Route Polyline Trajectory to Selected Mosque
    if (selectedMosquePos != null) {
      // Glow underlay
      final glowPaint = Paint()
        ..color = AppColors.accentGold.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      // Solid route line
      final routePaint = Paint()
        ..color = AppColors.accentGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      final route = Path()
        ..moveTo(userCenter.dx, userCenter.dy)
        ..quadraticBezierTo(
          (userCenter.dx + selectedMosquePos!.dx) / 2 + 30,
          (userCenter.dy + selectedMosquePos!.dy) / 2 - 20,
          selectedMosquePos!.dx,
          selectedMosquePos!.dy,
        );

      canvas.drawPath(route, glowPaint);
      canvas.drawPath(route, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveMapPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.selectedMosquePos != selectedMosquePos;
  }
}
