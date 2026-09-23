import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/announcement_item.dart';

// 1. Define the Star Model
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
    for (int i = 0; i < 90; i++) {
      final isCross = random.nextDouble() > 0.85;
      _stars.add(
        Star(
          x: random.nextDouble() * size.width,
          y: random.nextDouble() * size.height,
          size: isCross ? random.nextDouble() * 3 + 2 : random.nextDouble() * 1.5 + 0.5,
          isCross: isCross,
          twinkleSpeed: random.nextDouble() * 3 + 1,
          color: isCross
              ? const Color(0xFFFF5722).withValues(alpha: 0.6)
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
          // Twinkling Starfield Layer (isolated with RepaintBoundary)
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

          // Scrollable Content Layer (isolated with RepaintBoundary)
          SafeArea(
            child: RepaintBoundary(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                  // Header / Logo Bar
                  _buildHeader(primaryColor, secondaryColor)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.05, end: 0),

                  const SizedBox(height: 20),

                  // Centenary Theme Banner
                  _buildThemeBanner(primaryColor, secondaryColor)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 100.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 24),

                  // Countdown Timer
                  ConcettoCountdownTimer(primaryColor: primaryColor)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 180.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 28),

                  // Live Announcements Stream
                  _buildAnnouncementsSection(announcementsAsync, primaryColor)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 260.ms),

                  const SizedBox(height: 28),

                  // Key Stats Bar (Why Concetto?)
                  _buildStatsBar(primaryColor)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 340.ms),

                  const SizedBox(height: 32),

                  // Featured Flagship Events Carousel
                  _buildFeaturedEventsSection(eventsAsync, primaryColor)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 420.ms),

                  const SizedBox(height: 32),

                  // Quick Action Hub (Events, Schedule, Pass, Accommodation)
                  _buildQuickActionHub(context, primaryColor)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 500.ms),

                  const SizedBox(height: 32),

                  // Voices of Concetto (Leadership Quotes)
                  _buildLeadershipVoicesSection(primaryColor)
                      .animate()
                      .fadeIn(duration: 450.ms, delay: 540.ms),

                  const SizedBox(height: 32),

                  // About Fest & Centenary Footer Card
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

  // --- Header ---
  Widget _buildHeader(Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/logo_square.png',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/logo_final.webp',
                        height: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "CONCETTO '26",
                        style: GoogleFonts.orbitron(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "IIT (ISM) DHANBAD",
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 1.0,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF140604),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 13, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  'OCT 08 - 11',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

  // --- Theme Banner ---
  Widget _buildThemeBanner(Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CENTENARY EDITION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'IIT (ISM) DHANBAD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Centauri Synapse',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Forged Over a Century, Soaring Towards Infinity',
              style: GoogleFonts.rajdhani(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Where a century of academic imagination meets futuristic technology. Eastern India\'s largest techno-management celebration.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryColor.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }

}

// --- Isolated High-Performance Countdown Timer Widget ---
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: widget.primaryColor),
              const SizedBox(width: 6),
              Text(
                'TIME UNTIL LAUNCH',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDigitBox(days.toString().padLeft(2, '0'), 'DAYS'),
              _buildTimerSeparator(),
              _buildDigitBox(hours.toString().padLeft(2, '0'), 'HOURS'),
              _buildTimerSeparator(),
              _buildDigitBox(minutes.toString().padLeft(2, '0'), 'MINS'),
              _buildTimerSeparator(),
              _buildDigitBox(seconds.toString().padLeft(2, '0'), 'SECS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(String digits, String label) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF130604),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.45), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.12),
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
              fontWeight: FontWeight.w700,
              color: widget.primaryColor,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: widget.primaryColor.withValues(alpha: 0.7),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: widget.primaryColor.withValues(alpha: 0.7),
      ),
    );
  }
}

extension _HomeScreenHelpers on _HomeScreenState {

