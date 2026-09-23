import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _selectedDayIndex = 0;
  int _slideDirection = 1; // 1 = forward, -1 = backward
  bool _isTransitioning = false;

  final List<Map<String, String>> _festivalDays = [
    {'day': 'DAY 0', 'date': 'Oct 8', 'label': 'Wednesday • Inauguration & CaseBlitz'},
    {'day': 'DAY 1', 'date': 'Oct 9', 'label': 'Thursday • Keynotes & Competitions'},
    {'day': 'DAY 2', 'date': 'Oct 10', 'label': 'Friday • Battles & Hackathons'},
    {'day': 'DAY 3', 'date': 'Oct 11', 'label': 'Saturday • Grand Finale & Star Night'},
  ];

  void _changeDay(int newIndex, {required int direction}) {
    if (newIndex < 0 || newIndex >= _festivalDays.length || _isTransitioning) return;
    setState(() {
      _slideDirection = direction;
      _selectedDayIndex = newIndex;
      _isTransitioning = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        if (_selectedDayIndex != index) {
                          _changeDay(index, direction: index > _selectedDayIndex ? 1 : -1);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                          children: [
                            Text(
                              dayInfo['day']!,
                              style: GoogleFonts.orbitron(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayInfo['date']!,
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.black87
                                    : AppTheme.metallicMuted,
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

          // Timeline Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _festivalDays[_selectedDayIndex]['label']!.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: primaryColor,
                  ),
                ),
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

          const SizedBox(height: 8),

          // Dynamic Vertical Timeline with Auto Day Transition
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -250 && _selectedDayIndex < _festivalDays.length - 1) {
                    _changeDay(_selectedDayIndex + 1, direction: 1);
                  } else if (details.primaryVelocity! > 250 && _selectedDayIndex > 0) {
                    _changeDay(_selectedDayIndex - 1, direction: -1);
                  }
                }
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (_isTransitioning) return false;
                  if (notification is OverscrollNotification) {
                    if (notification.overscroll > 15 && _selectedDayIndex < _festivalDays.length - 1) {
                      _changeDay(_selectedDayIndex + 1, direction: 1);
                      return true;
                    } else if (notification.overscroll < -15 && _selectedDayIndex > 0) {
                      _changeDay(_selectedDayIndex - 1, direction: -1);
                      return true;
                    }
                  } else if (notification is ScrollEndNotification) {
                    final m = notification.metrics;
                    if (m.extentAfter == 0 && m.pixels > m.maxScrollExtent + 20 && _selectedDayIndex < _festivalDays.length - 1) {
                      _changeDay(_selectedDayIndex + 1, direction: 1);
                    } else if (m.extentBefore == 0 && m.pixels < -20 && _selectedDayIndex > 0) {
                      _changeDay(_selectedDayIndex - 1, direction: -1);
                    }
                  }
                  return false;
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0.0, _slideDirection > 0 ? 0.06 : -0.06),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedDayIndex),
                    child: eventsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(
                        child: Text(
                          'Failed to load schedule: $err',
                          style: GoogleFonts.rajdhani(color: Colors.redAccent),
                        ),
                      ),
                      data: (events) {
                        final selectedDateFilter = _festivalDays[_selectedDayIndex]['date']!;

                        // Filter events scheduled on this day
                        final dayEvents = events.where((e) {
                          return e.date.contains(selectedDateFilter) ||
                              e.date.contains('Oct 10-12');
                        }).toList();

                        if (dayEvents.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy, size: 56, color: primaryColor.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No events scheduled for ${_festivalDays[_selectedDayIndex]['day']}',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Swipe or select another festival day.',
                                    style: GoogleFonts.rajdhani(color: Colors.white60, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          itemCount: dayEvents.length + 1,
                          itemBuilder: (context, index) {
                            if (index == dayEvents.length) {
                              // Next Day or Finale Card
                              final hasNext = _selectedDayIndex < _festivalDays.length - 1;
                              final nextDay = hasNext ? _festivalDays[_selectedDayIndex + 1] : null;

                              return Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 20),
                                child: InkWell(
                                  onTap: hasNext
                                      ? () => _changeDay(_selectedDayIndex + 1, direction: 1)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: hasNext
                                          ? primaryColor.withValues(alpha: 0.1)
                                          : Colors.amber.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: hasNext
                                            ? primaryColor.withValues(alpha: 0.3)
                                            : Colors.amber.withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          hasNext ? Icons.arrow_downward : Icons.stars_rounded,
                                          size: 16,
                                          color: hasNext ? primaryColor : Colors.amber,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          hasNext
                                              ? 'SCROLL UP OR TAP FOR ${nextDay!['day']} (${nextDay['date']}) →'
                                              : '★ YOU HAVE REACHED THE GRAND FINALE OF CONCETTO \'26 ★',
                                          style: GoogleFonts.rajdhani(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color: hasNext ? primaryColor : Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

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
                                          padding: const EdgeInsets.all(14),
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
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
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
                                                          style: GoogleFonts.rajdhani(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w800,
                                                            color: primaryColor,
                                                            letterSpacing: 0.8,
                                                          ),
                                                        ),
                                                      ),
                                                      if (event.isWatchableOnly) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
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
                                                            'STAGE / OPEN',
                                                            style: GoogleFonts.rajdhani(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w800,
                                                              color: Colors.amber,
                                                              letterSpacing: 0.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.access_time, size: 13, color: primaryColor),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        event.time,
                                                        style: GoogleFonts.rajdhani(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                event.title,
                                                style: GoogleFonts.rajdhani(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            event.venue,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: GoogleFonts.rajdhani(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                              color: Colors.white60,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
                                                ],
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
