import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  String _selectedTeamFilter = 'All';
  String? _expandedNoteMemberName;

  final List<String> _teamFilters = const [
    'All',
    'Faculty',
    'Advisors',
    'Secretariat',
    'Events',
    'Sponsorship',
    'Public Relations',
    'Tech & Dev',
    'Operations',
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final user = ref.watch(authProvider);
    final teamAsync = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ABOUT CONCETTO',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, size: 18, color: Colors.white24),
            tooltip: 'Staff Portal',
            onPressed: () {
              AdminLoginDialog.show(
                context,
                onSuccess: (isDeveloper) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdminDashboardScreen(initialIsDeveloper: isDeveloper),
                    ),
                  );
                },
              );
            },
          ),
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

            // 2. Auth Action Button: Sign In / Register when logged out, Sign Out when logged in
            if (!user.isLoggedIn)
              _buildAuthActionButton(context, primaryColor)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
            else
              _buildSignOutActionButton(context, user, primaryColor)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 20),

            // Official About Us & Centenary Heritage Section
            _buildAboutUsSection(primaryColor, secondaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 180.ms),

            const SizedBox(height: 32),

            // 3. Core Team Directory
            _buildTeamDirectorySection(teamAsync, primaryColor, secondaryColor)
                .animate()
                .fadeIn(duration: 400.ms, delay: 220.ms),

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

            const SizedBox(height: 36),

            // Discreet Organizer Access at the very last of the page
            _buildDiscreetOrganizerAccess(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 1. Digital Fest Pass ---
  Widget _buildDigitalFestPass(AttendeeProfile user, Color primaryColor) {
    if (!user.isLoggedIn) {
      return _buildLockedFestPass(primaryColor);
    }

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
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo_transparent.png', height: 32),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "CONCETTO '26 PASS",
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPassBadgeColor(user.passType, user.isGuest, user.isIitIsm).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _getPassBadgeColor(user.passType, user.isGuest, user.isIitIsm),
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
                        color: _getPassBadgeColor(user.passType, user.isGuest, user.isIitIsm),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fade(begin: 0.4, end: 1.0, duration: 800.ms),
                    const SizedBox(width: 6),
                    Text(
                      user.isGuest ? 'GUEST PASS' : user.passCategoryTitle,
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPassBadgeColor(user.passType, user.isGuest, user.isIitIsm),
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
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_android, size: 11, color: AppTheme.metallicMuted.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            user.phone,
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              color: AppTheme.metallicMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
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

              // Genuine QR Code Badge with Tap to Enlarge
              GestureDetector(
                onTap: () => _showEnlargedPassModal(context, user, primaryColor),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPassBadgeColor(user.passType, user.isGuest, user.isIitIsm).withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                  ),
                  child: Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: QrImageView(
                      data: user.qrPayload,
                      version: QrVersions.auto,
                      size: 90,
                      padding: const EdgeInsets.all(2),
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
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
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'VALID: OCT 10 - 12, 2026',
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    user.isIitIsm ? 'IIT (ISM) DHANBAD' : user.college.toUpperCase(),
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPassBadgeColor(int passType, bool isGuest, [bool isIitIsm = false]) {
    if (isGuest) return const Color(0xFFFFB300);
    if (isIitIsm && (passType == 0 || passType == 1)) {
      return const Color(0xFF00E676); // Emerald Green (Student Pass)
    }
    switch (passType) {
      case 0:
        return const Color(0xFF00E676); // Emerald Green (Student Pass)
      case 1:
        return const Color(0xFFFFB300); // Amber (Guest Pass)
      case 2:
        return const Color(0xFFCFD8DC); // Silver Pass
      case 3:
        return const Color(0xFFFFB300); // Gold Pass
      case 4:
        return const Color(0xFF00E5FF); // Diamond Pass
      case 5:
        return const Color(0xFFFF4081); // Diamond+ Merch Pass
      default:
        return const Color(0xFF00E676);
    }
  }

  Widget _buildLockedFestPass(Color primaryColor) {
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
        border: Border.all(color: primaryColor.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Virtual Lanyard Slot
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo_transparent.png', height: 28),
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
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 12, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      'LOCKED',
                      style: GoogleFonts.rajdhani(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white60,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Lock Icon & "LOG IN TO GET YOUR EVENT PASS"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.1),
              border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Icon(Icons.lock_person_outlined, size: 36, color: primaryColor)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1200.ms),
          ),
          const SizedBox(height: 14),

          Text(
            'LOG IN TO GET YOUR EVENT PASS',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please sign in or register to issue your verified digital pass, category access, and gate entry QR code.',
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.metallicMuted,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VALID: OCT 10 - 12, 2026',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'IIT (ISM) DHANBAD',
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEnlargedPassModal(BuildContext context, AttendeeProfile user, Color primaryColor) {
    final badgeColor = _getPassBadgeColor(user.passType, user.isGuest, user.isIitIsm);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF140604),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: badgeColor, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Text(
                      user.isGuest ? 'GUEST PASS' : user.passCategoryTitle,
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: user.qrPayload,
                  version: QrVersions.auto,
                  size: 210,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                user.name,
                style: GoogleFonts.rajdhani(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.college,
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(fontSize: 13, color: AppTheme.metallicMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'ID: ${user.passId}',
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Show this QR code at checkpoints for fast validation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
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
        label: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'SIGN IN / REGISTER FEST ACCOUNT',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSignOutActionButton(BuildContext context, AttendeeProfile user, Color primaryColor) {
    return Column(
      children: [
        _buildUserStatusBanner(user, primaryColor),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out of festival account.')),
              );
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            label: const Text(
              'SIGN OUT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatusBanner(AttendeeProfile user, Color primaryColor) {
    final badgeColor = _getPassBadgeColor(user.passType, user.isGuest, user.isIitIsm);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.verified_user, color: badgeColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name.isNotEmpty ? user.name : 'Verified Attendee',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${user.passCategoryTitle} • ${user.email}',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh Pass',
            icon: Icon(Icons.refresh, color: badgeColor, size: 18),
            onPressed: () async {
              await ref.read(authProvider.notifier).refreshProfile();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pass data refreshed from Concetto cloud.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // --- 2b. Discreet Organizer & Staff Portal ---
  Widget _buildDiscreetOrganizerAccess(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AdminLoginDialog.show(
            context,
            onSuccess: (isDeveloper) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AdminDashboardScreen(initialIsDeveloper: isDeveloper),
                ),
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 12, color: AppTheme.metallicMuted.withValues(alpha: 0.35)),
              const SizedBox(width: 6),
              Text(
                'Staff & Organizer Portal',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.metallicMuted.withValues(alpha: 0.4),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Official About Us & Centenary Heritage Section ---
  // --- Official About Us & Centenary Heritage Section ---
  Widget _buildAboutUsSection(Color primaryColor, Color secondaryColor) {
    final glimpses = [
      {'img': 'assets/about/about1.webp', 'title': 'Where Ideas Meet Innovation', 'subtitle': 'Annual Techno-Management Fest'},
      {'img': 'assets/about/about2.webp', 'title': 'Centauri Synapse', 'subtitle': 'Forged Over A Century'},
      {'img': 'assets/about/about3.webp', 'title': 'Techno-Management Arena', 'subtitle': 'Curiosity, Creativity & Drive'},
      {'img': 'assets/about/about4.webp', 'title': 'Centenary Legacy', 'subtitle': 'IIT (ISM) Dhanbad Excellence'},
      {'img': 'assets/about/glimpse1.png', 'title': 'Flagship Arena', 'subtitle': 'Mega Robotics Battles'},
      {'img': 'assets/about/glimpse2.png', 'title': 'Drone Arena', 'subtitle': 'Precision Flight Racing'},
      {'img': 'assets/about/glimpse3.png', 'title': 'Overnight Hackathon', 'subtitle': '36 Hours of Non-stop Code'},
      {'img': 'assets/about/glimpse4.png', 'title': 'Design Workshop', 'subtitle': 'Hands-on Prototyping'},
      {'img': 'assets/about/glimpse5.png', 'title': 'Exhibition & Stunt', 'subtitle': 'Automotive & Aero Thrills'},
      {'img': 'assets/about/glimpse6.png', 'title': 'Star Night Grandeur', 'subtitle': 'Celebrity Pronites'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'ABOUT CONCETTO \'26',
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF110604),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.06),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'CENTAURI SYNAPSE • 1926-2026',
                      style: GoogleFonts.orbitron(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Eastern India\'s Largest Techno-Management Fest',
                style: GoogleFonts.rajdhani(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'CONCETTO is the renowned annual techno-management fest hosted by IIT (ISM) Dhanbad. Celebrating the historic centenary milestone of the institution (1926 - 2026), Concetto\'26 unites over 20,000 innovators across premier competitive arenas, workshops, guest lectures, and cultural showcases.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GLIMPSES OF CONCETTO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    'TAP TO VIEW',
                    style: GoogleFonts.rajdhani(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white38,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: glimpses.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = glimpses[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showGlimpseViewer(context, item, primaryColor),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  item['img']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFF1E0A08),
                                    child: const Icon(Icons.image, color: Colors.white24),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.85),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Icon(Icons.fullscreen_rounded, size: 12, color: primaryColor),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item['title']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      item['subtitle']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showGlimpseViewer(
    BuildContext context,
    Map<String, String> item,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            decoration: BoxDecoration(
              color: const Color(0xFF140605),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.45), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.camera_enhance_rounded, color: primaryColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item['subtitle']!,
                              style: GoogleFonts.rajdhani(
                                fontSize: 11.5,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.asset(
                        item['img']!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          padding: const EdgeInsets.all(40),
                          color: Colors.black45,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.broken_image, color: Colors.white38, size: 48),
                              SizedBox(height: 8),
                              Text('Could not load image', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pinch_rounded, size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(
                        'Pinch to zoom • Drag to pan',
                        style: GoogleFonts.rajdhani(
                          color: Colors.white38,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        const SizedBox(height: 12),

        // Vertical Filter Chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _teamFilters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _teamFilters[index];
              final isSelected = _selectedTeamFilter == filter;
              return ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
                selected: isSelected,
                selectedColor: primaryColor,
                backgroundColor: const Color(0xFF140604),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTeamFilter = filter;
                    });
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        teamAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading team: $err'),
          data: (team) {
            final filteredTeam = team.where((m) {
              if (_selectedTeamFilter == 'All') return true;
              final v = m.vertical.toLowerCase();
              if (_selectedTeamFilter == 'Faculty') return v.contains('faculty') || v.contains('convenor') || v.contains('treasurer');
              if (_selectedTeamFilter == 'Advisors') return v.contains('advisory') || v.contains('advisor');
              if (_selectedTeamFilter == 'Secretariat') return v.contains('secretariat') || v.contains('coordinator');
              if (_selectedTeamFilter == 'Events') return v.contains('event');
              if (_selectedTeamFilter == 'Sponsorship') return v.contains('sponsorship') || v.contains('prom') || v.contains('market') || v.contains('fin');
              if (_selectedTeamFilter == 'Public Relations') return v.contains('public');
              if (_selectedTeamFilter == 'Tech & Dev') return v.contains('development') || v.contains('web') || v.contains('app') || v.contains('design');
              if (_selectedTeamFilter == 'Operations') return v.contains('operation') || v.contains('security') || v.contains('hospitality') || v.contains('doc');
              return true;
            }).toList()
              ..sort((a, b) => a.order.compareTo(b.order));

            return RepaintBoundary(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTeam.length,
                itemBuilder: (context, index) {
                  final member = filteredTeam[index];
                  return _buildTeamMemberCard(member, primaryColor);
                },
              ),
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
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  backgroundImage: member.imageUrl.startsWith('assets/')
                      ? AssetImage(member.imageUrl) as ImageProvider
                      : (member.imageUrl.isNotEmpty ? CachedNetworkImageProvider(member.imageUrl) : null),
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
                      member.role,
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (member.email.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.email_outlined, size: 18),
                      color: primaryColor,
                      tooltip: 'Send Email (${member.email})',
                      onPressed: () => _launchMail(context, member.email),
                    ),
                  if (member.phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      color: primaryColor,
                      tooltip: 'Call Phone (${member.phone})',
                      onPressed: () => _launchPhone(context, member.phone),
                    ),
                ],
              ),
            ],
          ),
          if (member.quote.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  if (_expandedNoteMemberName == member.name) {
                    _expandedNoteMemberName = null;
                  } else {
                    _expandedNoteMemberName = member.name;
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: primaryColor, width: 2.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Text(
                        '"${member.quote}"',
                        maxLines: _expandedNoteMemberName == member.name ? null : 2,
                        overflow: _expandedNoteMemberName == member.name
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                    ),
                    if (member.quote.length > 70) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _expandedNoteMemberName == member.name ? 'Read Less' : 'Read More',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _expandedNoteMemberName == member.name
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 14,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
            childAspectRatio: 1.45,
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
          InkWell(
            onTap: () => _launchPhone(context, '+918503086164'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 14, color: primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '+91 85030 86164 / +91 326 223 5400',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          InkWell(
            onTap: () => _launchMail(context, 'concetto@iitism.ac.in'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.email, size: 14, color: primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'concetto@iitism.ac.in',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          InkWell(
            onTap: () => _launchExternalUrl('https://concetto.in'),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.public, size: 14, color: primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'https://concetto.in',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
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
    final phoneController = TextEditingController();
    final otherCollegeController = TextEditingController();

    const String iitIsmOption = 'Indian Institute of Technology (ISM) Dhanbad';
    const String othersOption = 'Others';

    String selectedCollegeOption = iitIsmOption;
    bool isSignUp = false;
    bool isLoading = false;
    bool obscurePassword = true;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF100605),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isIitSelected = selectedCollegeOption == iitIsmOption;

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
                    // Modal Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isSignUp ? Icons.badge_outlined : Icons.lock_open_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isSignUp ? 'REGISTER FEST PASS' : 'ATTENDEE SIGN IN',
                              style: GoogleFonts.orbitron(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Validation or Error Banner
                    if (localError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localError!,
                                style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (isSignUp) ...[
                      // Full Name
                      TextField(
                        controller: nameController,
                        style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          labelStyle: GoogleFonts.rajdhani(color: Colors.white60),
                          prefixIcon: Icon(Icons.person, color: primaryColor, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF180A08),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // College Dropdown
                      Text(
                        'COLLEGE / INSTITUTE *',
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF180A08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCollegeOption,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF180A08),
                            icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                            items: const [
                              DropdownMenuItem(
                                value: iitIsmOption,
                                child: Text(
                                  'Indian Institute of Technology (ISM) Dhanbad',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DropdownMenuItem(
                                value: othersOption,
                                child: Text(
                                  'Others (Specify College Name)',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  selectedCollegeOption = val;
                                  localError = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Conditional text field for "Others"
                      if (!isIitSelected) ...[
                        TextField(
                          controller: otherCollegeController,
                          style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Specify College / Institute Name *',
                            labelStyle: GoogleFonts.rajdhani(color: Colors.white60),
                            prefixIcon: Icon(Icons.school, color: primaryColor, size: 20),
                            filled: true,
                            fillColor: const Color(0xFF180A08),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Phone Number
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '+91 98765 43210',
                          hintStyle: GoogleFonts.rajdhani(color: Colors.white24),
                          labelStyle: GoogleFonts.rajdhani(color: Colors.white60),
                          prefixIcon: Icon(Icons.phone_android, color: primaryColor, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF180A08),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pass Category Preview Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isIitSelected ? const Color(0xFF00E676) : Colors.amber).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isIitSelected ? const Color(0xFF00E676) : Colors.amber,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: isIitSelected ? const Color(0xFF00E676) : Colors.amber,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isIitSelected
                                    ? 'Assigned Category: STUDENT PASS'
                                    : 'Assigned Category: GUEST PASS',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isIitSelected ? const Color(0xFF00E676) : Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Email Address
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: isSignUp && isIitSelected
                            ? 'Institute Email (@iitism.ac.in) *'
                            : 'Email Address *',
                        labelStyle: GoogleFonts.rajdhani(color: Colors.white60),
                        prefixIcon: Icon(Icons.email, color: primaryColor, size: 20),
                        helperText: isSignUp && isIitSelected
                            ? 'Must end with @iitism.ac.in for Student Pass'
                            : (isSignUp ? 'Confirmation link will be sent to this email' : null),
                        helperStyle: GoogleFonts.rajdhani(
                          color: isSignUp && isIitSelected ? const Color(0xFF00E676) : Colors.white38,
                          fontSize: 11,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF180A08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextField(
                      controller: passController,
                      obscureText: obscurePassword,
                      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        labelStyle: GoogleFonts.rajdhani(color: Colors.white60),
                        prefixIcon: Icon(Icons.lock, color: primaryColor, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38,
                            size: 18,
                          ),
                          onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF180A08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (!isSignUp) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(context, emailController.text.trim()),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.rajdhani(
                              color: primaryColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final email = emailController.text.trim();
                                final password = passController.text;

                                if (email.isEmpty) {
                                  setModalState(() => localError = 'Please enter your email address.');
                                  return;
                                }

                                if (password.length < 6) {
                                  setModalState(() => localError = 'Password must be at least 6 characters.');
                                  return;
                                }

                                if (isSignUp) {
                                  final name = nameController.text.trim();
                                  final phone = phoneController.text.trim();
                                  final college = isIitSelected
                                      ? iitIsmOption
                                      : otherCollegeController.text.trim();

                                  if (name.isEmpty) {
                                    setModalState(() => localError = 'Please enter your full name.');
                                    return;
                                  }

                                  if (!isIitSelected && college.isEmpty) {
                                    setModalState(() => localError = 'Please enter your college name.');
                                    return;
                                  }

                                  if (phone.isEmpty) {
                                    setModalState(() => localError = 'Please enter your phone number.');
                                    return;
                                  }

                                  // Strict check for IIT ISM
                                  if (isIitSelected && !email.toLowerCase().endsWith('@iitism.ac.in')) {
                                    setModalState(() => localError =
                                        'IIT (ISM) students must provide an email ending with @iitism.ac.in');
                                    return;
                                  }

                                  setModalState(() {
                                    isLoading = true;
                                    localError = null;
                                  });

                                  try {
                                    await ref.read(authProvider.notifier).signUpWithEmail(
                                          name: name,
                                          email: email,
                                          password: password,
                                          college: college,
                                          phone: phone,
                                        );

                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }

                                    // Display Email Confirmation Instructions Dialog
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF140604),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: const BorderSide(color: Color(0xFF00E676), width: 1.2),
                                          ),
                                          title: Row(
                                            children: [
                                              const Icon(Icons.mark_email_read_rounded, color: Color(0xFF00E676), size: 26),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'VERIFICATION EMAIL SENT',
                                                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'We sent a confirmation link to:\n$email',
                                                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Complete verification process to log in:',
                                                      style: GoogleFonts.rajdhani(
                                                        color: const Color(0xFF00E676),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      '1. Open the email sent to $email and click the verification link.\n2. IF EMAIL IS NOT FOUND, PLEASE CHECK YOUR SPAM OR JUNK FOLDER.\n3. Return here and tap "Sign In" to view your verified festival pass and QR code.',
                                                      style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 12, height: 1.35),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF00E676),
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('OK, UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() {
                                      isLoading = false;
                                      localError = e.toString().replaceAll('Exception: ', '');
                                    });
                                  }
                                } else {
                                  // Sign in flow
                                  setModalState(() {
                                    isLoading = true;
                                    localError = null;
                                  });

                                  try {
                                    await ref.read(authProvider.notifier).signInWithEmail(email, password);
                                    if (sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 18),
                                              const SizedBox(width: 8),
                                              const Text('Pass loaded successfully!'),
                                            ],
                                          ),
                                          backgroundColor: const Color(0xFF140604),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    final errStr = e.toString();
                                    final isNotVerified = errStr.contains('not verified');

                                    setModalState(() {
                                      isLoading = false;
                                      localError = errStr.replaceAll('Exception: ', '');
                                    });

                                    if (isNotVerified && sheetContext.mounted) {
                                      // Offer resend button dialog
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF140604),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: const BorderSide(color: Colors.amber, width: 1.2),
                                          ),
                                          title: Row(
                                            children: [
                                              const Icon(Icons.mail_lock_rounded, color: Colors.amber, size: 24),
                                              const SizedBox(width: 8),
                                              Text(
                                                'EMAIL NOT VERIFIED',
                                                style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            'Your email address has not been confirmed yet. Please verify it via the link sent to your inbox to log in.\n\nNeed another verification link?',
                                            style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 14),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                try {
                                                  await ref.read(authProvider.notifier).resendVerificationEmail(email, password);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Verification link sent again to $email.'),
                                                        backgroundColor: const Color(0xFF140604),
                                                      ),
                                                    );
                                                  }
                                                } catch (resendErr) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Could not resend: $resendErr')),
                                                    );
                                                  }
                                                }
                                              },
                                              child: const Text('RESEND LINK', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                isSignUp ? 'CREATE ACCOUNT & ISSUE PASS' : 'SIGN IN',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Toggle between Sign In and Sign Up
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            isSignUp = !isSignUp;
                            localError = null;
                          });
                        },
                        child: Text(
                          isSignUp
                              ? 'Already have an account? Sign In'
                              : "Don't have an account? Register Here",
                          style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
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

  Future<void> _launchPhone(BuildContext context, String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer: $e'),
            backgroundColor: const Color(0xFF140604),
          ),
        );
      }
    }
  }

  Future<void> _launchMail(BuildContext context, String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: cleanEmail,
      queryParameters: {
        'subject': "Query regarding Concetto'26 Organizing Committee",
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open mail app: $e'),
            backgroundColor: const Color(0xFF140604),
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext parentContext, String initialEmail) {
    final emailCtrl = TextEditingController(text: initialEmail);
    bool isSending = false;
    String? errorMsg;
    String? successMsg;

    showDialog(
      context: parentContext,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF140604),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Color(0xFFFF5252), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'RESET PASSWORD',
                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your registered email address. We will send password reset instructions to your inbox.',
                style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Email Address *',
                  labelStyle: GoogleFonts.rajdhani(color: Colors.white60),
                  prefixIcon: const Icon(Icons.email, color: Color(0xFFFF5252), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF1E0805),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMsg!,
                  style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              if (successMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  successMsg!,
                  style: GoogleFonts.rajdhani(color: const Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('CANCEL', style: GoogleFonts.rajdhani(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) {
                        setDialogState(() => errorMsg = 'Please enter your email.');
                        return;
                      }
                      setDialogState(() {
                        isSending = true;
                        errorMsg = null;
                      });
                      try {
                        await ref.read(authProvider.notifier).sendPasswordResetEmail(email);
                        setDialogState(() {
                          isSending = false;
                          successMsg = 'Reset link sent! Please check your Inbox and Spam folder.';
                        });
                        await Future.delayed(const Duration(seconds: 2));
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      } catch (e) {
                        setDialogState(() {
                          isSending = false;
                          errorMsg = e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    },
              child: isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SEND RESET LINK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
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
