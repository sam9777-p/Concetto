import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import '../../models/announcement_item.dart';

// --- Star Model for Background Starfield ---
class Star {
  final double x;
  final double y;
  final double size;
  final bool isCross;
  final double twinkleSpeed;
  final Color color;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.isCross,
    required this.twinkleSpeed,
    required this.color,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _starController;
  final List<Star> _stars = [];

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stars.isEmpty) {
      _generateStars(MediaQuery.of(context).size);
    }
  }

  void _generateStars(Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 95; i++) {
      final isCross = random.nextDouble() > 0.82;
      _stars.add(
        Star(
          x: random.nextDouble() * size.width,
          y: random.nextDouble() * size.height,
          size: isCross ? random.nextDouble() * 3 + 2.2 : random.nextDouble() * 1.5 + 0.6,
          isCross: isCross,
          twinkleSpeed: random.nextDouble() * 3 + 1,
          color: isCross
              ? const Color(0xFFFF5722).withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: random.nextDouble() * 0.5 + 0.3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final eventsAsync = ref.watch(eventsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070202),
      body: Stack(
        children: [
          // 1. Cosmic Aurora & Glow Accents
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 420,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Twinkling Starfield Layer
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _starController,
              builder: (context, child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: StarfieldPainter(
                    animationValue: _starController.value,
                    stars: _stars,
                  ),
                );
              },
            ),
          ),

          // 3. Scrollable Content Layer
          SafeArea(
            child: RepaintBoundary(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Top Futuristic Header
                    _buildHeader(primaryColor, secondaryColor)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.06, end: 0),

                    const SizedBox(height: 18),

                    // Epic Centenary Hero Showcase
                    _buildHeroShowcase(primaryColor, secondaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 80.ms)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 24),

                    // Telemetry Countdown Mission Clock
                    ConcettoCountdownTimer(primaryColor: primaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 150.ms)
                        .slideY(begin: 0.05, end: 0),

                    const SizedBox(height: 28),

                    // Live Transmissions & Announcements
                    _buildAnnouncementsSection(announcementsAsync, primaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 220.ms),

                    const SizedBox(height: 28),

                    // Key Festival Metrics (Why Concetto?)
                    _buildStatsBar(primaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 280.ms),

                    const SizedBox(height: 32),

                    // Command Deck - Quick Action Matrix
                    _buildQuickActionHub(context, primaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 340.ms),

                    const SizedBox(height: 32),

                    // Flagship Arenas Carousel
                    _buildFeaturedEventsSection(eventsAsync, primaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 400.ms),

                    const SizedBox(height: 32),

                    // Voices of Concetto (Leadership Speeches with 5-6 lines preview)
                    _buildLeadershipVoicesSection(primaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 460.ms),

                    const SizedBox(height: 32),

                    // Relive the Legacy - Moments & Glimpses Gallery
                    _buildGlimpsesSection(primaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 520.ms),

                    const SizedBox(height: 32),

                    // Centenary Heritage & Festival Contact Footer
                    _buildAboutSection(primaryColor, secondaryColor)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 580.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top Futuristic Header HUD ---
  Widget _buildHeader(Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Fest Branding
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.8),
                        Colors.black,
                        secondaryColor.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo_square.png',
                      height: 42,
                      width: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/logo_final.webp',
                        height: 42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "CONCETTO '26",
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 0.6),
                            ),
                            child: Text(
                              "100 YRS",
                              style: GoogleFonts.rajdhani(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "IIT (ISM) DHANBAD",
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.metallicMuted,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Date / Status Badge with Pulsing Live Beacon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF140604),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.3, end: 1.0, duration: 800.ms),
                const SizedBox(width: 6),
                Text(
                  'OCT 08 - 11',
                  style: GoogleFonts.orbitron(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Epic Centenary Hero Showcase ---
  Widget _buildHeroShowcase(Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1C0907),
              const Color(0xFF100403),
              Colors.black.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: primaryColor.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.14),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Edition Pill
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFFA000)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 10, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        'CENTENARY EDITION • 1926-2026',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'IIT (ISM)',
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white60,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Hero Title
            Text(
              'Centauri Synapse',
              style: GoogleFonts.orbitron(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.6,
                height: 1.15,
                shadows: [
                  Shadow(
                    color: primaryColor.withValues(alpha: 0.6),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Sub-headline
            Text(
              'Forged Over a Century • Soaring Towards Infinity',
              style: GoogleFonts.rajdhani(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: primaryColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              'Eastern India\'s largest techno-management celebration. A century of pioneer mining & engineering legacy converging into three days of robotics, coding, hackathons, and innovation.',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),

            // Dual CTA Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/events'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withValues(alpha: 0.6),
                    ),
                    icon: const Icon(Icons.bolt, size: 16, color: Colors.black),
                    label: Text(
                      'EXPLORE EVENTS',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/schedule'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.6), width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(Icons.calendar_month, size: 16, color: primaryColor),
                    label: Text(
                      'TIMELINE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

// --- High-Performance Futuristic Countdown Clock ---
class ConcettoCountdownTimer extends StatefulWidget {
  final Color primaryColor;

  const ConcettoCountdownTimer({super.key, required this.primaryColor});

  @override
  State<ConcettoCountdownTimer> createState() => _ConcettoCountdownTimerState();
}

class _ConcettoCountdownTimerState extends State<ConcettoCountdownTimer> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;
  final DateTime _festTargetDate = DateTime(2026, 10, 8, 9, 0, 0);

  @override
  void initState() {
    super.initState();
    _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calcRemaining());
  }

  void _calcRemaining() {
    final diff = _festTargetDate.difference(DateTime.now());
    if (mounted) {
      setState(() {
        _timeRemaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title with Radar Beacon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar, size: 16, color: widget.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'MISSION LAUNCH TELEMETRY',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: widget.primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: widget.primaryColor.withValues(alpha: 0.4), width: 0.6),
                ),
                child: Text(
                  'T-MINUS',
                  style: GoogleFonts.orbitron(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: widget.primaryColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Digits Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitBox(days.toString().padLeft(2, '0'), 'DAYS'),
              _buildTimerSeparator(),
              _buildDigitBox(hours.toString().padLeft(2, '0'), 'HOURS'),
              _buildTimerSeparator(),
              _buildDigitBox(minutes.toString().padLeft(2, '0'), 'MINS'),
              _buildTimerSeparator(),
              _buildDigitBox(seconds.toString().padLeft(2, '0'), 'SECS', isLive: true),
            ],
          ),
          const SizedBox(height: 10),

          // Mini Festival Progress Milestone Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0403),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDayMilestone('DAY 1', 'OCT 08', true),
                _buildMilestoneDivider(),
                _buildDayMilestone('DAY 2', 'OCT 09', false),
                _buildMilestoneDivider(),
                _buildDayMilestone('DAY 3', 'OCT 10', false),
                _buildMilestoneDivider(),
                _buildDayMilestone('FINALE', 'OCT 11', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayMilestone(String day, String date, bool isCurrent) {
    return Column(
      children: [
        Text(
          day,
          style: GoogleFonts.orbitron(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: isCurrent ? widget.primaryColor : Colors.white60,
          ),
        ),
        Text(
          date,
          style: GoogleFonts.rajdhani(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isCurrent ? Colors.white : Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneDivider() {
    return Container(
      width: 16,
      height: 1,
      color: widget.primaryColor.withValues(alpha: 0.35),
    );
  }

  Widget _buildDigitBox(String digits, String label, {bool isLive = false}) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF140604),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? widget.primaryColor : widget.primaryColor.withValues(alpha: 0.45),
          width: isLive ? 1.0 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: isLive ? 0.2 : 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            digits,
            style: GoogleFonts.orbitron(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isLive ? const Color(0xFFFF7043) : widget.primaryColor,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: widget.primaryColor.withValues(alpha: 0.7),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.metallicMuted,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSeparator() {
    return Text(
      ':',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: widget.primaryColor.withValues(alpha: 0.65),
      ),
    );
  }
}

extension _HomeScreenHelpers on _HomeScreenState {

  // --- Live Transmissions & Announcements ---
  Widget _buildAnnouncementsSection(
    AsyncValue<List<AnnouncementItem>> announcementsAsync,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE TRANSMISSIONS & ALERTS',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.5), width: 0.6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E676),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        announcementsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Failed to load updates: $err'),
          ),
          data: (announcements) {
            if (announcements.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No active announcements right now.'),
              );
            }
            return SizedBox(
              height: 140,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  return _buildAnnouncementCard(ann, primaryColor);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementItem ann, Color primaryColor) {
    Color tagColor = primaryColor;
    if (ann.tag == 'URGENT') tagColor = const Color(0xFFFF5252);
    if (ann.tag == 'HACKATHON') tagColor = const Color(0xFF00E5FF);
    if (ann.tag == 'INFO') tagColor = const Color(0xFF64B5F6);

    final dateStr = DateFormat('MMM d, h:mm a').format(ann.timestamp);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: const Color(0xFF140605),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: tagColor.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tagColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          ann.tag,
                          style: GoogleFonts.rajdhani(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: tagColor,
                          ),
                        ),
                      ),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ann.title,
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ann.description,
                    style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('CLOSE', style: TextStyle(color: primaryColor)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 285,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF120504),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tagColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    ann.tag,
                    style: GoogleFonts.rajdhani(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: tagColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.rajdhani(fontSize: 10.5, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ann.title,
              style: GoogleFonts.rajdhani(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              ann.description,
              style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // --- Key Festival Metrics (Why Concetto?) ---
  Widget _buildStatsBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                'WHY CONCETTO? • FESTIVAL IMPACT',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('20K+', 'Footfall', Icons.people_alt, primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatItem('100+', 'Events', Icons.emoji_events, primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatItem('150+', 'Colleges', Icons.school, primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatItem('₹15L+', 'Prizes', Icons.monetization_on, primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF120504),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white60,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Command Deck - Quick Action Matrix ---
  Widget _buildQuickActionHub(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                'COMMAND DECK • QUICK ACCESS',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.event_available,
                  title: 'All Events',
                  subtitle: '100+ Contests & Arenas',
                  accentColor: primaryColor,
                  onTap: () => context.go('/events'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.schedule,
                  title: 'Festival Timeline',
                  subtitle: 'Day 1 to Day 3 Flow',
                  accentColor: const Color(0xFF00E5FF),
                  onTap: () => context.go('/schedule'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.hotel,
                  title: 'Hostel & Stay',
                  subtitle: 'Campus Accommodation',
                  accentColor: const Color(0xFF00E676),
                  onTap: () => _showAccommodationSheet(context, primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.badge,
                  title: 'Centenary Pass',
                  subtitle: 'My Profile & ID',
                  accentColor: const Color(0xFFAB47BC),
                  onTap: () => context.go('/profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF120504),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.rajdhani(
                        fontSize: 10.5,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Flagship Arenas Carousel ---
  Widget _buildFeaturedEventsSection(
    AsyncValue<List<EventItem>> eventsAsync,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stars_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'FLAGSHIP ARENAS & HIGHLIGHTS',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/events'),
                child: Row(
                  children: [
                    Text(
                      'View All 100+',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Failed to load events: $err'),
          ),
          data: (events) {
            final flagshipEvents = events.where((e) => e.isFlagship).toList();
            final displayEvents = flagshipEvents.isNotEmpty ? flagshipEvents : events.take(6).toList();

            return SizedBox(
              height: 270,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayEvents.length,
                itemBuilder: (context, index) {
                  final event = displayEvents[index];
                  return _buildFeaturedEventCard(event, primaryColor);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedEventCard(EventItem event, Color primaryColor) {
    return GestureDetector(
      onTap: () => context.push('/events/detail', extra: event),
      child: Container(
        width: 225,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF120504),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.12),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: event.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF140604),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonOrange),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.black45,
                        child: const Icon(Icons.bolt, color: Colors.white38, size: 24),
                      ),
                    ),
                  ),
                  // Dark gradient overlay for text readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  if (event.prizePool.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, size: 12, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              event.prizePool,
                              style: GoogleFonts.orbitron(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.rajdhani(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.date,
                          style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'EXPLORE →',
                        style: GoogleFonts.rajdhani(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Voices of Concetto (Leadership Speeches with 5-6 lines preview) ---
  Widget _buildLeadershipVoicesSection(Color primaryColor) {
    final quotes = [
      {
        'name': 'Prof. Gopi Krishna Dondapati',
        'role': 'Treasurer & Faculty',
        'image': 'assets/about/prof_gopi_krishna.png',
        'quote':
            'As we commemorate the Centenary Year of IIT (ISM) Dhanbad, this edition holds a special significance as we celebrate a century of excellence, legacy, and learning. As the Treasurer, I believe that responsible financial management, transparency, and accountability are essential for transforming ideas into meaningful experiences. This fest is the result of collective effort, dedication, and teamwork from every individual involved.',
      },
      {
        'name': 'Arun Dayal',
        'role': '2nd Co-convener',
        'image': 'assets/about/prof_arun_udai.png',
        'quote':
            'India is now driven by a strong thrust towards startups, indigenous manufacturing, digital public infrastructure, and self-reliance in critical technologies, including medical and defence technologies. This transformation is creating unprecedented opportunities for young innovators to turn ideas into technologies, products, and enterprises that address real-world challenges.\nCONCETTO 2026 provides a platform where curiosity meets technology, creativity meets entrepreneurship, and ideas evolve into meaningful solutions. As IIT (ISM) Dhanbad celebrates a century of excellence, I invite students, researchers, innovators, and industry enthusiasts to use this platform to experiment, collaborate, compete, and create.\nLet us nurture a spirit of innovation that is not limited to solving problems, but aspires to build technologies and enterprises for a self-reliant, technologically empowered India.\n\nWelcome to CONCETTO 2026!',
      },
      {
        'name': 'Rahul Kumar',
        'role': 'Advisory Committee',
        'image': 'assets/about/rahul_kumar.png',
        'quote':
            'It is a privilege to welcome you to Concetto 2026, the premier techno-management festival of IIT (ISM) Dhanbad. As our institute celebrates a monumental century of academic brilliance and innovation, this edition stands as a tribute to our rich legacy and a stepping stone toward a limitless future.',
      },
      {
        'name': 'Badal Singh Naik',
        'role': 'Student Advisor',
        'image': 'assets/about/badal_singh.png',
        'quote':
            'Concetto stands as a vibrant platform where innovation meets imagination and ideas transform into possibilities. My vision has always been to work with dedication, embrace challenges, and strive to deliver the very best. I believe that excellence is not merely a destination, but a continuous journey driven by passion, perseverance, and teamwork.',
      },
      {
        'name': 'Sourav Dutta',
        'role': 'Student Advisor',
        'image': 'assets/about/sourav_dutta.png',
        'quote':
            'It is my immense pleasure to welcome you to Concetto 2026, the annual techno-management fest of IIT (ISM), Dhanbad—where ideas take shape, innovation takes flight, and technology meets purpose. I encourage every participant to explore, experiment, compete, and learn beyond the boundaries of the classroom.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'VOICES OF CONCETTO • PATRON MESSAGES',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              Text(
                'TAP TO EXPAND',
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: primaryColor.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Height 250px so that 5-6 full lines of speech are displayed before "Read full speech"
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: quotes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final q = quotes[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showLeadershipMessageDialog(context, q, primaryColor),
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF120504),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speaker Avatar + Name + Role Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 1.2),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: AssetImage(q['image']!),
                                backgroundColor: primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q['name']!,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    q['role']!,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.format_quote,
                              color: primaryColor.withValues(alpha: 0.35),
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 5 to 6 lines of pure speech visible before the button
                        Expanded(
                          child: Text(
                            '"${q['quote']}"',
                            style: GoogleFonts.rajdhani(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Interactive "Read Full Speech" Action Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Read full speech',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  void _showLeadershipMessageDialog(
    BuildContext context,
    Map<String, String> q,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF140605),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: AssetImage(q['image']!),
                      backgroundColor: primaryColor.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q['name']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            q['role']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              size: 18,
                              color: primaryColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'OFFICIAL ADDRESS • CONCETTO 2026',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q['quote']!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
                    label: Text(
                      'CLOSE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
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

  // --- Relive the Legacy - Moments & Glimpses Gallery ---
  Widget _buildGlimpsesSection(Color primaryColor) {
    final glimpses = [
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'CONCETTO GLIMPSES • MOMENTS',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              Text(
                'EXPERIENCE',
                style: GoogleFonts.rajdhani(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: primaryColor.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: glimpses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = glimpses[index];
              return Container(
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        item['img']!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          color: const Color(0xFF140604),
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
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            item['subtitle']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Accommodation Modal Bottom Sheet ---
  void _showAccommodationSheet(BuildContext context, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF120504),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.hotel, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campus Stay & Accommodation',
                          style: GoogleFonts.rajdhani(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'IIT (ISM) Dhanbad Hostels',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Enjoy secure hostel accommodation right on the IIT (ISM) Dhanbad campus throughout the festival days (October 08-11, 2026).',
                style: GoogleFonts.rajdhani(fontSize: 13, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dedicated boys and girls hostel wings with security',
                      style: GoogleFonts.rajdhani(fontSize: 12.5, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct walking distance to SAC, Penman Auditorium, and all arenas',
                      style: GoogleFonts.rajdhani(fontSize: 12.5, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final telUri = Uri.parse('tel:+918503086164');
                    if (await canLaunchUrl(telUri)) {
                      await launchUrl(telUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Contact Operations: +91 85030 86164 or anant.22je0109@nit.ac.in'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.phone_in_talk, size: 18, color: Colors.black),
                  label: Text(
                    'CALL ACCOMMODATION DESK (+91 85030 86164)',
                    style: GoogleFonts.rajdhani(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Centenary Heritage & About Fest Footer ---
  Widget _buildAboutSection(Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF100403),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.06),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance, size: 16, color: primaryColor),
                ),
                const SizedBox(width: 8),
                Text(
                  '100 YEARS OF LEGACY • IIT (ISM)',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Established in 1926 as the Indian School of Mines and upgraded to an Indian Institute of Technology, IIT (ISM) Dhanbad enters its monumental Centenary Year. CONCETTO 2026 brings over 20,000 delegates from 150+ premier institutions nationwide to celebrate innovation, robotics, coding, aerospace, and management.',
              style: GoogleFonts.rajdhani(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'IIT (ISM) Dhanbad, Jharkhand - 826004, India',
                    style: GoogleFonts.rajdhani(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'concetto@iitism.ac.in',
                  style: GoogleFonts.rajdhani(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- The Starfield Custom Painter ---
class StarfieldPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  StarfieldPainter({required this.animationValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final twinkle = (math.sin(animationValue * math.pi * 2 * star.twinkleSpeed) + 1) / 2;
      final currentOpacity = (star.color.a * twinkle).clamp(0.1, 1.0);

      final paint = Paint()
        ..color = star.color.withValues(alpha: currentOpacity)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      if (star.isCross) {
        canvas.drawLine(Offset(star.x - star.size, star.y), Offset(star.x + star.size, star.y), paint);
        canvas.drawLine(Offset(star.x, star.y - star.size), Offset(star.x, star.y + star.size), paint);
      } else {
        canvas.drawCircle(Offset(star.x, star.y), star.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarfieldPainter oldDelegate) => true;
}