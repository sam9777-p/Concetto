import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class MerchandiseScreen extends StatefulWidget {
  const MerchandiseScreen({super.key});

  @override
  State<MerchandiseScreen> createState() => _MerchandiseScreenState();
}

class _MerchandiseScreenState extends State<MerchandiseScreen> {
  String _selectedSize = 'M';
  final List<String> _sizes = ['S', 'M', 'L', 'XL', 'XXL'];

  // User-provided official merchandise form link
  static const String _merchFormUrl =
      'https://docs.google.com/forms/d/1YH3YaouuGGCdojzgFMKLKArhAHH8GGsszZ7CQg2HzN0/viewform';

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'STORE & MERCHANDISE',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Notice
            _buildStoreHeaderBanner(primaryColor)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 20),

            // 1. Official T-Shirt Section
            _buildTShirtSection(context, primaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 32),

            // 2. Festival Passes Section
            _buildPassesSection(context, primaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- Top Header Banner ---
  Widget _buildStoreHeaderBanner(Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF140604),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.checkroom, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CENTAURI SYNAPSE • OFFICIAL GEAR',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'IIT (ISM) Dhanbad Centenary Edition Apparel & Delegate Passes',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Official T-Shirt Showcase ---
  Widget _buildTShirtSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, size: 20, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'OFFICIAL FESTIVAL T-SHIRT',
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '38% OFF',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // T-Shirt Card
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF100504),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryColor.withValues(alpha: 0.45), width: 1),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster Image
              GestureDetector(
                onTap: () => _showImageZoomDialog(context, 'assets/merch_official.png'),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.asset(
                        'assets/merch_official.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/tshirt.jpeg',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: const Color(0xFF1B0705),
                            child: const Center(
                              child: Icon(Icons.checkroom, size: 60, color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.zoom_in, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Tap to Zoom',
                              style: TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFF100504),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // T-Shirt Details
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Concetto'26 Official Centauri Synapse T-Shirt",
                      style: GoogleFonts.rajdhani(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Premium 240 GSM Bio-Washed Combed Cotton • Screen-Printed Rocket & Barcode Graphics • Glow-in-the-Dark Centenary Detailing',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.metallicMuted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹379',
                          style: GoogleFonts.orbitron(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹599',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white38,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '37% OFF • Fest Subsidy',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Size Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SELECT SIZE:',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sizes.map((size) {
                            final isSelected = _selectedSize == size;
                            return ChoiceChip(
                              label: Text(
                                size,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : Colors.white,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: primaryColor,
                              backgroundColor: const Color(0xFF1E0907),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected ? primaryColor : Colors.white24,
                                ),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedSize = size;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Buy Now CTA Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE85002),
                            Color(0xFFFF6F00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _launchMerchOrderForm(context),
                        icon: const Icon(Icons.shopping_bag, color: Colors.black, size: 20),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'ORDER NOW ($_selectedSize) • OPEN FORM',
                            style: GoogleFonts.orbitron(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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

  // --- 2. Festival Passes Section (3 Tiers for Outside College Participants) ---
  Widget _buildPassesSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.confirmation_number_outlined, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'OUTSIDE COLLEGE PASSES',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Official delegate & entry access packages for participants from other universities',
          style: GoogleFonts.rajdhani(fontSize: 12, color: AppTheme.metallicMuted),
        ),
        const SizedBox(height: 16),

        // Tier 1: Silver Pass (1-Day)
        _buildPassCard(
          context: context,
          primaryColor: primaryColor,
          title: 'SILVER PASS (1-DAY)',
          badge: '1 DAY FOOD + STAY & ALL EVENTS',
          price: '₹499',
          originalPrice: '₹799',
          accentColor: const Color(0xFFCFD8DC),
          features: [
            '1 Day Campus Stay & Hostel Accommodation',
            '1 Day Complete Food & Mess Facility',
            'All-Event Access & Competitions Entry',
            'Evening Cultural Showcase & Stunt Shows',
            'Official Concetto Certificate of Participation',
          ],
        ),

        const SizedBox(height: 14),

        // Tier 2: Gold Pass (2-Day)
        _buildPassCard(
          context: context,
          primaryColor: primaryColor,
          title: 'GOLD PASS (2-DAY)',
          badge: '2 DAY FOOD + STAY & ALL EVENTS',
          price: '₹699',
          originalPrice: '₹1,099',
          accentColor: const Color(0xFFFFB300),
          features: [
            '2 Days Campus Stay & Hostel Accommodation',
            '2 Days Complete Food & Mess Facility',
            'Complete Access to All Events & Open Arenas',
            'Eligibility for Hackathons & Robotics Arena',
            'Official Concetto Delegate Kit & Certificate',
          ],
        ),

        const SizedBox(height: 14),

        // Tier 3: Diamond Pass (3-Day)
        _buildPassCard(
          context: context,
          primaryColor: primaryColor,
          title: 'DIAMOND PASS (3-DAY)',
          badge: '3 DAY FOOD + STAY & ALL EVENTS',
          price: '₹999',
          originalPrice: '₹1,499',
          accentColor: const Color(0xFF00E5FF),
          isFeatured: true,
          features: [
            'Full 3 Days Campus Stay & Hostel Accommodation',
            'Full 3 Days Complete Food & Mess Facility',
            'All-Event VIP & Arena Access Across the Fest',
            'Celebrity Star Night Concert Enclosure Entry',
            'Official Concetto Kit & Dedicated Guidance',
          ],
        ),

        const SizedBox(height: 14),

        // Tier 4: Diamond Elite + Merchandise Pass (3-Day)
        _buildPassCard(
          context: context,
          primaryColor: primaryColor,
          title: 'DIAMOND+ MERCH PASS',
          badge: '3 DAY FOOD + STAY + MERCHANDISE & ALL EVENTS',
          price: '₹1,249',
          originalPrice: '₹1,999',
          accentColor: const Color(0xFFFF4081),
          isFeatured: true,
          features: [
            'Full 3 Days Campus Stay & Hostel Accommodation',
            'Full 3 Days Complete Food & Mess Facility',
            'OFFICIAL CONCETTO\'26 MERCHANDISE / T-SHIRT INCLUDED',
            'Complete All-Event Access Across All 3 Fest Days',
            'Star Night VIP Front-Row Concert Access',
            'Centenary Edition Fest Badge, Mementos & Goodies',
          ],
        ),
      ],
    );
  }

  Widget _buildPassCard({
    required BuildContext context,
    required Color primaryColor,
    required String title,
    required String badge,
    required String price,
    required String originalPrice,
    required Color accentColor,
    required List<String> features,
    bool isFeatured = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF100504),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFeatured ? primaryColor : accentColor.withValues(alpha: 0.45),
          width: isFeatured ? 1.5 : 0.8,
        ),
        boxShadow: isFeatured
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 0.8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                originalPrice,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white38,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Per Participant',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          // Features List
          ...features.map(
            (feat) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 14, color: accentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feat,
                      style: GoogleFonts.rajdhani(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _openPassBookingForm(context, title, price),
              icon: const Icon(Icons.open_in_new, size: 16, color: Colors.black),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'BOOK $title • $price',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.black,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Official Pass Google Form Link provided by user
  static const String _passGoogleFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSeCjdcCQyPqFwwD9D_7Mg_nYfUm-U7tLY2RbjJOP33V6a42kg/viewform';

  Future<void> _openPassBookingForm(BuildContext context, String passTitle, String price) async {
    final uri = Uri.parse(_passGoogleFormUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open pass registration form: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- Zoom Image Dialog ---
  void _showImageZoomDialog(BuildContext context, String assetPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.asset(assetPath),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black87,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // --- Launch Google Form for T-Shirt ---
  Future<void> _launchMerchOrderForm(BuildContext context) async {
    final uri = Uri.parse(_merchFormUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open external merchandise form link'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching form: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