  // --- Announcements Section ---
  Widget _buildAnnouncementsSection(
    AsyncValue<List<AnnouncementItem>> announcementsAsync,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE ANNOUNCEMENTS',
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.3, 1.3),
                    duration: 1000.ms,
                  )
                  .fade(begin: 0.5, end: 1.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Failed to load updates: $err'),
          ),
          data: (announcements) {
            if (announcements.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('No active announcements right now.'),
              );
            }
            return SizedBox(
              height: 135,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
    if (ann.tag == 'URGENT') tagColor = Colors.redAccent;
    if (ann.tag == 'HACKATHON') tagColor = Colors.cyanAccent;
    if (ann.tag == 'INFO') tagColor = Colors.lightBlueAccent;

    final dateStr = DateFormat('MMM d, h:mm a').format(ann.timestamp);

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF100605),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
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
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ann.title,
            style: const TextStyle(
              fontSize: 13,
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
    );
  }

  // --- Why Concetto? Stats Bar ---
  Widget _buildStatsBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                'WHY CONCETTO?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
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
              Expanded(child: _buildStatItem('100+', 'Colleges', Icons.school, primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatItem('₹ Lakhs', 'Prizes', Icons.monetization_on, primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF100605),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: primaryColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white60),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Featured Events Section ---
  Widget _buildFeaturedEventsSection(
    AsyncValue<List<EventItem>> eventsAsync,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stars, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'FLAGSHIP HIGHLIGHTS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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
                      'View All',
                      style: TextStyle(
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Failed to load events: $err'),
          ),
          data: (events) {
            final flagshipEvents = events.where((e) => e.isFlagship).toList();
            final displayEvents = flagshipEvents.isNotEmpty ? flagshipEvents : events.take(5).toList();

            return SizedBox(
              height: 260,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF100605),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.1),
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
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events, size: 12, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              event.prizePool,
                              style: TextStyle(
                                fontSize: 10,
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.date,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  // --- Quick Action Hub ---
  Widget _buildQuickActionHub(BuildContext context, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                'QUICK ACCESS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
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
                  icon: Icons.event_note,
                  title: 'All Events',
                  subtitle: '100+ Contests',
                  onTap: () => context.go('/events'),
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.calendar_month,
                  title: 'Timeline',
                  subtitle: 'Day 1 - Day 3',
                  onTap: () => context.go('/schedule'),
                  primaryColor: primaryColor,
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
                  title: 'Stay & Travel',
                  subtitle: 'Accommodation',
                  onTap: () => _showAccommodationSheet(context, primaryColor),
                  primaryColor: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.badge,
                  title: 'Fest Pass',
                  subtitle: 'My Profile',
                  onTap: () => context.go('/profile'),
                  primaryColor: primaryColor,
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
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF100605),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccommodationSheet(BuildContext context, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0403),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  Icon(Icons.hotel, color: primaryColor),
                  const SizedBox(width: 10),
                  const Text(
                    'Campus Accommodation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Enjoy a comfortable hostel stay on the IIT (ISM) Dhanbad campus throughout the festival days (October 10-12, 2026).',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('On-campus boys and girls hostel rooms', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Convenient proximity to all festival venues', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact operations: anant.22je0109@nit.ac.in or +91 85030 86164'),
                      ),
                    );
                  },
                  child: const Text('CONTACT ACCOMMODATION TEAM'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Leadership Voices Section ---
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'VOICES OF CONCETTO',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: quotes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final q = quotes[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _showLeadershipMessageDialog(context, q, primaryColor),
                  child: Container(
                    width: 290,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF110504),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: AssetImage(q['image']!),
                              backgroundColor: primaryColor.withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q['name']!,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    q['role']!,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            '"${q['quote']}"',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                              height: 1.35,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Read full speech',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: primaryColor,
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF140808),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
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
                      radius: 24,
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            q['role']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
                              'MESSAGE FOR CONCETTO 2026',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          q['quote']!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.check_rounded, size: 16, color: primaryColor),
                    label: Text(
                      'CLOSE',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
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

  // --- About Fest & Footer ---
  Widget _buildAboutSection(Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0403),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ABOUT CONCETTO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'CONCETTO is the premier annual Techno-Management Fest hosted by Indian Institute of Technology (ISM) Dhanbad. Over 20,000 students from 100+ institutes nationwide compete in robotics, engineering design, hackathons, and management case studies.',
              style: TextStyle(
                fontSize: 12,
                color: secondaryColor.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_pin, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'IIT (ISM) Dhanbad, Jharkhand - 826004',
                    style: TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'concetto@iitism.ac.in',
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 2. The Custom Painter
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