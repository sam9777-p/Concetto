import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/repositories.dart';
import '../../core/network/mock_data.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import 'widgets/event_passcode_prompt.dart';
import 'event_editor_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final bool initialIsDeveloper;

  const AdminDashboardScreen({
    super.key,
    this.initialIsDeveloper = false,
  });

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClub = 'All';
  String _visibilityFilter = 'All'; // 'All', 'Visible', 'Hidden'
  bool _isSeeding = false;
  late bool _isDeveloperMode;

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
    _isDeveloperMode = widget.initialIsDeveloper;
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

  Future<bool> _promptDevUnlock([String? customMessage]) async {
    final devController = TextEditingController();
    bool obscure = true;
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: AppTheme.scaffoldBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.neonOrange, width: 1.2),
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppTheme.darkCardGradient,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.code_rounded, color: AppTheme.neonOrange, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DEVELOPER AUTHORIZATION',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  customMessage ?? 'Enter Developer Password to unlock full system controls (event visibility toggles and event creation).',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.metallicSilver,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: devController,
                  obscureText: obscure,
                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF140705),
                    hintText: 'Developer Password',
                    hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.neonOrange, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 18),
                      onPressed: () => setDlgState(() => obscure = !obscure),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) {
                    final valid = MasterAdminConfig.verifyDev(devController.text);
                    if (valid) {
                      Navigator.of(context).pop(true);
                    } else {
                      setDlgState(() => error = 'Invalid Developer Password.');
                    }
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'CANCEL',
                          style: GoogleFonts.rajdhani(color: AppTheme.metallicMuted, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonOrange,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final valid = MasterAdminConfig.verifyDev(devController.text);
                          if (valid) {
                            Navigator.of(context).pop(true);
                          } else {
                            setDlgState(() => error = 'Invalid Developer Password.');
                          }
                        },
                        child: Text(
                          'UNLOCK',
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, letterSpacing: 1),
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
    );

    if (result == true) {
      if (!mounted) return true;
      setState(() => _isDeveloperMode = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Developer Access Unlocked. You can now toggle event visibility and add events.'),
          backgroundColor: Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }
    return false;
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
              'Sync 55 Events to Cloud',
              style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'This will synchronize all 55 verified festival events with their dedicated passkeys to the live cloud database. Continue?',
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
              'SYNC ALL EVENTS',
              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);
    final results = await ref.read(firestoreServiceProvider).seedAllDataToFirestore();
    ref.invalidate(eventsProvider);
    ref.invalidate(announcementsProvider);
    ref.invalidate(teamProvider);
    setState(() => _isSeeding = false);

    if (mounted) {
      final total = (results['events'] ?? 0) + (results['announcements'] ?? 0) + (results['team'] ?? 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced $total items (${results['events']} events, ${results['announcements']} announcements, ${results['team']} team) to database "concetto"!'),
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
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (context) => EventEditorScreen(
              initialEvent: event,
              authorizedPasscode: secondaryPass,
              isMasterAdmin: true,
              isDeveloperMode: isDevOverride || _isDeveloperMode,
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
    // 1. Instantly update in local MockData and trigger local rebuild for immediate slider animation
    final idx = MockData.events.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      MockData.events[idx] = MockData.events[idx].copyWith(isVisible: newValue);
    }
    setState(() {});

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
      if (idx >= 0) {
        MockData.events[idx] = MockData.events[idx].copyWith(isVisible: !newValue);
      }
      setState(() {});
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

    // If initial fetch with no data, show loading screen
    if (eventsAsync.isLoading && !eventsAsync.hasValue && MockData.events.isEmpty) {
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
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonOrange),
        ),
      );
    }

    final allEvents = eventsAsync.asData?.value ?? MockData.events;

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
          if (_isDeveloperMode)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF00E676), width: 0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.code_rounded, color: Color(0xFF00E676), size: 11),
                  const SizedBox(width: 3),
                  Text(
                    'DEV',
                    style: GoogleFonts.rajdhani(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00E676),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.lock_outline, size: 14, color: AppTheme.cyberAmber),
              label: Text(
                'UNLOCK DEV',
                style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.cyberAmber),
              ),
              onPressed: () => _promptDevUnlock(),
            ),

          IconButton(
            tooltip: 'Sync 55 Events',
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

                  if (totalCount < 50) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cyberAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cyberAmber, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: AppTheme.cyberAmber, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Live database has $totalCount events. Upload full 55 events to cloud database.',
                              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isSeeding ? null : _seedMockData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cyberAmber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              'SYNC NOW',
                              style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : AppTheme.cardSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white12,
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          alignment: Alignment.center,
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
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 10.5,
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
                  Icon(Icons.emoji_events_outlined, size: 15, color: AppTheme.neonEmerald),
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
