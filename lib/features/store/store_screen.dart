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
                onTap: () => _showImageZoomDialog(context, 'assets/images/tshirt.jpeg'),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.asset(
                        'assets/images/tshirt.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1B0705),
                          child: const Center(
                            child: Icon(Icons.checkroom, size: 60, color: Colors.white30),
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
                          '₹499',
                          style: GoogleFonts.orbitron(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '₹799',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white38,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fest Subsidy Applied',
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
                    Row(
                      children: [
                        Text(
                          'Select Size: ',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 8,
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
                        label: Text(
                          'ORDER NOW ($_selectedSize) • OPEN FORM',
                          style: GoogleFonts.orbitron(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            letterSpacing: 0.8,
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

        // Tier 1: Silver Day Pass
        _buildPassCard(
          context: context,
          primaryColor: primaryColor,
          title: 'SILVER DAY PASS',
          badge: '1 DAY ACCESS',
          price: '₹299',
          originalPrice: '₹499',
          accentColor: const Color(0xFFB0BEC5),
          features: [
            '1-Day Full Access to Technical Events & Exhibitions',
            'Participation in any 2 Open Arenas & Workshops',
            'Evening Cultural Showcase & Stunt Show Entry',
            'Official Concetto Certificate of Participation',
          ],
        ),

        const SizedBox(height: 14),

        // Tier 2: Gold Fest Pass (Most Popular)
        _buildPassCard(
          context: context,
          primaryColor: primaryColor,
          title: 'GOLD FEST PASS',
          badge: 'MOST POPULAR • 4 DAYS',
          price: '₹699',
          originalPrice: '₹1,099',
          accentColor: const Color(0xFFFFB300),
          isFeatured: true,
          features: [
            'Complete 4-Day All-Event Access (All 39 Arenas)',
            'Eligibility for Mega Hackathons & Robotics Arena',
            'Star Night Musical Concert Entry (General Enclosure)',
            'Official Concetto Kit: Badge, Stickers & Lanyard',
            'Participation in Guest Lectures & Startup Conclave',
          ],
        ),

        const SizedBox(height: 14),

        // Tier 3: Centenary Diamond All-Access (VIP)
        _buildPassCard(
          context: context,
          primaryColor: primaryColor,
          title: 'CENTENARY DIAMOND PASS',
          badge: 'VIP + HOSTEL ACCOMMODATION',
          price: '₹1,499',
          originalPrice: '₹2,299',
          accentColor: const Color(0xFF00E5FF),
          features: [
            'Full 4-Day VIP All-Event & Arena Access',
            '4 Nights Campus Hostel Accommodation (Jasper/Rosaline)',
            'Campus Mess Food Coupons (Breakfast, Lunch & Dinner)',
            'Star Night VIP Front-Row Enclosure Access',
            'OFFICIAL CONCETTO\'26 T-SHIRT INCLUDED FOR FREE',
            'Priority Registration & Dedicated Campus Guide',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
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
            child: OutlinedButton.icon(
              onPressed: () => _showPassBookingSheet(context, title, price, accentColor),
              icon: Icon(Icons.bookmark_add, size: 16, color: accentColor),
              label: Text(
                'BOOK $title',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor.withValues(alpha: 0.7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modal for Pass Booking ---
  void _showPassBookingSheet(BuildContext context, String passTitle, String price, Color accentColor) {
    final nameCtrl = TextEditingController();
    final collegeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100504),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BOOK FESTIVAL PASS',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                Text(
                  '$passTitle • $price',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person, color: accentColor),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: collegeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'College / University Name',
                    prefixIcon: Icon(Icons.school, color: accentColor),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone, color: accentColor),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email, color: accentColor),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Pass reserved for ${nameCtrl.text.trim()}! Please confirm via email.'),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF140604),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'PROCEED TO RESERVE PASS',
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
