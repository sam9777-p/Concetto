import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/widgets/admin_login_dialog.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'All',
    'Pre-Events',
    'Flagship',
    'Robotics',
    'Coding',
    'Electronics',
    'Management',
    'Departmental',
    'Design',
    'Stage',
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'EVENTS DIRECTORY',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.cyberAmber),
            tooltip: 'Organizer Portal',
            onPressed: () {
              AdminLoginDialog.show(
                context,
                onSuccess: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh events',
            onPressed: () async {
              try {
                final _ = await ref.refresh(eventsProvider.future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Events refreshed successfully'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {}
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF120504),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Search events, domains, venues...',
                  hintStyle: GoogleFonts.rajdhani(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Pre-Events Quick Access Spotlight
          if (_selectedCategoryIndex == 0 && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = 1; // 'Pre-Events'
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6B1124).withValues(alpha: 0.75),
                        const Color(0xFF1E0A24).withValues(alpha: 0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.45), width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722).withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.celebration, color: Color(0xFFFF8A65), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'PRE-FESTIVAL SPECIALS',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5722),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Prom Night \'26 • Kryptos Cryptic Hunt • Movie Night',
                              style: GoogleFonts.rajdhani(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              ),
            ),

          // Horizontal Category Filter Chips
          SizedBox(
            height: 46,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppTheme.electricFireGradient : null,
                        color: isSelected ? null : const Color(0xFF140604),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : primaryColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isSelected ? Colors.black : AppTheme.metallicMuted,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Events Grid
          Expanded(
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                try {
                  final _ = await ref.refresh(eventsProvider.future);
                } catch (_) {}
              },
              child: eventsAsync.when(
                loading: () {
                  final previous = eventsAsync.asData?.value;
                  if (previous != null && previous.isNotEmpty) {
                    return _buildEventsView(context, previous, primaryColor);
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      ),
                    ],
                  );
                },
                error: (err, _) {
                  final previous = eventsAsync.asData?.value;
                  if (previous != null && previous.isNotEmpty) {
                    return _buildEventsView(context, previous, primaryColor);
                  }
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                                const SizedBox(height: 12),
                                Text('Failed to load events: $err', textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: () => ref.invalidate(eventsProvider),
                                  child: const Text('RETRY'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                data: (events) => _buildEventsView(context, events, primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsView(BuildContext context, List<EventItem> events, Color primaryColor) {
    final selectedCategory = _categories[_selectedCategoryIndex];

    // Filter by category & search query
    final filteredEvents = events.where((event) {
      final isPreEvent = event.category.toLowerCase().contains('pre') ||
          event.id.contains('_pre') ||
          event.id.contains('preevent') ||
          event.tags.any((t) => t.toLowerCase().contains('pre'));

      final bool matchesCategory;
      if (selectedCategory == 'All') {
        matchesCategory = true;
      } else if (selectedCategory == 'Pre-Events') {
        matchesCategory = isPreEvent;
      } else if (selectedCategory == 'Flagship') {
        matchesCategory = event.isFlagship ||
            event.category.toLowerCase() == 'flagship' ||
            event.tags.any((t) => t.toLowerCase() == 'flagship');
      } else if (selectedCategory == 'Robotics') {
        matchesCategory = event.category.toLowerCase() == 'robotics' ||
            event.tags.any((t) => t.toLowerCase() == 'robotics') ||
            event.organizerClub.toLowerCase().contains('robo') ||
            event.title.toLowerCase().contains('robo') ||
            event.title.toLowerCase().contains('autonav') ||
            event.title.toLowerCase().contains('aeroglide');
      } else if (selectedCategory == 'Electronics') {
        matchesCategory = event.category.toLowerCase() == 'electronics' ||
            event.tags.any((t) => t.toLowerCase() == 'electronics') ||
            event.organizerClub.toLowerCase().contains('electronic') ||
            event.organizerClub.toLowerCase().contains('see') ||
            event.title.toLowerCase().contains('sparkathon') ||
            event.title.toLowerCase().contains('gate craft') ||
            event.title.toLowerCase().contains('fault hunt');
      } else if (selectedCategory == 'Management') {
        matchesCategory = event.category.toLowerCase() == 'management' ||
            event.tags.any((t) => t.toLowerCase() == 'management') ||
            event.organizerClub.toLowerCase().contains('management') ||
            event.organizerClub.toLowerCase().contains('180dc') ||
            event.organizerClub.toLowerCase().contains('fintech') ||
            event.title.toLowerCase().contains('caseblitz') ||
            event.title.toLowerCase().contains('questree') ||
            event.title.toLowerCase().contains('equity auction');
      } else if (selectedCategory == 'Design') {
        matchesCategory = event.category.toLowerCase() == 'design' ||
            event.tags.any((t) => t.toLowerCase() == 'design') ||
            event.organizerClub.toLowerCase().contains('ui/ux') ||
            event.organizerClub.toLowerCase().contains('angd') ||
            event.organizerClub.toLowerCase().contains('animation') ||
            event.title.toLowerCase().contains('pixel perfect') ||
            event.title.toLowerCase().contains('game jam');
      } else if (selectedCategory == 'Coding') {
        matchesCategory = event.category.toLowerCase() == 'coding' ||
            event.tags.any((t) => t.toLowerCase() == 'coding') ||
            event.organizerClub.toLowerCase().contains('cyberlabs') ||
            event.organizerClub.toLowerCase().contains('coding') ||
            event.organizerClub.toLowerCase().contains('c3') ||
            event.title.toLowerCase().contains('hack') ||
            event.title.toLowerCase().contains('code') ||
            event.title.toLowerCase().contains('ctf');
      } else {
        final sel = selectedCategory.toLowerCase();
        matchesCategory = event.category.toLowerCase() == sel ||
            event.tags.any((t) => t.toLowerCase() == sel);
      }

      final matchesSearch = _searchQuery.isEmpty ||
          event.title.toLowerCase().contains(_searchQuery) ||
          event.description.toLowerCase().contains(_searchQuery) ||
          event.venue.toLowerCase().contains(_searchQuery) ||
          event.category.toLowerCase().contains(_searchQuery) ||
          event.organizerClub.toLowerCase().contains(_searchQuery) ||
          event.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));

      return matchesCategory && matchesSearch;
    }).toList();

    // Keep stage / watchable events at the end of the list
    filteredEvents.sort((a, b) {
      final aIsStage = a.isWatchableOnly || a.category.toLowerCase() == 'stage';
      final bIsStage = b.isWatchableOnly || b.category.toLowerCase() == 'stage';
      if (aIsStage && !bIsStage) return 1;
      if (!aIsStage && bIsStage) return -1;
      return 0;
    });

    if (filteredEvents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 56, color: primaryColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No events matching "$_searchQuery"'
                          : 'No events found in $selectedCategory',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try selecting another category or clearing your search.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => _searchController.clear(),
                        child: const Text('CLEAR SEARCH'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 0.50,
      ),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return EventCard(event: event)
            .animate()
            .fadeIn(duration: 250.ms, delay: (index * 40).clamp(0, 400).ms);
      },
    );
  }
}

class EventCard extends StatelessWidget {
  final EventItem event;

  const EventCard({super.key, required this.event});

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('flagship')) return const Color(0xFFFF4500);
    if (cat.contains('coding')) return const Color(0xFF00E5FF);
    if (cat.contains('robotics')) return const Color(0xFFFF9100);
    if (cat.contains('management')) return const Color(0xFF00E676);
    if (cat.contains('electronics')) return const Color(0xFFE040FB);
    if (cat.contains('design')) return const Color(0xFFFFD600);
    if (cat.contains('stage')) return const Color(0xFFFF8A80);
    if (cat.contains('pre')) return const Color(0xFFFF5252);
    if (cat.contains('departmental')) return const Color(0xFF40C4FF);
    if (cat.contains('fun')) return const Color(0xFFFFD54F);
    return const Color(0xFFFF4500);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final catColor = _getCategoryColor(event.category);

    return GestureDetector(
      onTap: () => context.push('/events/detail', extra: event),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF110604),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: catColor.withValues(alpha: 0.4), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: catColor.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster in 2:3 rectangle portrait ratio
            AspectRatio(
              aspectRatio: 2 / 3,
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
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonOrange),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF1A0A08),
                        child: const Icon(Icons.bolt, color: Colors.white24, size: 28),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF110604).withValues(alpha: 0.85),
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
                        color: catColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: catColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
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
                          color: const Color(0xFF0B0403).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events, size: 12, color: Color(0xFFFFA000)),
                            const SizedBox(width: 4),
                            Text(
                              event.prizePool,
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFA000),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.rajdhani(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.organizerClub,
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.cyberAmber,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: event.tags.take(3).map((tag) => Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white12, width: 0.5),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 11, color: primaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.date,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.metallicMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 11, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.venue,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
