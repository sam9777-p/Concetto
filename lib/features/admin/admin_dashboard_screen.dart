import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/pass_scanner_screen.dart';
import 'event_operations_screen.dart';
import 'guest_pass_dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final bool initialIsDeveloper;

  const AdminDashboardScreen({
    super.key,
    this.initialIsDeveloper = false,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isEventUnlocked = false;
  bool _isSecurityUnlocked = false;
  bool _isHospitalityUnlocked = false;

  @override
  void initState() {
    super.initState();
    // Strictly all modules start locked by default upon entering Organizer Hub
    _isEventUnlocked = false;
    _isSecurityUnlocked = false;
    _isHospitalityUnlocked = false;
  }

  Future<void> _promptRolePassword({
    required String roleName,
    required String roleSubtitle,
    required IconData icon,
    required Color accentColor,
    required bool Function(String) validator,
    required VoidCallback onAuthorized,
  }) async {
    final controller = TextEditingController();
    bool obscure = true;
    String? error;
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: AppTheme.scaffoldBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: accentColor, width: 1.3),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppTheme.darkCardGradient,
              boxShadow: AppTheme.neonGlow(color: accentColor, opacity: 0.25, blur: 20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                        ),
                        child: Icon(icon, color: accentColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roleName.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              roleSubtitle,
                              style: GoogleFonts.rajdhani(
                                fontSize: 12.5,
                                color: AppTheme.metallicMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Enter $roleName or Developer Override Password:',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13.5,
                      color: AppTheme.metallicSilver,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent, width: 0.8),
                      ),
                      child: Text(
                        error!,
                        style: GoogleFonts.rajdhani(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    autofocus: true,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF140705),
                      hintText: 'Enter Password',
                      hintStyle: GoogleFonts.rajdhani(color: Colors.white38),
                      prefixIcon: Icon(Icons.lock_outline, color: accentColor, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.metallicMuted,
                          size: 20,
                        ),
                        onPressed: () => setDlgState(() => obscure = !obscure),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: accentColor, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) {
                      final entered = controller.text.trim();
                      if (entered.isEmpty) return;
                      setDlgState(() => isVerifying = true);
                      if (validator(entered)) {
                        Navigator.of(context).pop();
                        if (MasterAdminConfig.verifyDev(entered)) {
                          setState(() {
                            _isEventUnlocked = true;
                            _isSecurityUnlocked = true;
                            _isHospitalityUnlocked = true;
                          });
                        }
                        onAuthorized();
                      } else {
                        setDlgState(() {
                          isVerifying = false;
                          error = 'Incorrect password for $roleName.';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.metallicMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isVerifying
                            ? null
                            : () {
                                final entered = controller.text.trim();
                                if (entered.isEmpty) {
                                  setDlgState(() => error = 'Please enter password.');
                                  return;
                                }
                                setDlgState(() => isVerifying = true);
                                if (validator(entered)) {
                                  Navigator.of(context).pop();
                                  if (MasterAdminConfig.verifyDev(entered)) {
                                    setState(() {
                                      _isEventUnlocked = true;
                                      _isSecurityUnlocked = true;
                                      _isHospitalityUnlocked = true;
                                    });
                                  }
                                  onAuthorized();
                                } else {
                                  setDlgState(() {
                                    isVerifying = false;
                                    error = 'Incorrect password for $roleName.';
                                  });
                                }
                              },
                        child: isVerifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Text(
                                'AUTHORIZE & OPEN',
                                style: GoogleFonts.rajdhani(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 0.8,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSelectEditEvents() {
    if (_isEventUnlocked) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const EventOperationsScreen()),
      );
      return;
    }

    _promptRolePassword(
      roleName: 'Event Password',
      roleSubtitle: 'Event Operations & Cloud Sync',
      icon: Icons.edit_calendar_rounded,
      accentColor: AppTheme.neonOrange,
      validator: MasterAdminConfig.verifyEvent,
      onAuthorized: () {
        setState(() => _isEventUnlocked = true);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const EventOperationsScreen()),
        );
      },
    );
  }

  void _onSelectScanGatePass() {
    if (_isSecurityUnlocked) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PassScannerScreen()),
      );
      return;
    }

    _promptRolePassword(
      roleName: 'Security Password',
      roleSubtitle: 'Gate Entry & Live QR Verification',
      icon: Icons.qr_code_scanner_rounded,
      accentColor: const Color(0xFF00E676),
      validator: MasterAdminConfig.verifySecurity,
      onAuthorized: () {
        setState(() => _isSecurityUnlocked = true);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PassScannerScreen()),
        );
      },
    );
  }

  void _onSelectEditPasses() {
    if (_isHospitalityUnlocked) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const GuestPassDashboardScreen()),
      );
      return;
    }

    _promptRolePassword(
      roleName: 'Hospitality Password',
      roleSubtitle: 'Guest Pass Management & Attendee Directory',
      icon: Icons.badge_outlined,
      accentColor: AppTheme.cyberAmber,
      validator: MasterAdminConfig.verifyHospitality,
      onAuthorized: () {
        setState(() => _isHospitalityUnlocked = true);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const GuestPassDashboardScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: Text(
          'ORGANIZER COMMAND HUB',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cyberAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.cyberAmber, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: AppTheme.cyberAmber, size: 13),
                const SizedBox(width: 4),
                Text(
                  'MASTER AUTH',
                  style: GoogleFonts.rajdhani(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.cyberAmber,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Exit Organizer Portal',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Festival Security Subtitle
              Text(
                'CONCETTO 2026 • ORGANIZER PANEL',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.metallicMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SELECT DEPARTMENT MODULE',
                style: GoogleFonts.orbitron(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // BOX 1: EDIT EVENTS (EVENT PASSWORD OR DEV)
              // ==========================================
              _buildBoxyModuleCard(
                title: 'EDIT EVENTS',
                subtitle: 'Manage 55 events, rules, clubs, toggle visibility, sync cloud database, or add new competitions.',
                roleBadge: 'REQUIRES EVENT PASS (OR DEV)',
                accentColor: AppTheme.neonOrange,
                icon: Icons.edit_calendar_rounded,
                isUnlocked: _isEventUnlocked,
                onTap: _onSelectEditEvents,
              ),
              const SizedBox(height: 18),

              // ==========================================
              // BOX 2: SCAN GATE PASS (SECURITY PASSWORD OR DEV)
              // ==========================================
              _buildBoxyModuleCard(
                title: 'SCAN GATE PASS',
                subtitle: 'Security gate pass scanner, camera QR code reader, manual ID search & real-time entry logs.',
                roleBadge: 'REQUIRES SECURITY PASS (OR DEV)',
                accentColor: const Color(0xFF00E676),
                icon: Icons.qr_code_scanner_rounded,
                isUnlocked: _isSecurityUnlocked,
                onTap: _onSelectScanGatePass,
              ),
              const SizedBox(height: 18),

              // ==========================================
              // BOX 3: EDIT PASSES / GUEST MANAGEMENT (HOSPITALITY PASSWORD OR DEV)
              // ==========================================
              _buildBoxyModuleCard(
                title: 'EDIT PASSES & GUESTS',
                subtitle: 'Non-IIT ISM attendee dashboard (Pass categories 1, 2, 3, 4, 5). Search any attendee detail and edit pass types in real-time.',
                roleBadge: 'REQUIRES HOSP PASS (OR DEV)',
                accentColor: AppTheme.cyberAmber,
                icon: Icons.badge_outlined,
                isUnlocked: _isHospitalityUnlocked,
                onTap: _onSelectEditPasses,
              ),
              const SizedBox(height: 28),

              // Security notice footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_clock_outlined, size: 14, color: AppTheme.metallicMuted.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      'Multi-tier cryptographic protection active. Zero unauthorized access.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppTheme.metallicMuted.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxyModuleCard({
    required String title,
    required String subtitle,
    required String roleBadge,
    required Color accentColor,
    required IconData icon,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF140705),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUnlocked ? accentColor : accentColor.withValues(alpha: 0.6),
            width: isUnlocked ? 2.0 : 1.3,
          ),
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.12),
              const Color(0xFF100403),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isUnlocked ? 0.25 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Big Icon Box + Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentColor, width: 1.2),
                    boxShadow: AppTheme.neonGlow(color: accentColor, opacity: 0.3, blur: 10),
                  ),
                  child: Icon(icon, color: accentColor, size: 30),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFF00E676).withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isUnlocked ? const Color(0xFF00E676) : accentColor.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                        size: 13,
                        color: isUnlocked ? const Color(0xFF00E676) : accentColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isUnlocked ? 'UNLOCKED' : roleBadge,
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isUnlocked ? const Color(0xFF00E676) : accentColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle / Description
            Text(
              subtitle,
              style: GoogleFonts.rajdhani(
                fontSize: 13.5,
                color: AppTheme.metallicSilver,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // Action prompt
            Row(
              children: [
                Text(
                  isUnlocked ? 'OPEN MODULE' : 'ENTER PASSKEY TO ACCESS',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 15, color: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
