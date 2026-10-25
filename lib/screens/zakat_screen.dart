import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/floating_nav_dock.dart';
import 'main_navigation_shell.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final TextEditingController _wealthController =
      TextEditingController(text: '10000');
  final TextEditingController _deductionsController =
      TextEditingController(text: '0');

  int _selectedTab = 0; // 0: Quick estimate, 1: Asset breakdown
  String _selectedCurrency = 'USD';
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'AED', 'SAR', 'UGX'];

  // Nisab benchmarks
  static const double _silverNisabUsd = 610.0;
  static const double _goldNisabUsd = 7200.0;
  double _currentNisab = _silverNisabUsd;
  bool _useSilverStandard = true;

  bool _heldForLunarYear = true;

  // Asset breakdown controllers (when in breakdown tab)
  final TextEditingController _cashController =
      TextEditingController(text: '7000');
  final TextEditingController _goldController =
      TextEditingController(text: '2000');
  final TextEditingController _sharesController =
      TextEditingController(text: '1000');

  String _formatCurrency(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedWhole = whole.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedWhole.$decimal';
  }

  String _formatInt(int value) {
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return value.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  double get _totalAssets {
    if (_selectedTab == 1) {
      final cash = double.tryParse(_cashController.text.replaceAll(',', '')) ?? 0.0;
      final gold = double.tryParse(_goldController.text.replaceAll(',', '')) ?? 0.0;
      final shares = double.tryParse(_sharesController.text.replaceAll(',', '')) ?? 0.0;
      return cash + gold + shares;
    }
    return double.tryParse(_wealthController.text.replaceAll(',', '')) ?? 0.0;
  }

  double get _deductions {
    return double.tryParse(_deductionsController.text.replaceAll(',', '')) ?? 0.0;
  }

  double get _netWealth {
    final net = _totalAssets - _deductions;
    return net > 0 ? net : 0.0;
  }

  bool get _isNisabReached => _netWealth >= _currentNisab && _heldForLunarYear;

  double get _zakatDue => _isNisabReached ? (_netWealth * 0.025) : 0.0;

  @override
  void dispose() {
    _wealthController.dispose();
    _deductionsController.dispose();
    _cashController.dispose();
    _goldController.dispose();
    _sharesController.dispose();
    super.dispose();
  }

  void _resetToDefaults() {
    HapticFeedback.lightImpact();
    setState(() {
      _wealthController.text = '10000';
      _deductionsController.text = '0';
      _cashController.text = '7000';
      _goldController.text = '2000';
      _sharesController.text = '1000';
      _currentNisab = _silverNisabUsd;
      _useSilverStandard = true;
      _heldForLunarYear = true;
      _selectedTab = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Calculator reset to default estimate values',
          style: GoogleFonts.plusJakartaSans(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Currency',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF133827),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _currencies.map((c) {
                    final isSel = c == _selectedCurrency;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCurrency = c);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF133827)
                              : const Color(0xFFF3F7F4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          c,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBeneficiariesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F261B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final categories = [
          {
            'title': '1. The Poor (Al-Fuqara)',
            'desc': 'Those without any means of livelihood or sufficient income.'
          },
          {
            'title': '2. The Needy (Al-Masakin)',
            'desc': 'Those who have income but cannot meet basic life necessities.'
          },
          {
            'title': '3. Zakat Administrators (Al-Amilina)',
            'desc': 'Those appointed to collect, manage, and distribute Zakat funds.'
          },
          {
            'title': "4. Reconciling Hearts (Mu'allafat al-Qulub)",
            'desc': 'New Muslims or those whose friendship is sought for Islam.'
          },
          {
            'title': '5. Freeing Captives (Fir-Riqab)',
            'desc': 'Liberating slaves and freeing victims of human trafficking.'
          },
          {
            'title': '6. Debtors (Al-Gharimin)',
            'desc': 'Those burdened with debt taken for lawful basic necessities.'
          },
          {
            'title': '7. In the Cause of Allah (Fi Sabilillah)',
            'desc': 'Striving for the welfare and spiritual upliftment of Muslims.'
          },
          {
            'title': '8. The Stranded Traveler (Ibn al-Sabil)',
            'desc': 'Wayfarers traveling for lawful reasons who run out of funds.'
          },
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '8 Quranic Beneficiaries (Surah 9:60)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final c = categories[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF143324)
                            : const Color(0xFFF3F7F4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c['desc']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNisabRulesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F261B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nisab & Zakat Rules',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRuleRow(
                icon: Icons.access_time_filled_rounded,
                title: 'Hawl (1 Full Lunar Year)',
                desc: 'Wealth must be retained above Nisab for a complete lunar cycle (~354 days).',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildRuleRow(
                icon: Icons.toll_rounded,
                title: 'Silver Threshold (\$610 / 595g)',
                desc: 'The traditional standard recommended by classical scholars for cash and currency.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildRuleRow(
                icon: Icons.monetization_on_rounded,
                title: 'Gold Threshold (\$7,200 / 87.48g)',
                desc: 'Traditional gold nisab for precious metals and gold investments.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildRuleRow(
                icon: Icons.percent_rounded,
                title: 'Fixed Rate (2.5%)',
                desc: 'Zakat due is strictly 2.5% (one fortieth) of net eligible wealth.',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleRow({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF143324) : const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentGold, size: 20),
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
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewEstimateSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F261B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zakat Calculation Review',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF133827),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildReviewRow('Total Zakatable Assets',
                  '$_selectedCurrency ${_formatCurrency(_totalAssets)}'),
              _buildReviewRow('Eligible Deductions',
                  '$_selectedCurrency ${_formatCurrency(_deductions)}'),
              _buildReviewRow('Net Eligible Wealth',
                  '$_selectedCurrency ${_formatCurrency(_netWealth)}'),
              _buildReviewRow('Threshold (Nisab)',
                  '$_selectedCurrency ${_formatCurrency(_currentNisab)}'),
              _buildReviewRow('Status',
                  _isNisabReached ? '✓ Nisab Met (Eligible)' : 'Below Nisab'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Zakat Due (2.5%)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF133827),
                    ),
                  ),
                  Text(
                    '$_selectedCurrency ${_formatCurrency(_zakatDue)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B633D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCCA048),
                    foregroundColor: const Color(0xFF132B1F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    'Acknowledge & Save Estimate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF133827),
                        content: Text(
                          'JazakAllah Khair! Zakat estimate of $_selectedCurrency ${_formatCurrency(_zakatDue)} recorded.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Warm cream background matching reference design
    final bg = isDark ? const Color(0xFF0E1A14) : const Color(0xFFFBF8F2);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Scrollable Page Content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 120 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Pixel-Perfect Curved Dark Green Islamic Header
                  _buildTopHeader(isDark),

                  const SizedBox(height: 14),

                  // 2. Sub-header: "Wealth purification" & "Currency USD ∨"
                  _buildSubHeader(isDark),

                  const SizedBox(height: 14),

                  // 3. Segmented Tab Switch: [ Quick estimate ] vs [ Asset breakdown ]
                  _buildSegmentedTab(isDark),

                  const SizedBox(height: 14),

                  // 4. Main Card: "TOTAL ZAKATABLE ASSETS"
                  _buildTotalAssetsCard(isDark),

                  const SizedBox(height: 12),

                  // 5. Two Side-by-Side Cards: "Eligible deductions" & "Current Nisab"
                  _buildSideBySideCards(isDark),

                  const SizedBox(height: 6),

                  // Helper text below two cards
                  Text(
                    'Enter a verified gold or silver Nisab in your currency. No live price feed.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : const Color(0xFF7A756D),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 6. Checkbox Row: "Wealth held above Nisab for one lunar year"
                  _buildLunarYearCheckbox(isDark),

                  const SizedBox(height: 14),

                  // 7. Gold / Cream Summary Banner Card
                  _buildSummaryBanner(isDark),

                  const SizedBox(height: 14),

                  // 8. Action Pills: [ 👥 Recipients ] and [ ⓘ Nisab & rules ]
                  _buildActionPills(isDark),

                  const SizedBox(height: 16),

                  // 9. Bottom Action Row: [ ↺ ] Reset and [ Review estimate ↗ ]
                  _buildBottomActionRow(isDark),

                  const SizedBox(height: 10),

                  // Footer disclaimer
                  Center(
                    child: Text(
                      'Estimate only. Confirm your circumstances with a qualified scholar.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF888279),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 10. Reserved Floating Liquid Glass Navigation Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavDock(
              currentIndex: 0,
              onTabSelected: (idx) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => MainNavigationShell(initialIndex: idx),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Top Header: Deep Forest Green Container with Islamic Mufta Pattern
  Widget _buildTopHeader(bool isDark) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFF0F3826),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Islamic pattern overlay
          Positioned.fill(
            child: Image.asset(
              'assets/new_mufta.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xDF0F3826),
                    Color(0xF0103A26),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Circular back button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationShell(initialIndex: 0),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.14),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zakat al-Mal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '3rd pillar of Islam • زكاة المال',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFC7DEC9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Green 2.5% pill badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF163E2B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4ADE80).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '2.5%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Sub-header: "Wealth purification" shield + "Currency USD ∨" selector
  Widget _buildSubHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: Color(0xFF1B633D),
            ),
            const SizedBox(width: 6),
            Text(
              'Wealth purification',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF68D391) : const Color(0xFF1B633D),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _showCurrencySelector,
          child: Row(
            children: [
              Text(
                'Currency',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF7A756D),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF173022) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedCurrency,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3. Segmented Tab: [ Quick estimate ] vs [ Asset breakdown ]
  Widget _buildSegmentedTab(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162D20) : const Color(0xFFEFE9DC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? (isDark ? const Color(0xFF1F422E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Quick estimate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight:
                          _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                      color: _selectedTab == 0
                          ? (isDark ? Colors.white : const Color(0xFF132B1F))
                          : (isDark ? Colors.white60 : const Color(0xFF7A756D)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? (isDark ? const Color(0xFF1F422E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Asset breakdown',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight:
                          _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                      color: _selectedTab == 1
                          ? (isDark ? Colors.white : const Color(0xFF132B1F))
                          : (isDark ? Colors.white60 : const Color(0xFF7A756D)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Main Card: "TOTAL ZAKATABLE ASSETS"
  Widget _buildTotalAssetsCard(bool isDark) {
    final cardBg = isDark ? const Color(0xFF152E20) : Colors.white;

    if (_selectedTab == 1) {
      // Detailed Asset Breakdown mode
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: Color(0xFFCCA048),
                ),
                const SizedBox(width: 8),
                Text(
                  'ASSET BREAKDOWN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark ? Colors.white70 : const Color(0xFF7A756D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBreakdownField('Cash & Bank', _cashController, isDark),
            const SizedBox(height: 8),
            _buildBreakdownField('Gold & Silver Value', _goldController, isDark),
            const SizedBox(height: 8),
            _buildBreakdownField('Shares & Investments', _sharesController, isDark),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Color(0xFFCCA048),
              ),
              const SizedBox(width: 8),
              Text(
                'TOTAL ZAKATABLE ASSETS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white70 : const Color(0xFF7A756D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _wealthController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownField(
      String label, TextEditingController ctrl, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCCA048)),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  /// 5. Two Side-by-Side Cards: "Eligible deductions" & "Current Nisab"
  Widget _buildSideBySideCards(bool isDark) {
    final cardBg = isDark ? const Color(0xFF152E20) : Colors.white;

    return Row(
      children: [
        // Left Card: Eligible deductions
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eligible deductions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF7A756D),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _deductionsController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right Card: Current Nisab (USD)
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _useSilverStandard = !_useSilverStandard;
                _currentNisab = _useSilverStandard ? _silverNisabUsd : _goldNisabUsd;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Nisab ($_selectedCurrency)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : const Color(0xFF7A756D),
                        ),
                      ),
                      const Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: AppColors.accentGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatInt(_currentNisab.toInt()),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 6. Checkbox Row: "Wealth held above Nisab for one lunar year"
  Widget _buildLunarYearCheckbox(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _heldForLunarYear = !_heldForLunarYear);
      },
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _heldForLunarYear
                  ? const Color(0xFFCCA048)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _heldForLunarYear
                    ? const Color(0xFFCCA048)
                    : (isDark ? Colors.white38 : const Color(0xFF9E988F)),
                width: 1.5,
              ),
            ),
            child: _heldForLunarYear
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wealth held above Nisab for one lunar year',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF2D2A26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 7. Gold / Cream Summary Banner Card
  Widget _buildSummaryBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A29) : const Color(0xFFFAF2DC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFCCA048).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCCA048).withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Net wealth & Nisab status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net wealth • $_selectedCurrency ${_formatCurrency(_netWealth)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF5A5348),
                ),
              ),
              if (_isNisabReached)
                Row(
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Nisab reached',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Below Nisab',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Middle Row: Zakah estimate & Bold Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zakah estimate',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '2.5% of eligible net wealth',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF7A756D),
                    ),
                  ),
                ],
              ),
              Text(
                '\$${_formatCurrency(_zakatDue)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF68D391) : const Color(0xFF165C38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 8. Action Pills: [ 👥 Recipients ] and [ ⓘ Nisab & rules ]
  Widget _buildActionPills(bool isDark) {
    final pillBg = isDark ? const Color(0xFF162E20) : Colors.white;

    return Row(
      children: [
        // Recipients Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showBeneficiariesSheet();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 16,
                    color: Color(0xFFCCA048),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recipients',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1C1917),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Nisab & Rules Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showNisabRulesSheet();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFFCCA048),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nisab & rules',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1C1917),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 9. Bottom Action Row: [ ↺ ] Reset and [ Review estimate ↗ ]
  Widget _buildBottomActionRow(bool isDark) {
    return Row(
      children: [
        // Circular Reset Button
        GestureDetector(
          onTap: _resetToDefaults,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF162E20) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF292524),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Golden Gradient Review Estimate Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showReviewEstimateSheet();
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFCCA048),
                    Color(0xFF986F20),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCCA048).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: Color(0xFF0F261B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Review estimate ↗',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F261B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
