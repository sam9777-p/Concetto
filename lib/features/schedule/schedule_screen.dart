import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  int _slideDirection = 1; // 1 = forward, -1 = backward
  bool _isTransitioning = false;
  double _pullExtent = 0.0;
  int _pullDirection = 0; // 1 = pulled up at bottom for next day, -1 = pulled down at top for prev day
  bool _hapticFired = false;
  static const double _pullThreshold = 65.0;
  DateTime _lastTransitionTime = DateTime.now();

  final List<Map<String, String>> _festivalDays = [
    {'day': 'Thursday', 'date': 'Oct 8', 'label': 'Thursday • Inauguration & CaseBlitz'},
    {'day': 'Friday', 'date': 'Oct 9', 'label': 'Friday • Keynotes & Competitions'},
    {'day': 'Saturday', 'date': 'Oct 10', 'label': 'Saturday • Battles & Workshops'},
    {'day': 'Sunday', 'date': 'Oct 11', 'label': 'Sunday • Grand Finale & Star Night'},
  ];

  void _changeDay(int newIndex, {required int direction}) {
    if (newIndex < 0 || newIndex >= _festivalDays.length || _isTransitioning) return;
    final now = DateTime.now();
    if (now.difference(_lastTransitionTime).inMilliseconds < 450) return;

    _lastTransitionTime = now;
    setState(() {
      _slideDirection = direction;
      _selectedDayIndex = newIndex;
      _isTransitioning = true;
      _pullExtent = 0.0;
      _pullDirection = 0;
      _hapticFired = false;
    });

    Future.delayed(const Duration(milliseconds: 380), () {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
          _pullExtent = 0.0;
          _pullDirection = 0;
          _hapticFired = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        surfaceTintColor: Colors.transparent,
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
                      onTap: () {
                        if (_selectedDayIndex != index && !_isTransitioning) {
                          _changeDay(index, direction: index > _selectedDayIndex ? 1 : -1);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppTheme.electricFireGradient : null,
                          color: isSelected ? null : const Color(0xFF140604),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : primaryColor.withValues(alpha: 0.3),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
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
                                      : AppTheme.metallicMuted,
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

          // Timeline Banner (Zero-overflow responsive row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _festivalDays[_selectedDayIndex]['label']!.toUpperCase(),
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 6),

          // Dynamic Vertical Timeline with Hard Pull / Overscroll Gesture & Swipe Day Switching
          Expanded(
            child: Listener(
              onPointerUp: (event) {
                if (_isTransitioning) return;
                if (_pullExtent >= _pullThreshold) {
                  final dir = _pullDirection;
                  final target = dir == 1 ? _selectedDayIndex + 1 : _selectedDayIndex - 1;
                  setState(() {
                    _pullExtent = 0.0;
                    _pullDirection = 0;
                    _hapticFired = false;
                  });
                  if (dir == 1 && target < _festivalDays.length) {
                    _changeDay(target, direction: 1);
                  } else if (dir == -1 && target >= 0) {
                    _changeDay(target, direction: -1);
                  }
                } else if (_pullExtent > 0) {
                  setState(() {
                    _pullExtent = 0.0;
                    _pullDirection = 0;
                    _hapticFired = false;
                  });
                }
              },
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (_isTransitioning) return;
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -250 && _selectedDayIndex < _festivalDays.length - 1) {
                      _changeDay(_selectedDayIndex + 1, direction: 1);
                    } else if (details.primaryVelocity! > 250 && _selectedDayIndex > 0) {
                      _changeDay(_selectedDayIndex - 1, direction: -1);
                    }
                  }
                },
                child: Stack(
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (_isTransitioning) return false;

                        final now = DateTime.now();
                        if (now.difference(_lastTransitionTime).inMilliseconds < 450) {
                          return false;
                        }

                        if (notification is ScrollUpdateNotification) {
                          final m = notification.metrics;
                          // Bottom pull (pulling up at bottom of day list to go next)
                          if (m.pixels > m.maxScrollExtent && _selectedDayIndex < _festivalDays.length - 1) {
                            final extent = (m.pixels - m.maxScrollExtent).clamp(0.0, 120.0);
                            if ((extent - _pullExtent).abs() > 1.0) {
                              if (extent >= _pullThreshold && !_hapticFired) {
                                HapticFeedback.lightImpact();
                                _hapticFired = true;
                              } else if (extent < _pullThreshold) {
                                _hapticFired = false;
                              }
                              setState(() {
                                _pullExtent = extent;
                                _pullDirection = 1;
                              });
                            }
                          }
                          // Top pull (pulling down at top of day list to go prev)
                          else if (m.pixels < m.minScrollExtent && _selectedDayIndex > 0) {
                            final extent = (m.minScrollExtent - m.pixels).clamp(0.0, 120.0);
                            if ((extent - _pullExtent).abs() > 1.0) {
                              if (extent >= _pullThreshold && !_hapticFired) {
                                HapticFeedback.lightImpact();
                                _hapticFired = true;
                              } else if (extent < _pullThreshold) {
                                _hapticFired = false;
                              }
                              setState(() {
                                _pullExtent = extent;
                                _pullDirection = -1;
                              });
                            }
                          }
                          // In-bounds normal scrolling
                          else if (_pullExtent > 0 && m.pixels >= m.minScrollExtent && m.pixels <= m.maxScrollExtent) {
                            setState(() {
                              _pullExtent = 0.0;
                              _pullDirection = 0;
                              _hapticFired = false;
                            });
                          }
                        } else if (notification is ScrollEndNotification) {
                          if (_pullExtent > 0 && _pullExtent < _pullThreshold) {
                            setState(() {
                              _pullExtent = 0.0;
                              _pullDirection = 0;
                              _hapticFired = false;
                            });
                          }
                        }
                        return false;
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(_slideDirection > 0 ? 0.08 : -0.08, 0.0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: dayEvents.length,
                          itemBuilder: (context, index) {
                            final event = dayEvents[index];
                            final isLast = index == dayEvents.length - 1;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Timeline line & indicator
                                  SizedBox(
                                    width: 24,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryColor.withValues(alpha: 0.6),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    primaryColor.withValues(alpha: 0.6),
                                                    primaryColor.withValues(alpha: 0.15),
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

                                  const SizedBox(width: 12),

                                  // Event Schedule Card
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: InkWell(
                                        onTap: () => context.push('/events/detail', extra: event),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF110604),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: primaryColor.withValues(alpha: 0.35),
                                              width: 0.8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryColor.withValues(alpha: 0.06),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // 2:3 rectangle portrait photo
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: SizedBox(
                                                  width: 96,
                                                  height: 64, // 2:3 ratio (68 x 102)
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      event.posterUrl.startsWith('assets/')
                                                           ? Image.asset(
                                                               event.posterUrl,
                                                               fit: BoxFit.cover,
                                                               errorBuilder: (_, _, _) => Container(
                                                                 color: const Color(0xFF1A0A08),
                                                                 child: const Icon(Icons.bolt, color: Colors.white24, size: 24),
                                                               ),
                                                             )
                                                           : CachedNetworkImage(
                                                               imageUrl: event.posterUrl,
                                                               fit: BoxFit.cover,
                                                               placeholder: (_, _) => Container(color: const Color(0xFF140604)),
                                                               errorWidget: (_, _, _) => Container(
                                                                 color: const Color(0xFF1A0A08),
                                                                 child: const Icon(Icons.bolt, color: Colors.white24, size: 24),
                                                               ),
                                                             ),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.transparent,
                                                              Colors.black.withValues(alpha: 0.5),
                                                            ],
                                                            begin: Alignment.topCenter,
                                                            end: Alignment.bottomCenter,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Flexible(
                                                                child: Container(
                                                                  padding: const EdgeInsets.symmetric(
                                                                    horizontal: 7,
                                                                    vertical: 2.5,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: primaryColor.withValues(alpha: 0.15),
                                                                    borderRadius: BorderRadius.circular(6),
                                                                    border: Border.all(
                                                                      color: primaryColor.withValues(alpha: 0.4),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    event.category.toUpperCase(),
                                                                    maxLines: 1,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: GoogleFonts.rajdhani(
                                                                      fontSize: 9.5,
                                                                      fontWeight: FontWeight.w800,
                                                                      color: primaryColor,
                                                                      letterSpacing: 0.8,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              if (event.isWatchableOnly) ...[
                                                                const SizedBox(width: 5),
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(
                                                                    horizontal: 5,
                                                                    vertical: 2,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.amber.withValues(alpha: 0.15),
                                                                    borderRadius: BorderRadius.circular(4),
                                                                    border: Border.all(
                                                                      color: Colors.amber.withValues(alpha: 0.5),
                                                                      width: 0.7,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    'OPEN',
                                                                    style: GoogleFonts.rajdhani(
                                                                      fontSize: 8.5,
                                                                      fontWeight: FontWeight.w800,
                                                                      color: Colors.amber,
                                                                      letterSpacing: 0.5,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.access_time, size: 12, color: primaryColor),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              event.time,
                                                              style: GoogleFonts.rajdhani(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w700,
                                                                color: primaryColor,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      event.title,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.rajdhani(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Row(
                                                            children: [
                                                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                                              const SizedBox(width: 3),
                                                              Expanded(
                                                                child: Text(
                                                                  event.venue,
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: GoogleFonts.rajdhani(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: Colors.white60,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        const Icon(Icons.arrow_forward_ios, size: 11, color: Colors.white38),
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
                              ),
                            ).animate().fadeIn(duration: 250.ms, delay: (index * 40).clamp(0, 350).ms).slideX(begin: 0.04, end: 0);
                          },
                        );
                      },
                    ),

                    // Minimal Floating Pull Indicator (arrow + day name)
                    _buildPullIndicator(primaryColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPullIndicator(Color primaryColor) {
    if (_pullExtent < 12.0 || _pullDirection == 0) return const SizedBox.shrink();

    final isTriggered = _pullExtent >= _pullThreshold;
    final isNext = _pullDirection == 1;
    final String targetDay = isNext
        ? (_selectedDayIndex < _festivalDays.length - 1 ? (_festivalDays[_selectedDayIndex + 1]['day'] ?? '') : '')
        : (_selectedDayIndex > 0 ? (_festivalDays[_selectedDayIndex - 1]['day'] ?? '') : '');

    if (targetDay.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: isNext ? null : 16,
      bottom: isNext ? 24 : null,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isTriggered ? primaryColor : const Color(0xFF140604).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isTriggered ? Colors.white : primaryColor.withValues(alpha: 0.6),
              width: isTriggered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isTriggered ? primaryColor.withValues(alpha: 0.6) : Colors.black54,
                blurRadius: isTriggered ? 16 : 8,
                spreadRadius: isTriggered ? 2 : 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNext ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 16,
                color: isTriggered ? Colors.black : primaryColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isTriggered
                      ? 'Release to view $targetDay'
                      : (isNext ? 'Pull up for $targetDay' : 'Pull down for $targetDay'),
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isTriggered ? Colors.black : Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayEventsList(
    BuildContext context,
    int dayIndex,
    AsyncValue<List<EventItem>> eventsAsync,
    Color primaryColor,
  ) {
    return eventsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.neonOrange),
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

        // Filter events scheduled on this day (direct match or stage match)
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

        return ListView.builder(
          key: PageStorageKey<int>(dayIndex),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          itemCount: dayEvents.length,
          itemBuilder: (context, index) {
            final event = dayEvents[index];
            final isLastEvent = index == dayEvents.length - 1;
            final stageForDay = event.stages.where((s) => s.date.contains(selectedDateFilter)).firstOrNull;
            final displayTime = (stageForDay != null && stageForDay.time.isNotEmpty)
                ? stageForDay.time
                : event.time;
            final displayVenue = (stageForDay != null && stageForDay.venue.isNotEmpty)
                ? stageForDay.venue
                : event.venue;

            // Single-pass Stack layout (No IntrinsicHeight) for 120 FPS speed
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
                Padding(
                  padding: const EdgeInsets.only(left: 26, bottom: 14),
                  child: InkWell(
                    onTap: () => context.push('/events/detail', extra: event),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF110604),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster image with cache
                          ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: SizedBox(
                              width: 80,
                              height: 60,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  event.posterUrl.startsWith('assets/')
                                      ? Image.asset(
                                          event.posterUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: const Color(0xFF1A0A08),
                                            child: const Icon(Icons.bolt, color: Colors.white24, size: 22),
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: event.posterUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, _) => Container(color: const Color(0xFF140604)),
                                          errorWidget: (_, _, _) => Container(
                                            color: const Color(0xFF1A0A08),
                                            child: const Icon(Icons.bolt, color: Colors.white24, size: 22),
                                          ),
                                        ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.45),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Text details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category badge + Time
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: primaryColor.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Text(
                                                event.category.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.rajdhani(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: primaryColor,
                                                  letterSpacing: 0.7,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (event.isWatchableOnly) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: Colors.amber.withValues(alpha: 0.5),
                                                  width: 0.7,
                                                ),
                                              ),
                                              child: Text(
                                                'OPEN',
                                                style: GoogleFonts.rajdhani(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.amber,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 11, color: primaryColor),
                                        const SizedBox(width: 3),
                                        Text(
                                          displayTime,
                                          style: GoogleFonts.rajdhani(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  stageForDay != null ? '${event.title} — ${stageForDay.name}' : event.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              displayVenue,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white60,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.white38),
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
              ],
            ).animate().fadeIn(duration: 200.ms, delay: (index * 25).clamp(0, 250).ms);
          },
        );
      },
    );
  }
}
