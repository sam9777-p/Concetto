import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/auth_provider.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/core_team_member.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/widgets/admin_login_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final user = ref.watch(authProvider);
    final teamAsync = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ATTENDEE PORTAL',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
        ),
        centerTitle: false,
        actions: [
          if (!user.isGuest)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out of festival account.')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Digital Fest Pass
            _buildDigitalFestPass(user, primaryColor)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 20),

            // 2. Auth Action Button
            if (user.isGuest)
              _buildAuthActionButton(context, primaryColor)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
            else
              _buildUserStatusBanner(user, primaryColor)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 18),

            // Organizer Portal Card
            _buildOrganizerPortalCard(context, primaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 32),

            // 3. Core Team Directory
            _buildTeamDirectorySection(teamAsync, primaryColor, secondaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 32),

            // 4. Festival Sponsors Section
            _buildSponsorsSection(primaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 32),

            // 5. Accommodation & Campus Guide
            _buildAccommodationGuide(primaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 32),

            // 6. Helpdesk & Emergency Contact
            _buildHelpdeskCard(primaryColor, secondaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 500.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 1. Digital Fest Pass ---
  Widget _buildDigitalFestPass(AttendeeProfile user, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E0805),
            Color(0xFF0F0403),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: primaryColor.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.16),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Virtual Lanyard Slot
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
            ),
          ),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/logo_final.webp', height: 32),
                  const SizedBox(width: 8),
                  Text(
                    "CONCETTO '26 PASS",
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isGuest
                      ? Colors.amber.withValues(alpha: 0.15)
                      : const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: user.isGuest ? Colors.amber : const Color(0xFF00E676),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: user.isGuest ? Colors.amber : const Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fade(begin: 0.4, end: 1.0, duration: 800.ms),
                    const SizedBox(width: 6),
                    Text(
                      user.isGuest ? 'GUEST PASS' : 'VERIFIED PASS',
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: user.isGuest ? Colors.amber : const Color(0xFF00E676),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // User Info & QR Code Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.rajdhani(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.college,
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.metallicMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PASS IDENTIFIER (TAP TO COPY)',
                      style: GoogleFonts.rajdhani(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: user.passId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 16),
                                const SizedBox(width: 8),
                                Text('Copied ${user.passId} to clipboard!'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF140604),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.passId,
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.copy, size: 12, color: primaryColor.withValues(alpha: 0.8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Visual QR Badge with Framed Corner Brackets
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.7), width: 1.2),
                ),
                child: Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: CustomPaint(
                    painter: MockQRPainter(primaryColor: primaryColor),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 6),

          // Pass Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VALID: OCT 10 - 12, 2026',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'IIT (ISM) DHANBAD',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. Auth Action Button ---
  Widget _buildAuthActionButton(BuildContext context, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showAuthModal(context, primaryColor),
        icon: const Icon(Icons.login),
        label: const Text(
          'SIGN IN / REGISTER FEST ACCOUNT',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildUserStatusBanner(AttendeeProfile user, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Signed in as ${user.email}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: Text(
              'LOGOUT',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2b. Organizer & Club Portal ---
  Widget _buildOrganizerPortalCard(BuildContext context, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.4), width: 1),
        gradient: AppTheme.darkCardGradient,
        boxShadow: AppTheme.neonGlow(opacity: 0.15, blur: 10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            AdminLoginDialog.show(
              context,
              onSuccess: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen(),
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.neonOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.neonOrange, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ORGANIZER PORTAL',
                            style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.cyberAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.cyberAmber, width: 0.8),
                            ),
                            child: Text(
                              'CLUB HEADS',
                              style: GoogleFonts.rajdhani(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cyberAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Manage, add, and publish festival events',
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          color: AppTheme.metallicMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.neonOrange),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 3. Core Team Directory ---
  Widget _buildTeamDirectorySection(
    AsyncValue<List<CoreTeamMember>> teamAsync,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.groups_2, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'ORGANIZING COMMITTEE',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        teamAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading team: $err'),
          data: (team) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: team.length,
              itemBuilder: (context, index) {
                final member = team[index];
                return _buildTeamMemberCard(member, primaryColor);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTeamMemberCard(CoreTeamMember member, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF110604),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(member.imageUrl),
              backgroundColor: primaryColor.withValues(alpha: 0.15),
              child: member.imageUrl.isEmpty
                  ? Icon(Icons.person, color: primaryColor, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.role} • ${member.vertical}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor.withValues(alpha: 0.9),
                  ),
                ),
                if (member.year.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.year,
                    style: GoogleFonts.rajdhani(fontSize: 11, color: AppTheme.metallicMuted),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.email_outlined, size: 18),
                color: primaryColor,
                tooltip: 'Copy Email',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: member.email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied email: ${member.email}'),
                      backgroundColor: const Color(0xFF140604),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined, size: 18),
                color: primaryColor,
                tooltip: 'Copy Phone',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: member.phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied phone: ${member.phone}'),
                      backgroundColor: const Color(0xFF140604),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 4. Sponsors Section ---
  Widget _buildSponsorsSection(Color primaryColor) {
    final sponsors = [
      {'tier': 'TITLE SPONSOR', 'name': 'Centenary Innovation Lab', 'category': 'Tech Partner'},
      {'tier': 'ASSOCIATE SPONSOR', 'name': 'Tata Steel & Mining', 'category': 'Industry Leader'},
      {'tier': 'POWERED BY', 'name': 'NVCTI Innovation Hub', 'category': 'Incubation'},
      {'tier': 'MEDIA PARTNER', 'name': 'Eastern Tech Chronicle', 'category': 'Outreach'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.workspace_premium, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'FESTIVAL PARTNERS & SPONSORS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: sponsors.length,
          itemBuilder: (context, index) {
            final s = sponsors[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF100605),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s['tier']!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['category']!,
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --- 5. Accommodation Guide ---
  Widget _buildAccommodationGuide(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF100605),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Campus Accommodation & Stay',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Hostel rooms are available for registered outstation participants from October 9 to October 13, 2026 at IIT (ISM) Dhanbad.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 10),
          _buildBulletItem('Check-in counter open 24x7 at Jasper & Rosaline Hostels'),
          _buildBulletItem('Valid Student College ID & Concetto Pass required'),
          _buildBulletItem('Campus mess coupons provided at reporting desk'),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 14)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // --- 6. Helpdesk Card ---
  Widget _buildHelpdeskCard(Color primaryColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF100605),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FESTIVAL HELPDESK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.white60),
              const SizedBox(width: 8),
              const Text('+91 85030 86164 / +91 326 223 5400', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.email, size: 14, color: Colors.white60),
              const SizedBox(width: 8),
              const Text('concetto@iitism.ac.in', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.public, size: 14, color: Colors.white60),
              const SizedBox(width: 8),
              const Text('https://concetto.in', style: TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Auth Modal Sheet ---
  void _showAuthModal(BuildContext context, Color primaryColor) {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();
    final collegeController = TextEditingController();
    bool isSignUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100605),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          isSignUp ? 'CREATE FEST ACCOUNT' : 'ATTENDEE SIGN IN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isSignUp) ...[
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person, color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: collegeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'College / Institute',
                          prefixIcon: Icon(Icons.school, color: primaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (emailController.text.trim().isEmpty) return;

                          Navigator.pop(sheetContext);
                          if (isSignUp) {
                            await ref.read(authProvider.notifier).signUpWithEmail(
                                  name: nameController.text.trim().isNotEmpty
                                      ? nameController.text.trim()
                                      : 'Attendee',
                                  email: emailController.text.trim(),
                                  password: passController.text,
                                  college: collegeController.text.trim().isNotEmpty
                                      ? collegeController.text.trim()
                                      : 'College Participant',
                                  phone: '+91 85030 86164',
                                );
                          } else {
                            await ref.read(authProvider.notifier).signInWithEmail(
                                  emailController.text.trim(),
                                  passController.text,
                                );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          isSignUp ? 'SIGN UP' : 'SIGN IN',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            isSignUp = !isSignUp;
                          });
                        },
                        child: Text(
                          isSignUp
                              ? 'Already have an account? Sign In'
                              : "Don't have an account? Create one",
                          style: TextStyle(color: primaryColor, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 2. Custom Mock QR Painter
class MockQRPainter extends CustomPainter {
  final Color primaryColor;

  MockQRPainter({required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = Colors.black;
    final paintPrimary = Paint()..color = primaryColor;

    // Corner Finder Patterns
    _drawFinderPattern(canvas, 0, 0, 22, paintDark, paintPrimary);
    _drawFinderPattern(canvas, size.width - 22, 0, 22, paintDark, paintPrimary);
    _drawFinderPattern(canvas, 0, size.height - 22, 22, paintDark, paintPrimary);

    // Decorative inner micro-matrix bits
    final randomBits = [
      [30.0, 6.0, 6.0],
      [40.0, 10.0, 4.0],
      [32.0, 24.0, 8.0],
      [48.0, 28.0, 6.0],
      [60.0, 32.0, 5.0],
      [10.0, 32.0, 6.0],
      [22.0, 40.0, 5.0],
      [36.0, 46.0, 7.0],
      [52.0, 48.0, 6.0],
      [68.0, 52.0, 6.0],
      [30.0, 60.0, 8.0],
      [44.0, 64.0, 5.0],
      [60.0, 68.0, 6.0],
    ];

    for (var b in randomBits) {
      canvas.drawRect(Rect.fromLTWH(b[0], b[1], b[2], b[2]), paintDark);
    }
  }

  void _drawFinderPattern(
    Canvas canvas,
    double x,
    double y,
    double s,
    Paint dark,
    Paint primary,
  ) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, s, s), dark);
    // Inner white gap
    canvas.drawRect(Rect.fromLTWH(x + 3, y + 3, s - 6, s - 6), Paint()..color = Colors.white);
    // Center dot
    canvas.drawRect(Rect.fromLTWH(x + 6, y + 6, s - 12, s - 12), primary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
