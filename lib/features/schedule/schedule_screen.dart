import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _selectedDayIndex = 0;
  late final PageController _pageController;
  double _pullExtent = 0.0;
  bool _hapticFired = false;
  static const double _pullThreshold = 55.0;

  final List<Map<String, String>> _festivalDays = [
    {'day': 'Day 0', 'date': 'Oct 8', 'label': 'Thursday'},
    {'day': 'Day 1', 'date': 'Oct 9', 'label': 'Friday'},
    {'day': 'Day 2', 'date': 'Oct 10', 'label': 'Saturday'},
    {'day': 'Day 3', 'date': 'Oct 11', 'label': 'Sunday'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedDayIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index < 0 || index >= _festivalDays.length || _selectedDayIndex == index) return;
    setState(() {
      _selectedDayIndex = index;
      _pullExtent = 0.0;
      _hapticFired = false;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToNextDay() {
    if (_selectedDayIndex < _festivalDays.length - 1) {
      _onTabTapped(_selectedDayIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBg = Theme.of(context).colorScheme.surface;
    final bgDark = Theme.of(context).scaffoldBackgroundColor;
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'FESTIVAL TIMELINE',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Day Selector Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: List.generate(_festivalDays.length, (index) {
                final dayInfo = _festivalDays[index];
                final isSelected = _selectedDayIndex == index;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => _onTabTapped(index),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppTheme.electricFireGradient : null,
                          color: isSelected ? null : cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : primaryColor.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                dayInfo['day']!,
                                style: GoogleFonts.orbitron(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isSelected ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                dayInfo['date']!,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Timeline Subtitle Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _festivalDays[_selectedDayIndex]['label']!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ALL TIMES IN IST',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Native Butterworth PageView - zero oscillation, 120 FPS swiping
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _festivalDays.length,
              onPageChanged: (index) {
                if (_selectedDayIndex != index) {
                  setState(() {
                    _selectedDayIndex = index;
                    _pullExtent = 0.0;
                    _hapticFired = false;
                  });
                }
              },
              itemBuilder: (context, dayIndex) {
                return _buildDayEventsList(context, dayIndex, eventsAsync, primaryColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayEventsList(
    BuildContext context,
    int dayIndex,
    AsyncValue<List<EventItem>> eventsAsync,
    Color primaryColor,
  ) {
    final cardBg = Theme.of(context).colorScheme.surface;

    return eventsAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load schedule: $err',
            style: GoogleFonts.rajdhani(color: Colors.redAccent),
          ),
        ),
      ),
      data: (events) {
        final selectedDateFilter = _festivalDays[dayIndex]['date']!;

        // Filter events scheduled on this day
        final dayEvents = events.where((e) {
          final matchesDirect = e.date.contains(selectedDateFilter);
          final matchesStage = e.stages.any((s) => s.date.contains(selectedDateFilter));
          final matchesGeneral = selectedDateFilter == 'Oct 10' && e.date.contains('Oct 10-12');
          return matchesDirect || matchesStage || matchesGeneral;
        }).toList();

        if (dayEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 54,
                    color: primaryColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No events scheduled for ${_festivalDays[dayIndex]['day']}',
                    style: GoogleFonts.orbitron(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select other days to explore festival timeline.',
                    style: GoogleFonts.rajdhani(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final bool hasNextDay = dayIndex < _festivalDays.length - 1;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final m = notification.metrics;
              if (m.pixels > m.maxScrollExtent && hasNextDay) {
                final extent = (m.pixels - m.maxScrollExtent);
                if (extent >= _pullThreshold && !_hapticFired) {
                  HapticFeedback.lightImpact();
                  _hapticFired = true;
                  _pullExtent = extent;
                }
              }
            } else if (notification is ScrollEndNotification) {
              if (_pullExtent >= _pullThreshold && hasNextDay) {
                _pullExtent = 0.0;
                _hapticFired = false;
                _goToNextDay();
              } else {
                _pullExtent = 0.0;
                _hapticFired = false;
              }
            }
            return false;
          },
          child: ListView.builder(
            key: PageStorageKey<int>(dayIndex),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: dayEvents.length + (hasNextDay ? 1 : 0),
            itemBuilder: (context, index) {
              // Footer pull & tap card to transition to next day
              if (index == dayEvents.length) {
                final nextDay = _festivalDays[dayIndex + 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Center(
                    child: InkWell(
                      onTap: _goToNextDay,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'PULL UP OR TAP TO VIEW ${nextDay['day']!.toUpperCase()} (${nextDay['label']!.toUpperCase()})',
                              style: GoogleFonts.orbitron(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final event = dayEvents[index];
              final isLastEvent = index == dayEvents.length - 1 && !hasNextDay;
              final stageForDay = event.stages.where((s) => s.date.contains(selectedDateFilter)).firstOrNull;
              final displayTime = (stageForDay != null && stageForDay.time.isNotEmpty)
                  ? stageForDay.time
                  : event.time;
              final displayVenue = (stageForDay != null && stageForDay.venue.isNotEmpty)
                  ? stageForDay.venue
                  : event.venue;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Connecting timeline line
                  if (!isLastEvent)
                    Positioned(
                      left: 6,
                      top: 22,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.6),
                              primaryColor.withValues(alpha: 0.12),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                  // Dot indicator
                  Positioned(
                    left: 0,
                    top: 14,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.6),
                            blurRadius: 7,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Event Schedule Card
                  Container(
                    margin: const EdgeInsets.only(left: 28, bottom: 16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/events/${event.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1:1 Square Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: event.posterUrl.startsWith('assets/')
                                      ? Image.asset(
                                          event.posterUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: const Color(0xFF1E0A08),
                                            child: const Icon(Icons.bolt, color: Colors.white24, size: 24),
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: event.posterUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: const Color(0xFF140604),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonOrange),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: const Color(0xFF1E0A08),
                                            child: const Icon(Icons.bolt, color: Colors.white24, size: 24),
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Event Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tags & Time Row
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: primaryColor.withValues(alpha: 0.4),
                                              width: 0.6,
                                            ),
                                          ),
                                          child: Text(
                                            event.category.toUpperCase(),
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                        if (event.isStageExperience || event.isWatchableOnly) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                                                width: 0.6,
                                              ),
                                            ),
                                            child: Text(
                                              'OPEN',
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                color: const Color(0xFFFFB300),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        Icon(Icons.access_time, size: 11, color: primaryColor),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            displayTime,
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: primaryColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Title
                                    Text(
                                      event.title,
                                      style: GoogleFonts.orbitron(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 6),

                                    // Venue & Chevron
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 12, color: Colors.white54),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            displayVenue,
                                            style: GoogleFonts.rajdhani(
                                              fontSize: 11,
                                              color: Colors.white60,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.chevron_right, size: 14, color: Colors.white30),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
