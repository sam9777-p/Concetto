import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import 'widgets/event_passcode_prompt.dart';
import 'event_editor_screen.dart';

class EventOperationsScreen extends ConsumerStatefulWidget {
  const EventOperationsScreen({super.key});

  @override
  ConsumerState<EventOperationsScreen> createState() => _EventOperationsScreenState();
}

class _EventOperationsScreenState extends ConsumerState<EventOperationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClub = 'All';
  String _visibilityFilter = 'All'; // 'All', 'Visible', 'Hidden'

  final List<String> _clubs = [
    'All',
    'RoboISM',
    'CyberLabs',
    'MechismuS',
    'E-Cell IIT (ISM)',
    '180 Degrees Consulting',
    'Product Management Club',
    'Fintech Club',
    'Electronics & IoT',
    'Society of Electronics Engineers',
    'Society of MnC',
    'Civil Engineering Society',
    'Chemical Engineering Society',
    'IADC IIT(ISM) Dhanbad SC',
    'SPE IIT(ISM) Dhanbad',
    'ASTC',
    'QARC',
    'C3',
    'Maths Club',
    'Quiz Club',
    'AnGd',
    'Concetto Organizing Team',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() {
          _searchQuery = q;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _onAddNewEvent() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const EventEditorScreen(
          isMasterAdmin: true,
          isDeveloperMode: true,
        ),
      ),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: AppTheme.neonEmerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onEditEvent(EventItem event) {
    EventPasscodePrompt.show(
      context,
      event: event,
      actionTitle: 'Edit Event',
      onAuthorized: (masterPass, secondaryPass, isDevOverride) async {
        // Fetch fresh event directly from Firestore so latest edited values are displayed
        final freshEvent = await ref.read(firestoreServiceProvider).getEventById(event.id) ?? event;

        if (!mounted) return;
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => EventEditorScreen(
              initialEvent: freshEvent,
              authorizedPasscode: secondaryPass,
              isMasterAdmin: true,
              isDeveloperMode: true,
            ),
          ),
        );
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      result,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF140806),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  void _onDeleteEvent(EventItem event) {
    EventPasscodePrompt.show(
      context,
      event: event,
      actionTitle: 'Delete Event',
      onAuthorized: (masterPass, secondaryPass, isDevOverride) async {
        try {
          await ref.read(firestoreServiceProvider).deleteEvent(event.id);
          ref.invalidate(adminEventsProvider);
          ref.invalidate(eventsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Event "${event.title}" has been deleted.'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Delete failed: $e')),
            );
          }
        }
      },
    );
  }

  Future<void> _onToggleVisibility(EventItem event, bool newValue) async {
    try {
      await ref.read(firestoreServiceProvider).toggleEventVisibility(event.id, newValue);
      ref.invalidate(adminEventsProvider);
      ref.invalidate(eventsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newValue ? Icons.visibility : Icons.visibility_off,
                  color: newValue ? const Color(0xFF00E676) : Colors.orangeAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newValue
                        ? '"${event.title}" is now VISIBLE to students.'
                        : '"${event.title}" is now HIDDEN from students.',
                    style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF140605),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update visibility: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlagship(EventItem event) async {
    final updated = event.copyWith(isFlagship: !event.isFlagship);
    await ref.read(firestoreServiceProvider).updateEvent(updated);
    ref.invalidate(adminEventsProvider);
    ref.invalidate(eventsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isFlagship
                ? '${event.title} marked as Flagship!'
                : '${event.title} removed from Flagship.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminEventsProvider);

    if (eventsAsync.isLoading && !eventsAsync.hasValue) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg,
          title: Text(
            'EVENT OPERATIONS',
            style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonOrange),
        ),
      );
    }

    final allEvents = eventsAsync.asData?.value ?? const <EventItem>[];

    final filteredEvents = allEvents.where((e) {
      final matchesQuery = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery) ||
          e.organizerClub.toLowerCase().contains(_searchQuery) ||
          e.coordinatorName.toLowerCase().contains(_searchQuery);

      final matchesClub = _selectedClub == 'All' ||
          e.organizerClub.toLowerCase().contains(_selectedClub.toLowerCase());

      final bool matchesVisibility;
      if (_visibilityFilter == 'Visible') {
        matchesVisibility = e.isVisible;
      } else if (_visibilityFilter == 'Hidden') {
        matchesVisibility = !e.isVisible;
      } else {
        matchesVisibility = true;
      }

      return matchesQuery && matchesClub && matchesVisibility;
    }).toList();

    final totalCount = allEvents.length;
    final visibleCount = allEvents.where((e) => e.isVisible).length;
    final hiddenCount = allEvents.where((e) => !e.isVisible).length;
    final flagshipCount = allEvents.where((e) => e.isFlagship).length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'EVENT OPERATIONS',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF00E676), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.code_rounded, color: Color(0xFF00E676), size: 12),
                const SizedBox(width: 4),
                Text(
                  'DEV AUTHORIZED',
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00E676),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.neonOrange,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(
          'ADD NEW EVENT',
          style: GoogleFonts.rajdhani(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        onPressed: _onAddNewEvent,
      ),
      body: Column(
        children: [
          if (eventsAsync.isRefreshing || (eventsAsync.isLoading && eventsAsync.hasValue))
            const LinearProgressIndicator(
              minHeight: 2.5,
              color: AppTheme.neonOrange,
              backgroundColor: Colors.transparent,
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.neonOrange,
              onRefresh: () async => ref.invalidate(adminEventsProvider),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildMetricsBanner(
                    total: totalCount,
                    visible: visibleCount,
                    hidden: hiddenCount,
                    flagship: flagshipCount,
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardSurface,
                      hintText: 'Search by title, club, or coordinator...',
                      hintStyle: GoogleFonts.rajdhani(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.neonOrange, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.white54),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.neonOrange),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _buildVisibilityFilterChip('All', 'ALL (${allEvents.length})'),
                      const SizedBox(width: 8),
                      _buildVisibilityFilterChip('Visible', 'VISIBLE ($visibleCount)', const Color(0xFF00E676)),
                      const SizedBox(width: 8),
                      _buildVisibilityFilterChip('Hidden', 'NOT VISIBLE ($hiddenCount)', Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(Icons.corporate_fare, size: 13, color: AppTheme.cyberAmber),
                      const SizedBox(width: 6),
                      Text(
                        'FILTER BY ORGANIZING CLUB / SOCIETY',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.cyberAmber,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _clubs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final club = _clubs[index];
                        final isSelected = _selectedClub == club;

                        return ChoiceChip(
                          label: Text(
                            club,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : AppTheme.metallicSilver,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.neonOrange,
                          backgroundColor: AppTheme.cardSurface,
                          side: BorderSide(
                            color: isSelected ? AppTheme.neonOrange : Colors.white12,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedClub = club;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'EVENT CATALOG (${filteredEvents.length})',
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.metallicMuted,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (filteredEvents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.event_busy_outlined, color: Colors.white24, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No events match your search or filter.',
                            style: GoogleFonts.rajdhani(fontSize: 15, color: Colors.white60),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredEvents.map((event) => _buildAdminEventCard(event)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityFilterChip(String filterKey, String label, [Color? activeColor]) {
    final isSelected = _visibilityFilter == filterKey;
    final color = activeColor ?? AppTheme.neonOrange;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _visibilityFilter = filterKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.metallicMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsBanner({
    required int total,
    required int visible,
    required int hidden,
    required int flagship,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.35), width: 0.8),
        gradient: AppTheme.darkCardGradient,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem('TOTAL', total.toString(), Colors.white),
          Container(width: 1, height: 36, color: Colors.white12),
          _buildMetricItem('LIVE', visible.toString(), const Color(0xFF00E676)),
          Container(width: 1, height: 36, color: Colors.white12),
          _buildMetricItem('HIDDEN', hidden.toString(), Colors.orangeAccent),
          Container(width: 1, height: 36, color: Colors.white12),
          _buildMetricItem('FLAGSHIP', flagship.toString(), AppTheme.cyberAmber),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.metallicMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminEventCard(EventItem event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: event.isVisible ? Colors.white12 : Colors.orangeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: event.posterUrl,
                    width: 96,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(width: 96, height: 64, color: Colors.black26),
                    errorWidget: (_, _, _) => Container(
                      width: 96,
                      height: 64,
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image, size: 24, color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.rajdhani(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (event.isFlagship)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.neonOrange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.neonOrange, width: 0.8),
                              ),
                              child: Text(
                                'FLAGSHIP',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neonOrange,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.organizerClub,
                        style: GoogleFonts.rajdhani(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.cyberAmber,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.metallicMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${event.venue} • ${event.date}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                color: AppTheme.metallicMuted,
                              ),
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

          // VISIBILITY SLIDER ROW
          InkWell(
            onTap: () => _onToggleVisibility(event, !event.isVisible),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF140806),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    event.isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                    color: event.isVisible ? const Color(0xFF00E676) : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.isVisible ? 'LIVE & VISIBLE TO STUDENTS' : 'HIDDEN FROM STUDENTS',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: event.isVisible ? const Color(0xFF00E676) : Colors.orangeAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Switch(
                    value: event.isVisible,
                    activeThumbColor: AppTheme.neonOrange,
                    activeTrackColor: AppTheme.neonOrange.withValues(alpha: 0.4),
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.white12,
                    onChanged: (val) => _onToggleVisibility(event, val),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                if (event.prizePool.isNotEmpty) ...[
                  const Icon(Icons.emoji_events_outlined, size: 15, color: AppTheme.neonEmerald),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      event.prizePool,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonEmerald,
                      ),
                    ),
                  ),
                ],
                const Spacer(),

                IconButton(
                  tooltip: event.isFlagship ? 'Unmark Flagship' : 'Mark as Flagship',
                  icon: Icon(
                    event.isFlagship ? Icons.star : Icons.star_border,
                    size: 20,
                    color: event.isFlagship ? AppTheme.cyberAmber : Colors.white38,
                  ),
                  onPressed: () => _toggleFlagship(event),
                ),

                IconButton(
                  tooltip: 'Edit Event (Master + Specific/Dev Passkey)',
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.neonOrange),
                  onPressed: () => _onEditEvent(event),
                ),

                IconButton(
                  tooltip: 'Delete Event',
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  onPressed: () => _onDeleteEvent(event),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
