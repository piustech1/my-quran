import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  // Calculator inputs
  final TextEditingController _cashController = TextEditingController(text: '0');
  final TextEditingController _goldSilverController = TextEditingController(text: '0');
  final TextEditingController _investmentsController = TextEditingController(text: '0');
  final TextEditingController _inventoryController = TextEditingController(text: '0');
  final TextEditingController _debtsController = TextEditingController(text: '0');

  // Nisab reference (USD)
  final double _silverNisabUsd = 580.0;
  final double _goldNisabUsd = 6820.0;

  // Selected quick donation tier
  int _selectedDonationTier = 50;
  final List<int> _tiers = [10, 25, 50, 100, 250];

  double get _totalAssets {
    final cash = double.tryParse(_cashController.text.replaceAll(',', '')) ?? 0.0;
    final gold = double.tryParse(_goldSilverController.text.replaceAll(',', '')) ?? 0.0;
    final inv = double.tryParse(_investmentsController.text.replaceAll(',', '')) ?? 0.0;
    final inventory = double.tryParse(_inventoryController.text.replaceAll(',', '')) ?? 0.0;
    return cash + gold + inv + inventory;
  }

  double get _totalDebts {
    return double.tryParse(_debtsController.text.replaceAll(',', '')) ?? 0.0;
  }

  double get _netWealth {
    final net = _totalAssets - _totalDebts;
    return net > 0 ? net : 0.0;
  }

  bool get _isEligible => _netWealth >= _silverNisabUsd;

  double get _zakatDue => _isEligible ? (_netWealth * 0.025) : 0.0;

  @override
  void dispose() {
    _cashController.dispose();
    _goldSilverController.dispose();
    _investmentsController.dispose();
    _inventoryController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? Colors.white : AppColors.lightTextPrimary;
    final textSecondary = isDark ? Colors.white60 : AppColors.lightTextSecondary;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Hero Orientation Header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Hero Image
                Image.asset(
                  'assets/zakat_hero.jpg',
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                // Emerald & Dark Gradient Overlays
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        const Color(0xFF0D281C).withOpacity(0.85),
                        isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      ],
                    ),
                  ),
                ),

                // Top Back Button & Title
                Positioned(
                  top: topPadding + 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.40),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accentGold, width: 0.8),
                        ),
                        child: Text(
                          '3RD PILLAR OF ISLAM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Orientation Hero Title
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zakat al-Mal (زكاة المال)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purifying Wealth & Uplifting the Ummah',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Educational Orientation Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuranicVerseCard(isDark),
                  const SizedBox(height: 20),
                  _buildNisabTrackerCards(isDark),
                  const SizedBox(height: 24),

                  // 3. Interactive Real-Time Calculator
                  Text(
                    'ZAKAT CALCULATOR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calculate your annual 2.5% obligation accurately',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildCalculatorCard(isDark, textPrimary, textSecondary),

                  const SizedBox(height: 24),

                  // 4. Who Receives Zakat (8 Categories)
                  Text(
                    'WHO RECEIVES ZAKAT?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.accentGold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The 8 eligible recipient categories defined in Surah At-Tawbah 9:60',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBeneficiariesSection(isDark),

                  const SizedBox(height: 26),

                  // 5. Pay Zakat via Google Play
                  _buildGooglePlayPaymentSection(isDark, textPrimary, textSecondary),
                  const SizedBox(height: 120), // Bottom scroll clearance
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranicVerseCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13281E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFFE5B850).withOpacity(0.3) : const Color(0xFFE5B850).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.accentGold, size: 22),
              const SizedBox(width: 8),
              Text(
                'SURAH AT-TAWBAH 9:103',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'خُذْ مِنْ أَمْوَالِهِمْ صَدَقَةً تُطَهِّرُهُمْ وَتُزَكِّيهِم بِهَا',
            textAlign: TextAlign.right,
            style: GoogleFonts.amiri(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"Take from their wealth a charity by which you purify them and cause them increase..."',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNisabTrackerCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14291E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SILVER NISAB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                    const Icon(Icons.circle, size: 8, color: Colors.blueGrey),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${_silverNisabUsd.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '612.36 grams of silver (Recommended standard)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14291E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GOLD NISAB',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: AppColors.accentGold,
                      ),
                    ),
                    const Icon(Icons.circle, size: 8, color: AppColors.accentGold),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${_goldNisabUsd.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '87.48 grams of gold (~7.5 tola)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorCard(bool isDark, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13281E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalcInput(
            label: 'Cash in Hand & Bank Accounts',
            controller: _cashController,
            icon: Icons.account_balance_wallet_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildCalcInput(
            label: 'Gold, Silver & Precious Metals Value',
            controller: _goldSilverController,
            icon: Icons.diamond_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildCalcInput(
            label: 'Shares, Stocks & Liquid Investments',
            controller: _investmentsController,
            icon: Icons.trending_up_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildCalcInput(
            label: 'Trade Merchandise / Business Inventory',
            controller: _inventoryController,
            icon: Icons.store_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildCalcInput(
            label: 'Less: Debts Due Immediately',
            controller: _debtsController,
            icon: Icons.remove_circle_outline_rounded,
            isDark: isDark,
            isDeduction: true,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Net Calculation Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Zakatable Pool:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              Text(
                '\$${_netWealth.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nisab Threshold Status:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _isEligible
                      ? Colors.green.withOpacity(0.18)
                      : Colors.orange.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isEligible ? 'Above Nisab (Obligated)' : 'Below Nisab (Exempt)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isEligible ? Colors.greenAccent.shade700 : Colors.orangeAccent.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Zakat Due Badge
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF133827), Color(0xFF1E4D36)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentGold.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ZAKAT DUE (2.5%)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppColors.accentGold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Payable annually',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${_zakatDue.toStringAsFixed(2)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    bool isDeduction = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDeduction ? Colors.redAccent : AppColors.accentGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    prefixText: '\$ ',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiariesSection(bool isDark) {
    final categories = [
      {'name': 'Al-Fuqara', 'desc': 'The poor lacking basic needs'},
      {'name': 'Al-Masakin', 'desc': 'The needy in economic distress'},
      {'name': 'Amilina Alayha', 'desc': 'Zakat administrators & workers'},
      {'name': 'Mu\'allafatu Qulub', 'desc': 'Reconciling hearts & new Muslims'},
      {'name': 'Fir-Riqab', 'desc': 'Freeing from debt servitude / bondage'},
      {'name': 'Al-Gharimin', 'desc': 'Those overwhelmed by unavoidable debt'},
      {'name': 'Fi Sabilillah', 'desc': 'In the cause of Allah & community'},
      {'name': 'Ibnus-Sabil', 'desc': 'Stranded travelers with no funds'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((c) {
        return Container(
          width: (MediaQuery.of(context).size.width - 46) / 2,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13281E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c['name']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                c['desc']!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGooglePlayPaymentSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14291E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.40 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF133827),
                ),
                child: const Icon(Icons.shop_two_rounded, color: AppColors.accentGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay Zakat via Google Play',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Direct secure Google Play in-app contribution',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tiers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _tiers.map((tier) {
              final isSelected = _selectedDonationTier == tier;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDonationTier = tier);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF133827)
                        : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.accentGold : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '\$$tier',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.accentGold : textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Google Play Pay Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF133827),
              foregroundColor: AppColors.accentGold,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
            onPressed: () => _triggerGooglePlayPayment(context, _selectedDonationTier),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment_rounded, color: AppColors.accentGold, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Donate \$$_selectedDonationTier via Google Play',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 12, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                'Google Play Protected · Certified 100% Zakat Distribution',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _triggerGooglePlayPayment(BuildContext context, int amount) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF122419) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Play In-App Billing',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Zakat Al-Mal Contribution: \$$amount.00 USD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded, color: AppColors.accentGold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Linked to your Google Play Store Account\n(Credit Card, Carrier Billing, or Google Pay)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jazakallahu Khair! Your Zakat contribution of \$$amount has been received.'),
                      backgroundColor: const Color(0xFF133827),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                child: Text(
                  '1-Tap Buy with Google Play (\$$amount)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
