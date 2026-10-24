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

class _MosqueFinderScreenState extends State<MosqueFinderScreen> {
  final MosqueService _mosqueService = MosqueService();
  final LocationWeatherService _weatherService = LocationWeatherService();
  final TextEditingController _searchController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
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
    }
  }

  void _onFilterSelected(String filter) async {
    setState(() {
      _activeFilter = filter;
      _isLoading = true;
    });

    final results = await _mosqueService.fetchNearbyMosques(
      userLat: _userLocation?.lat ?? 0.3476,
      userLon: _userLocation?.lon ?? 32.5825,
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
    }
  }

  void _onSearchChanged(String query) async {
    final results = await _mosqueService.fetchNearbyMosques(
      userLat: _userLocation?.lat ?? 0.3476,
      userLon: _userLocation?.lon ?? 32.5825,
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
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Maps Styled Vector Map Canvas
          Positioned.fill(
            child: _GoogleMapsCanvas(
              isDark: isDark,
              mosques: _mosques,
              selectedMosque: _selectedMosque,
              onMosqueTapped: _selectMosque,
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

          // 3. Map Control Floating Action Buttons (Recenter & Compass)
          Positioned(
            right: 16,
            bottom: 230 + bottomPadding,
            child: Column(
              children: [
                _buildMapActionButton(
                  icon: Icons.layers_rounded,
                  tooltip: 'Map Layer',
                  isDark: isDark,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to Islamic Terrain Map mode'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildMapActionButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Recenter on my location',
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (_mosques.isNotEmpty) {
                      _selectMosque(_mosques.first);
                    }
                  },
                ),
              ],
            ),
          ),

          // 4. Bottom Sliding Mosque Cards Carousel (Mimics Google Maps Place Carousel)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding > 0 ? bottomPadding + 10 : 20,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                  )
                : _mosques.isEmpty
                    ? _buildEmptyState(isDark)
                    : SizedBox(
                        height: 200,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _mosques.length,
                          onPageChanged: (idx) {
                            setState(() => _selectedMosque = _mosques[idx]);
                          },
                          itemBuilder: (context, idx) {
                            final m = _mosques[idx];
                            return _buildMosqueCard(m, isDark);
                          },
                        ),
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
        color: isDark ? const Color(0xFF1E2D24) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06),
          width: 1,
        ),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search mosques, Jamaat, address...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              color: isDark ? Colors.white70 : Colors.black54,
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF133827),
            ),
            child: const Icon(
              Icons.mosque_rounded,
              color: AppColors.accentGold,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _activeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onFilterSelected(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF133827)
                      : (isDark ? const Color(0xFF1E2D24) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentGold
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  f,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? AppColors.accentGold
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1E2D24) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: isDark ? AppColors.accentGold : const Color(0xFF133827),
        ),
      ),
    );
  }

  Widget _buildMosqueCard(MosqueModel m, bool isDark) {
    final isSelected = _selectedMosque?.id == m.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14291E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? AppColors.accentGold
              : (isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.06)),
          width: isSelected ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.50 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mosque Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.asset(
                  m.imageUrl,
                  width: 90,
                  height: 140,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF133827).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${m.distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (m.isVerified)
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.accentGold,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                        const SizedBox(width: 3),
                        Text(
                          '${m.rating}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                  ],
                ),

                // Action Buttons Row: Directions & Details
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF133827),
                          foregroundColor: AppColors.accentGold,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _showMosqueDetailsSheet(m, isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  void _showMosqueDetailsSheet(MosqueModel m, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF11251A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          m.arabicName,
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${m.distanceKm.toStringAsFixed(1)} km away',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Facilities & Amenities',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: m.facilities.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Text(
                      f,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF133827),
                        foregroundColor: AppColors.accentGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('Start Navigation'),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        MosqueService.launchGoogleMapsDirections(
                          m.lat,
                          m.lon,
                          m.name,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                    ),
                    icon: const Icon(Icons.phone_rounded),
                    onPressed: () => MosqueService.callMosque(m.phone),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Google Maps Styled Interactive Canvas
class _GoogleMapsCanvas extends StatelessWidget {
  final bool isDark;
  final List<MosqueModel> mosques;
  final MosqueModel? selectedMosque;
  final ValueChanged<MosqueModel> onMosqueTapped;

  const _GoogleMapsCanvas({
    required this.isDark,
    required this.mosques,
    required this.selectedMosque,
    required this.onMosqueTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Custom Painted Roads, Rivers, Greenery, Grid
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _MapGridPainter(isDark: isDark),
            ),

            // User GPS Location Blue Glowing Beacon (Center-ish)
            Positioned(
              left: constraints.maxWidth * 0.48 - 14,
              top: constraints.maxHeight * 0.45 - 14,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.24),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Mosque Pins on Map
            ...List.generate(mosques.length, (idx) {
              final m = mosques[idx];
              final isSelected = selectedMosque?.id == m.id;

              // Distribute pins across realistic map screen locations
              final pinOffsets = [
                Offset(constraints.maxWidth * 0.32, constraints.maxHeight * 0.30),
                Offset(constraints.maxWidth * 0.68, constraints.maxHeight * 0.36),
                Offset(constraints.maxWidth * 0.22, constraints.maxHeight * 0.52),
                Offset(constraints.maxWidth * 0.76, constraints.maxHeight * 0.58),
                Offset(constraints.maxWidth * 0.52, constraints.maxHeight * 0.22),
              ];
              final pos = pinOffsets[idx % pinOffsets.length];

              return Positioned(
                left: pos.dx - 22,
                top: pos.dy - 44,
                child: GestureDetector(
                  onTap: () => onMosqueTapped(m),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF133827) : (isDark ? const Color(0xFF1B3224) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accentGold : Colors.black12,
                            width: isSelected ? 1.5 : 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          m.name.split(' ').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.accentGold : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 42 : 34,
                        height: isSelected ? 42 : 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF133827) : const Color(0xFF1C4933),
                          border: Border.all(
                            color: isSelected ? AppColors.accentGold : Colors.white,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? AppColors.accentGold : Colors.black).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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
        );
      },
    );
  }
}

/// Custom Vector Map Painter rendering Google Maps-style streets, greenery & water
class _MapGridPainter extends CustomPainter {
  final bool isDark;

  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Background terrain
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF121B16) : const Color(0xFFE8ECE9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Green Parks & Nature Reserves
    final parkPaint = Paint()
      ..color = isDark ? const Color(0xFF162B1F) : const Color(0xFFD2E6D5);

    final parkPath1 = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(20, size.height * 0.15, size.width * 0.38, size.height * 0.22),
        const Radius.circular(40),
      ));
    canvas.drawPath(parkPath1, parkPaint);

    final parkPath2 = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.45, size.width * 0.40, size.height * 0.20),
        const Radius.circular(50),
      ));
    canvas.drawPath(parkPath2, parkPaint);

    // Blue Water / River curve
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF102830) : const Color(0xFFC7DEEC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final river = Path()
      ..moveTo(-10, size.height * 0.70)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.65,
        size.width + 10,
        size.height * 0.85,
      );
    canvas.drawPath(river, waterPaint);

    // Minor Streets Grid
    final streetPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (double y = 80; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }
    for (double x = 40; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
    }

    // Major Arterial Highways
    final highwayPaint = Paint()
      ..color = isDark ? const Color(0xFF2C3E33) : const Color(0xFFFBE4A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final h1 = Path()
      ..moveTo(0, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.42);
    canvas.drawPath(h1, highwayPaint);

    final h2 = Path()
      ..moveTo(size.width * 0.50, 0)
      ..lineTo(size.width * 0.46, size.height);
    canvas.drawPath(h2, highwayPaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
