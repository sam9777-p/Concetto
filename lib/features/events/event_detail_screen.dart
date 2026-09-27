import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/auth_provider.dart';
import '../../core/network/repositories.dart';
import '../../models/event_item.dart';
import '../admin/widgets/event_passcode_prompt.dart';
import '../admin/event_editor_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'rulebook_pdf_viewer_screen.dart';
import 'team_registration_screen.dart';
import 'team_details_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final EventItem? event;
  final String? eventId;

  const EventDetailScreen({super.key, this.event, this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  /// Cached result of checking if the current user is already registered
  Map<String, dynamic>? _existingTeamData;
  String? _existingTeamDocId;
  bool _isCheckingRegistration = false;
  EventItem? _fetchedEvent;
  bool _isFetchingEvent = false;

  String get eventId => widget.event?.id ?? widget.eventId ?? '';

  EventItem get event {
    // 1. Check live stream from eventsProvider for latest realtime Firestore updates
    final liveList = ref.watch(eventsProvider).asData?.value;
    if (liveList != null && eventId.isNotEmpty) {
      final match = liveList.where((e) => e.id == eventId);
      if (match.isNotEmpty) return match.first;
    }
    // 2. Return direct fetched event if loaded
    if (_fetchedEvent != null) return _fetchedEvent!;
    // 3. Fallback to passed event
    if (widget.event != null) return widget.event!;
    // 4. Default fallback
    return EventItem(
      id: eventId,
      title: 'Event Details',
      category: 'General',
      venue: 'TBD',
      time: 'TBD',
      description: '',
      posterUrl: '',
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.event == null && widget.eventId != null) {
      _loadEventDirectly();
    }
    _checkExistingRegistration();
  }

  Future<void> _loadEventDirectly() async {
    final id = widget.eventId;
    if (id == null || id.isEmpty) return;
    setState(() => _isFetchingEvent = true);
    try {
      final item = await ref.read(firestoreServiceProvider).getEventById(id);
      if (item != null && mounted) {
        setState(() => _fetchedEvent = item);
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetchingEvent = false);
  }

  /// Checks Firestore for an existing registration where the logged-in user
  /// is either the leader or a member
  Future<void> _checkExistingRegistration() async {
    final profile = ref.read(authProvider);
    if (profile.isGuest || profile.email.isEmpty) {
      return;
    }

    setState(() => _isCheckingRegistration = true);

    try {
      final db = FirestoreConfig.instance;
      final userEmail = profile.email.toLowerCase().trim();

      // Query where leaderEmail matches (fast indexed query)
      final leaderQuery = await db
          .collection('events')
          .doc(event.id)
          .collection('registrations')
          .where('leaderEmail', isEqualTo: userEmail)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (leaderQuery.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _existingTeamData = leaderQuery.docs.first.data();
            _existingTeamDocId = leaderQuery.docs.first.id;
            _isCheckingRegistration = false;
          });
        }
        return;
      }

      // Fallback: scan all registrations to check if user is a non-leader member
      final allRegs = await db
          .collection('events')
          .doc(event.id)
          .collection('registrations')
          .get()
          .timeout(const Duration(seconds: 5));

      for (final doc in allRegs.docs) {
        final members = doc.data()['members'] as List<dynamic>? ?? [];
        for (final m in members) {
          if (m is Map &&
              m['email']?.toString().toLowerCase().trim() == userEmail) {
            if (mounted) {
              setState(() {
                _existingTeamData = doc.data();
                _existingTeamDocId = doc.id;
                _isCheckingRegistration = false;
              });
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Registration check notice: $e');
    }

    if (mounted) {
      setState(() {
        _isCheckingRegistration = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingEvent && widget.event == null && _fetchedEvent == null) {
      return const Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.neonOrange),
        ),
      );
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  event.posterUrl.startsWith('assets/')
                      ? Image.asset(
                          event.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.black,
                            child: const Icon(Icons.bolt, size: 50, color: Colors.white24),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: event.posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF140604),
                            child: const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.neonOrange),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.black,
                            child: const Icon(Icons.bolt, size: 50, color: Colors.white24),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.white),
                tooltip: 'Edit Event (Coordinator / Admin)',
                onPressed: () {
                  EventPasscodePrompt.show(
                    context,
                    event: event,
                    actionTitle: 'Edit Event',
                    onAuthorized: (masterPass, secondaryPass, isDevOverride) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventEditorScreen(
                            initialEvent: event,
                            authorizedPasscode: secondaryPass,
                            isMasterAdmin: true,
                            isDeveloperMode: isDevOverride,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Event',
                onPressed: () => _shareEvent(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Category Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Organizing Club Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.cyberAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.cyberAmber, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: AppTheme.cyberAmber),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'ORGANIZED BY ${event.organizerClub.toUpperCase()}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.cyberAmber,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tags Cloud
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: event.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B0907),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.35),
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            '#${tag.toUpperCase()}',
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Metadata Badges Wrap
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(event.date, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(event.venue, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 16, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(event.time, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      if (event.teamSize.isNotEmpty && !event.isWatchableOnly && !event.isStageExperience)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(event.teamSize, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      if (event.prizePool.isNotEmpty &&
                          event.prizePool != '0' &&
                          !event.isWatchableOnly &&
                          !event.isStageExperience &&
                          event.category != 'Workshops')
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Prize: ${event.prizePool}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons: Stage Experience vs Workshop Razorpay vs Standard In-App Register
                  if (event.isWatchableOnly || event.isStageExperience) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.25),
                            const Color(0xFF160A08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stars_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'STAGE EXPERIENCE • OPEN TO ALL • NO REGISTRATION REQUIRED',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (event.category == 'Workshops' || event.registrationUrl.contains('razorpay.com')) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: event.rulebookUrl.isNotEmpty ? 3 : 1,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchExternalUrl(context, event.registrationUrl),
                            icon: const Icon(Icons.payment_rounded, color: Colors.black, size: 18),
                            label: const Text(
                              'ENROLL NOW',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.8,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                          ),
                        ),
                        if (event.rulebookUrl.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _showRulebookDialog(context, primaryColor),
                              icon: const Icon(Icons.school_rounded, size: 16),
                              label: const Text(
                                'CURRICULUM',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[ 
                    // Dynamic In-App Registration
                    if (_isCheckingRegistration)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      )
                    else if (_existingTeamData != null)
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeamDetailsScreen(
                                      event: event,
                                      teamData: _existingTeamData!,
                                      teamDocId: _existingTeamDocId!,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  setState(() {
                                    _existingTeamData = null;
                                    _existingTeamDocId = null;
                                  });
                                  _checkExistingRegistration();
                                }
                              },
                              icon: const Icon(
                                Icons.group,
                                color: Colors.black,
                                size: 18,
                              ),
                              label: Text(
                                event.maxTeamSize <= 1 ? 'VIEW REGISTRATION' : 'CHECK TEAM DETAILS',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0.8,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _showRulebookDialog(context, primaryColor),
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text(
                                'RULES',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final profile = ref.read(authProvider);
                                if (profile.isGuest || !profile.isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in to register for this event.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                // If there's an external Google Form URL, let user choose
                                if (event.registrationUrl.isNotEmpty) {
                                  _showRegistrationChoiceSheet(context, primaryColor);
                                } else {
                                  // No external form — go directly to in-app registration
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TeamRegistrationScreen(event: event),
                                    ),
                                  ).then((_) {
                                    setState(() {
                                      _existingTeamData = null;
                                      _existingTeamDocId = null;
                                    });
                                    _checkExistingRegistration();
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.how_to_reg,
                                color: Colors.black,
                                size: 18,
                              ),
                              label: const Text(
                                'REGISTER NOW',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0.8,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _showRulebookDialog(context, primaryColor),
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text(
                                'RULES',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],

                  // Schedule Breakdown & Timeline
                  if (event.scheduleBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'EVENT SCHEDULE BREAKDOWN & TIMELINE',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF120504),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timeline_rounded, color: primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'OFFICIAL ROUNDS SCHEDULE',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            event.scheduleBreakdown,
                            style: GoogleFonts.rajdhani(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // About Section
                  Text(
                    'ABOUT EVENT',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Colors.white70,
                        ),
                  ),

                  // Coordinator Details
                  if (event.coordinatorName.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'EVENT COORDINATOR',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF100605),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryColor.withValues(alpha: 0.2),
                            child: Icon(Icons.person, color: primaryColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.coordinatorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.coordinatorContact,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (event.coordinatorPhone.isNotEmpty ||
                                  (event.coordinatorContact.isNotEmpty &&
                                      !event.coordinatorContact.contains('@')))
                                IconButton(
                                  icon: Icon(Icons.phone, color: primaryColor, size: 20),
                                  tooltip: 'Call coordinator',
                                  onPressed: () {
                                    final phone = event.coordinatorPhone.isNotEmpty
                                        ? event.coordinatorPhone
                                        : event.coordinatorContact;
                                    _launchPhone(context, phone);
                                  },
                                ),
                              if (event.coordinatorEmail.isNotEmpty ||
                                  event.coordinatorContact.contains('@'))
                                IconButton(
                                  icon: Icon(Icons.email, color: primaryColor, size: 20),
                                  tooltip: 'Email coordinator',
                                  onPressed: () {
                                    final email = event.coordinatorEmail.isNotEmpty
                                        ? event.coordinatorEmail
                                        : (event.coordinatorContact.contains('@')
                                            ? event.coordinatorContact
                                            : 'concetto@iitism.ac.in');
                                    _launchMail(context, email);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Schedule Breakdown (Only displayed if actual stages or breakdown exists)
                  if (event.stages.isNotEmpty) ...[
                    Text(
                      'SCHEDULE BREAKDOWN & ROUNDS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                    ),
                    const SizedBox(height: 14),
                    ...event.stages.map((stage) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF140604),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.timer_outlined, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stage.name,
                                    style: GoogleFonts.orbitron(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (stage.date.isNotEmpty) ...[
                                        Icon(Icons.calendar_today, size: 12, color: primaryColor),
                                        const SizedBox(width: 4),
                                        Text(stage.date, style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 12)),
                                        const SizedBox(width: 10),
                                      ],
                                      if (stage.time.isNotEmpty) ...[
                                        Icon(Icons.access_time, size: 12, color: primaryColor),
                                        const SizedBox(width: 4),
                                        Text(stage.time, style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ],
                                  ),
                                  if (stage.synopsis.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      stage.synopsis,
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 12,
                                        color: Colors.white60,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 32),

                  // Add to Calendar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _addToCalendar(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('ADD TO CALENDAR'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Registration Choice Bottom Sheet ---
  void _showRegistrationChoiceSheet(BuildContext context, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A06),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'CHOOSE REGISTRATION METHOD',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // In-App Registration
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamRegistrationScreen(event: event),
                    ),
                  ).then((_) {
                    setState(() {
                      _existingTeamData = null;
                      _existingTeamDocId = null;
                    });
                    _checkExistingRegistration();
                  });
                },
                icon: const Icon(Icons.app_registration, color: Colors.black, size: 20),
                label: const Text(
                  'REGISTER IN-APP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Official Google Form
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _launchExternalUrl(context, event.registrationUrl);
                },
                icon: Icon(Icons.open_in_browser, color: primaryColor, size: 20),
                label: Text(
                  'OPEN OFFICIAL GOOGLE FORM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // --- Rulebook In-App PDF Viewer ---
  // Opens for ALL events. The viewer screen handles "no URL" gracefully.
  void _showRulebookDialog(BuildContext context, Color primaryColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RulebookPdfViewerScreen(event: event),
      ),
    );
  }

  // --- Real Add to Calendar Intent ---
  Future<void> _addToCalendar(BuildContext context) async {
    try {
      int day = 9;
      if (event.date.contains('Oct 8')) day = 8;
      if (event.date.contains('Oct 9')) day = 9;
      if (event.date.contains('Oct 10')) day = 10;
      if (event.date.contains('Oct 11')) day = 11;
      if (event.date.contains('Oct 12')) day = 12;

      int startHour = 10;
      int startMin = 0;
      int endHour = 13;
      int endMin = 0;

      final timeParts = event.time.split('-');
      if (timeParts.isNotEmpty) {
        final startMatch = RegExp(r'(\d+):?(\d*)\s*(AM|PM)', caseSensitive: false).firstMatch(timeParts[0]);
        if (startMatch != null) {
          int h = int.tryParse(startMatch.group(1) ?? '10') ?? 10;
          int m = int.tryParse(startMatch.group(2) ?? '0') ?? 0;
          final ampm = (startMatch.group(3) ?? 'AM').toUpperCase();
          if (ampm == 'PM' && h < 12) h += 12;
          if (ampm == 'AM' && h == 12) h = 0;
          startHour = h;
          startMin = m;
          endHour = (startHour + 2).clamp(0, 23);
        }
      }
      if (timeParts.length > 1) {
        final endMatch = RegExp(r'(\d+):?(\d*)\s*(AM|PM)', caseSensitive: false).firstMatch(timeParts[1]);
        if (endMatch != null) {
          int h = int.tryParse(endMatch.group(1) ?? '13') ?? 13;
          int m = int.tryParse(endMatch.group(2) ?? '0') ?? 0;
          final ampm = (endMatch.group(3) ?? 'PM').toUpperCase();
          if (ampm == 'PM' && h < 12) h += 12;
          if (ampm == 'AM' && h == 12) h = 0;
          endHour = h;
          endMin = m;
        }
      }

      final startLocal = DateTime(2026, 10, day, startHour, startMin);
      final endLocal = DateTime(2026, 10, day, endHour, endMin);
      final startUtc = startLocal.subtract(const Duration(hours: 5, minutes: 30));
      final endUtc = endLocal.subtract(const Duration(hours: 5, minutes: 30));

      String formatUtc(DateTime dt) {
        return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}T${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}00Z';
      }

      final startStr = formatUtc(startUtc);
      final endStr = formatUtc(endUtc);

      final title = Uri.encodeComponent('CONCETTO: ${event.title}');
      final venue = Uri.encodeComponent(event.venue.isNotEmpty ? '${event.venue}, IIT (ISM) Dhanbad' : 'IIT (ISM) Dhanbad');
      final desc = Uri.encodeComponent('${event.description}\n\nCategory: ${event.category}\nPrize Pool: ${event.prizePool}\nOrganized by: ${event.organizerClub}\nOfficial Web: https://www.concetto.in');

      final intentUri = Uri.parse('https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$startStr/$endStr&details=$desc&location=$venue');

      final launched = await launchUrl(intentUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(intentUri, mode: LaunchMode.platformDefault);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening Calendar for "${event.title}"...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open calendar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- Helper to open external registration links / rulebooks ---
  Future<void> _launchExternalUrl(BuildContext context, String urlString) async {
    if (urlString.trim().isEmpty) return;
    try {
      final uri = Uri.parse(urlString.trim());
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open external link: $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- Deep Link Share via Share Plus ---
  Future<void> _shareEvent(BuildContext context) async {
  final webUrl = 'https://concetto.in/redirect.html?id=${event.id}';
  final shareText =
      "🚀 *${event.title}* — Concetto'26 Centenary Edition\n"
      "IIT (ISM) Dhanbad\n\n"
      "📅 Date: ${event.date}\n"
      "📍 Venue: ${event.venue}\n"
      "${event.prizePool.isNotEmpty ? '🏆 Prize Pool: ${event.prizePool}\n' : ''}"
      "👥 Team: ${event.teamSize}\n\n"
      "Open in Concetto'26 App:\n$webUrl";

    Rect? sharePositionOrigin;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
      }
    } catch (_) {}

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: "Concetto'26 — ${event.title}",
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not trigger share intent: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- Intent: Open System Phone Dialer ---
  Future<void> _launchPhone(BuildContext context, String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone dialer: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- Intent: Open System Email Client ---
  Future<void> _launchMail(BuildContext context, String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: cleanEmail,
      queryParameters: {
        'subject': "Query regarding Concetto'26 - ${event.title}",
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch mail client: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
