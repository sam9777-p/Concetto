import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import 'widgets/event_passcode_prompt.dart';
import 'event_editor_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClub = 'All';
  bool _isSeeding = false;

  final List<String> _clubs = [
    'All',
    'RoboISM',
    'CyberLabs',
    'MechismuS',
    'E-Cell IIT (ISM)',
    '180 Degrees Consulting',
    'Product Management Club',
    'Electronics Club',
    'IEEE Student Branch',
    'Animation & Art Society',
    'Concetto Core Team',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seedMockData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.scaffoldBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cyberAmber, width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.cloud_sync_outlined, color: AppTheme.cyberAmber),
            const SizedBox(width: 10),
            Text(
              'Sync Mock Data',
              style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'This will push all 12+ pre-configured festival events into your Cloud Firestore database with default test passcodes ("concetto2026"). Continue?',
          style: GoogleFonts.rajdhani(fontSize: 14, color: AppTheme.metallicSilver),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.metallicMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cyberAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'SYNC TO CLOUD',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);
    final count = await ref.read(firestoreServiceProvider).seedMockEventsToFirestore();
    ref.invalidate(eventsProvider);
    setState(() => _isSeeding = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced $count events to Cloud Firestore!'),
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
      onAuthorized: (passcode, isMaster) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventEditorScreen(
              initialEvent: event,
              authorizedPasscode: passcode,
              isMasterAdmin: isMaster,
            ),
          ),
        );
      },
    );
  }

  void _onDeleteEvent(EventItem event) {
    EventPasscodePrompt.show(
      context,
      event: event,
      actionTitle: 'Delete Event',
      onAuthorized: (passcode, isMaster) async {
        try {
          await ref.read(firestoreServiceProvider).deleteEvent(
                event.id,
                passcode,
                isMasterAdmin: isMaster,
              );
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

  Future<void> _toggleFlagship(EventItem event) async {
    final updated = event.copyWith(isFlagship: !event.isFlagship);
    await ref.read(firestoreServiceProvider).updateEvent(
          updated,
          '',
          isMasterAdmin: true,
        );
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
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: Text(
          'ADMIN COMMAND HUB',
          style: GoogleFonts.orbitron(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Mock Events to Cloud',
            icon: _isSeeding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyberAmber),
                  )
                : const Icon(Icons.cloud_sync, color: AppTheme.cyberAmber),
            onPressed: _isSeeding ? null : _seedMockData,
          ),
          IconButton(
            tooltip: 'Exit Admin Portal',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
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
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EventEditorScreen(),
            ),
          );
        },
      ),
      body: eventsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.neonOrange),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading events: $error'),
        ),
        data: (allEvents) {
          // Filter events
          final filteredEvents = allEvents.where((e) {
            final matchesQuery = _searchQuery.isEmpty ||
                e.title.toLowerCase().contains(_searchQuery) ||
                e.organizerClub.toLowerCase().contains(_searchQuery) ||
                e.coordinatorName.toLowerCase().contains(_searchQuery);

            final matchesClub = _selectedClub == 'All' ||
                e.organizerClub.toLowerCase().contains(_selectedClub.toLowerCase());

            return matchesQuery && matchesClub;
          }).toList();

          final flagshipCount = allEvents.where((e) => e.isFlagship).length;
          final uniqueClubs = allEvents.map((e) => e.organizerClub).toSet().length;

          return RefreshIndicator(
            color: AppTheme.neonOrange,
            onRefresh: () async => ref.invalidate(eventsProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Metric Stats Cards
                _buildMetricsBanner(
                  total: allEvents.length,
                  flagship: flagshipCount,
                  clubs: uniqueClubs,
                ),
                const SizedBox(height: 16),

                // 2. Search Field
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

                // 3. Club Filter Chips
                SizedBox(
                  height: 38,
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
                            fontSize: 13,
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

                // 4. Header with Result Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EVENT CATALOG (${filteredEvents.length})',
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.metallicMuted,
                      ),
                    ),
                    Text(
                      'Tap card actions to edit or delete',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. Events List
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

                // Space for FAB
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsBanner({required int total, required int flagship, required int clubs}) {
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
          _buildMetricItem('TOTAL EVENTS', total.toString(), AppTheme.neonOrange),
          Container(width: 1, height: 36, color: Colors.white12),
          _buildMetricItem('FLAGSHIP', flagship.toString(), AppTheme.cyberAmber),
          Container(width: 1, height: 36, color: Colors.white12),
          _buildMetricItem('ACTIVE CLUBS', clubs.toString(), AppTheme.neonEmerald),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.metallicMuted,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminEventCard(EventItem event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: event.posterUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: Colors.black26),
                    errorWidget: (_, _, _) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.black26,
                      child: const Icon(Icons.broken_image, size: 24, color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
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
                                  fontSize: 10,
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
                          Icon(Icons.location_on_outlined, size: 13, color: AppTheme.metallicMuted),
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

          // Divider
          const Divider(height: 1, color: Colors.white10),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                if (event.prizePool.isNotEmpty) ...[
                  Icon(Icons.emoji_events_outlined, size: 15, color: AppTheme.neonEmerald),
                  const SizedBox(width: 4),
                  Text(
                    event.prizePool,
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonEmerald,
                    ),
                  ),
                ],
                const Spacer(),

                // Flagship Toggle
                IconButton(
                  tooltip: event.isFlagship ? 'Unmark Flagship' : 'Mark as Flagship',
                  icon: Icon(
                    event.isFlagship ? Icons.star : Icons.star_border,
                    size: 20,
                    color: event.isFlagship ? AppTheme.cyberAmber : Colors.white38,
                  ),
                  onPressed: () => _toggleFlagship(event),
                ),

                // Edit Button
                IconButton(
                  tooltip: 'Edit Event (Requires Passcode)',
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.neonOrange),
                  onPressed: () => _onEditEvent(event),
                ),

                // Delete Button
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
