import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import '../../services/notification_service.dart';

class NotificationSenderScreen extends ConsumerStatefulWidget {
  const NotificationSenderScreen({super.key});

  @override
  ConsumerState<NotificationSenderScreen> createState() => _NotificationSenderScreenState();
}

class _NotificationSenderScreenState extends ConsumerState<NotificationSenderScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _contentUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String _selectedCategory = 'Fest Highlights';
  String _selectedRouteType = '/events';
  String? _selectedEventId;
  bool _keepInAnnouncementFeed = true;
  bool _isPublishing = false;
  late final TabController _tabController;

  final List<String> _standardCategories = [
    'Fest Highlights',
    'Schedule',
    'Hackathon',
    'Workshops',
    'Cultural',
    'Guest Lectures',
    'Competitions',
    'Important Alert',
    'Custom Category',
  ];

  final List<Map<String, String>> _routeOptions = [
    {'label': 'Nowhere (Notification Info Only)', 'value': 'none'},
    {'label': 'Exact Event / Hackathon', 'value': 'exact_event'},
    {'label': 'Schedule Matrix', 'value': '/schedule'},
    {'label': 'Events Directory', 'value': '/events'},
    {'label': 'Home Screen', 'value': '/'},
    {'label': 'Merch Store', 'value': '/store'},
    {'label': 'About Concetto & Heritage', 'value': '/profile'},
    {'label': 'External Website Link', 'value': 'external'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _contentUrlController.dispose();
    _imageUrlController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  bool get _isCustomCategory => _selectedCategory == 'Custom Category';

  String get _effectiveCategory {
    if (_isCustomCategory) {
      final custom = _customCategoryController.text.trim();
      return custom.isNotEmpty ? custom : 'Announcement';
    }
    return _selectedCategory;
  }

  EventItem? _getSelectedEvent(List<EventItem>? events) {
    if (events == null || events.isEmpty) return null;
    if (_selectedEventId == null || _selectedEventId!.isEmpty) {
      return events.first;
    }
    return events.firstWhere(
      (e) => e.id == _selectedEventId,
      orElse: () => events.first,
    );
  }

  Widget _buildImagePreview(String url, {double height = 110, double? width, BoxFit fit = BoxFit.cover}) {
    if (url.trim().isEmpty) return const SizedBox.shrink();
    final clean = url.trim();
    if (clean.startsWith('assets/')) {
      return Image.asset(
        clean,
        height: height,
        width: width ?? double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Colors.red.withValues(alpha: 0.1),
          alignment: Alignment.center,
          child: const Text('Asset image not found', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
        ),
      );
    }
    return Image.network(
      clean,
      height: height,
      width: width ?? double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        height: height,
        color: Colors.red.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: const Text('Invalid image link', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
      ),
    );
  }

  String get _computedTargetRoute {
    if (_selectedRouteType == 'none') {
      return '';
    }
    if (_selectedRouteType == 'exact_event') {
      if (_selectedEventId != null && _selectedEventId!.isNotEmpty) {
        return '/events/$_selectedEventId';
      }
      return '/events';
    }
    if (_selectedRouteType == 'external') {
      return '';
    }
    return _selectedRouteType;
  }

  String get _computedContentUrl {
    if (_selectedRouteType == 'external') {
      return _contentUrlController.text.trim();
    }
    return '';
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    final events = ref.read(eventsProvider).asData?.value;
    final selectedEvent = _getSelectedEvent(events);

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    String imageUrl = _imageUrlController.text.trim();
    if (_selectedRouteType == 'exact_event' && selectedEvent != null && selectedEvent.posterUrl.isNotEmpty) {
      imageUrl = selectedEvent.posterUrl.trim();
    }
    final contentUrl = _computedContentUrl;
    final category = _effectiveCategory;
    final targetRoute = _computedTargetRoute;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF140706),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Color(0xFF00E5FF), size: 24),
            const SizedBox(width: 10),
            Text(
              'CONFIRM BROADCAST',
              style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publish this broadcast notification to all festival attendees?',
              style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E0A08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: GoogleFonts.rajdhani(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF)),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _keepInAnnouncementFeed ? 'Feed: SAVED' : 'Feed: ONE-TIME ONLY',
                        style: GoogleFonts.rajdhani(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _keepInAnnouncementFeed ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  if (imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImagePreview(imageUrl, height: 80),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (targetRoute.isNotEmpty)
                    Text('🎯 Target Destination: $targetRoute', style: GoogleFonts.rajdhani(fontSize: 11, color: const Color(0xFF00E5FF)))
                  else if (contentUrl.isNotEmpty)
                    Text('🌐 External Link: $contentUrl', style: GoogleFonts.rajdhani(fontSize: 11, color: const Color(0xFF00E5FF)))
                  else
                    Text('ℹ️ Tap Action: Shows Notification Info', style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('PUBLISH TO ALL', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isPublishing = true);

    final res = await NotificationService.publishBroadcast(
      title: title,
      body: body,
      imageUrl: imageUrl,
      route: targetRoute,
      contentUrl: contentUrl,
      category: category,
      keepInAnnouncementFeed: _keepInAnnouncementFeed,
    );

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (res.success) {
      _titleController.clear();
      _bodyController.clear();
      _contentUrlController.clear();
      _imageUrlController.clear();
      _customCategoryController.clear();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF140706),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: res.fcmSent ? const Color(0xFF00E676) : const Color(0xFFFFB300),
              width: 1.2,
            ),
          ),
          title: Row(
            children: [
              Icon(
                res.fcmSent ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: res.fcmSent ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  res.fcmSent ? 'BROADCAST DISPATCHED!' : 'SAVED — FCM ISSUE',
                  style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (res.fcmSent) ...[
                Text(
                  _keepInAnnouncementFeed
                      ? 'Push notification sent to ALL attendee devices and saved to Announcement Feed!'
                      : 'One-time push notification sent to ALL attendee devices (not saved in feed).',
                  style: GoogleFonts.rajdhani(fontSize: 13.5, color: Colors.white70),
                ),
              ] else ...[
                Text(
                  'Announcement was saved to Firestore but the FCM push notification could not be delivered.',
                  style: GoogleFonts.rajdhani(fontSize: 13.5, color: Colors.white70),
                ),
                if (res.error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E0A08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Error: ${res.error}',
                      style: GoogleFonts.rajdhani(fontSize: 11.5, color: const Color(0xFFFFB300)),
                    ),
                  ),
                ],
              ],
              if (res.broadcastId != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Broadcast ID: ${res.broadcastId}',
                  style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white38),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: res.fcmSent ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('DONE', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF140706),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE50914), width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_rounded, color: Color(0xFFE50914), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'BROADCAST FAILED',
                  style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Failed to publish broadcast notification.',
                style: GoogleFonts.rajdhani(fontSize: 13.5, color: Colors.white70),
              ),
              if (res.error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E0A08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    res.error!,
                    style: GoogleFonts.rajdhani(fontSize: 11.5, color: const Color(0xFFE50914)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('CLOSE', style: GoogleFonts.rajdhani(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF00E5FF);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'BROADCAST NOTIFICATIONS',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accentColor, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: accentColor, size: 13),
                const SizedBox(width: 4),
                Text(
                  'PROMO AUTH',
                  style: GoogleFonts.rajdhani(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.orbitron(fontSize: 11.5, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.campaign, size: 20), text: 'COMPOSE'),
            Tab(icon: Icon(Icons.history, size: 20), text: 'HISTORY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposeTab(eventsAsync, accentColor),
          _buildHistoryTab(accentColor),
        ],
      ),
    );
  }

  Widget _buildComposeTab(AsyncValue<List<EventItem>> eventsAsync, Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Info Banner
            _buildStatusHeader(accentColor),
            const SizedBox(height: 18),

            // 1. Category Selection
            Text(
              '1. ANNOUNCEMENT CATEGORY',
              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF140706),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF180A09),
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF00E5FF)),
                  items: _standardCategories.map((c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        style: GoogleFonts.rajdhani(
                          color: c == 'Custom Category' ? const Color(0xFFFFB300) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
              ),
            ),

            // Custom Category Input (Max 20 characters)
            if (_isCustomCategory) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _customCategoryController,
                maxLength: 20,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Custom Category Name * (Max 20 chars)',
                  labelStyle: GoogleFonts.rajdhani(color: const Color(0xFFFFB300)),
                  hintText: 'e.g. RoboWars, E-Sports, Quiz',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  counterStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                  prefixIcon: const Icon(Icons.edit_note, color: Color(0xFFFFB300)),
                  filled: true,
                  fillColor: const Color(0xFF140706),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFFFB300), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (!_isCustomCategory) return null;
                  if (val == null || val.trim().isEmpty) return 'Please specify custom category';
                  if (val.trim().length > 20) return 'Maximum 20 characters allowed';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 18),

            // 2. Title & Message
            Text(
              '2. NOTIFICATION CONTENT',
              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              maxLength: 65,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Notification Headline / Title *',
                labelStyle: GoogleFonts.rajdhani(color: Colors.white70),
                hintText: 'e.g. Sparkathon Round 1 Commences at SAC!',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.title, color: Color(0xFF00E5FF)),
                filled: true,
                fillColor: const Color(0xFF140706),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Headline is required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              maxLines: 3,
              maxLength: 250,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Notification Message / Body *',
                labelStyle: GoogleFonts.rajdhani(color: Colors.white70),
                hintText: 'Provide concise, essential details for attendees...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.message, color: Color(0xFF00E5FF)),
                filled: true,
                fillColor: const Color(0xFF140706),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Message body is required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),

            // 3. Notification Image
            Text(
              '3. NOTIFICATION BANNER IMAGE (OPTIONAL)',
              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            if (_selectedRouteType == 'exact_event') ...[
              Builder(
                builder: (context) {
                  final events = eventsAsync.asData?.value;
                  final ev = _getSelectedEvent(events);
                  final poster = ev?.posterUrl.trim() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        if (poster.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildImagePreview(poster, height: 44, width: 44, fit: BoxFit.cover),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LINKED TO EVENT POSTER',
                                style: GoogleFonts.orbitron(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00E5FF),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ev != null ? ev.title : 'Selected Event',
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Event picture is automatically locked as the notification banner.',
                                style: GoogleFonts.rajdhani(
                                  color: Colors.white54,
                                  fontSize: 11,
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
            ],
            TextFormField(
              controller: _imageUrlController,
              readOnly: _selectedRouteType == 'exact_event',
              style: TextStyle(
                color: _selectedRouteType == 'exact_event' ? Colors.white60 : Colors.white,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                labelText: _selectedRouteType == 'exact_event'
                    ? 'Banner Image (Auto-linked to Event Poster)'
                    : 'Banner Image URL (HTTPS link)',
                labelStyle: GoogleFonts.rajdhani(
                  color: _selectedRouteType == 'exact_event' ? const Color(0xFF00E5FF) : Colors.white70,
                ),
                hintText: 'https://images.unsplash.com/...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12.5),
                prefixIcon: Icon(
                  _selectedRouteType == 'exact_event' ? Icons.lock : Icons.image,
                  color: const Color(0xFF00E5FF),
                ),
                filled: true,
                fillColor: const Color(0xFF140706),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_selectedRouteType != 'exact_event') ...[
              const SizedBox(height: 8),
              _buildPresetBanners(),
            ],
            if (_imageUrlController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImagePreview(_imageUrlController.text.trim(), height: 110),
              ),
            ],
            const SizedBox(height: 18),

            // 4. Destination Selector ("Portion of app to open when clicked")
            Text(
              '4. APP PORTION TO OPEN ON TAP',
              style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF140706),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRouteType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF180A09),
                  icon: const Icon(Icons.navigation, color: Color(0xFF00E5FF)),
                  items: _routeOptions.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt['value'],
                      child: Text(
                        opt['label']!,
                        style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRouteType = val;
                        if (val == 'exact_event') {
                          final events = eventsAsync.asData?.value;
                          if (events != null && events.isNotEmpty) {
                            _selectedEventId ??= events.first.id;
                            final ev = _getSelectedEvent(events);
                            if (ev != null && ev.posterUrl.isNotEmpty) {
                              _imageUrlController.text = ev.posterUrl;
                            }
                          }
                        }
                      });
                    }
                  },
                ),
              ),
            ),

            // Sub-selector if "Exact Event / Hackathon" is chosen
            if (_selectedRouteType == 'exact_event') ...[
              const SizedBox(height: 12),
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return const Text('No events found in database.', style: TextStyle(color: Colors.white54, fontSize: 12));
                  }
                  final currentEventId = _selectedEventId ?? events.first.id;
                  if (_selectedEventId == null || _imageUrlController.text.trim().isEmpty) {
                    final ev = events.firstWhere((e) => e.id == currentEventId, orElse: () => events.first);
                    if (ev.posterUrl.isNotEmpty && _imageUrlController.text.trim() != ev.posterUrl) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedRouteType == 'exact_event') {
                          setState(() {
                            _selectedEventId = currentEventId;
                            _imageUrlController.text = ev.posterUrl;
                          });
                        }
                      });
                    }
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B0C0B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentEventId,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF180A09),
                        hint: const Text('Choose Exact Event / Hackathon *', style: TextStyle(color: Colors.white70)),
                        items: events.map<DropdownMenuItem<String>>((e) {
                          final club = e.organizerClub;
                          return DropdownMenuItem<String>(
                            value: e.id,
                            child: Text(
                              '${e.title}${club.isNotEmpty ? ' ($club)' : ''}',
                              style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedEventId = val;
                            if (val != null) {
                              final ev = events.firstWhere((e) => e.id == val, orElse: () => events.first);
                              if (ev.posterUrl.isNotEmpty) {
                                _imageUrlController.text = ev.posterUrl;
                              }
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(color: Color(0xFF00E5FF)),
                error: (e, _) => Text('Could not load events: $e', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ],

            // ONLY shown if "External Website Link" is chosen
            if (_selectedRouteType == 'external') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentUrlController,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'External Website URL *',
                  labelStyle: GoogleFonts.rajdhani(color: const Color(0xFF00E5FF)),
                  hintText: 'https://example.com/form or https://drive.google.com/...',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 12.5),
                  prefixIcon: const Icon(Icons.language, color: Color(0xFF00E5FF)),
                  filled: true,
                  fillColor: const Color(0xFF140706),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (_selectedRouteType != 'external') return null;
                  if (val == null || val.trim().isEmpty) return 'Please specify external website URL';
                  if (!val.trim().startsWith('http://') && !val.trim().startsWith('https://')) {
                    return 'Must start with https:// or http://';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 20),

            // 5. Feed Persistence Checkbox
            _buildFeedPersistenceCard(accentColor),
            const SizedBox(height: 22),

            // 6. Live Phone Simulation
            _buildLivePhonePreview(accentColor),
            const SizedBox(height: 26),

            // 7. Instant Publish Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  shadowColor: accentColor.withValues(alpha: 0.5),
                ),
                onPressed: _isPublishing ? null : _handlePublish,
                icon: _isPublishing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.send_rounded, size: 22),
                label: Text(
                  _isPublishing ? 'PUBLISHING BROADCAST...' : 'PUBLISH TO ALL APP USERS',
                  style: GoogleFonts.orbitron(fontSize: 13.5, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF120504),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.cell_tower, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONCETTO BROADCAST NETWORK',
                  style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Instant push notification delivery to all Android & iOS devices',
                  style: GoogleFonts.rajdhani(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedPersistenceCard(Color accentColor) {
    return InkWell(
      onTap: () {
        setState(() {
          _keepInAnnouncementFeed = !_keepInAnnouncementFeed;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _keepInAnnouncementFeed ? const Color(0xFF140706) : const Color(0xFF110706),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _keepInAnnouncementFeed ? accentColor.withValues(alpha: 0.8) : Colors.white24,
            width: _keepInAnnouncementFeed ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _keepInAnnouncementFeed,
              activeColor: accentColor,
              checkColor: Colors.black,
              onChanged: (val) {
                if (val != null) setState(() => _keepInAnnouncementFeed = val);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save in Announcement Feed',
                    style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _keepInAnnouncementFeed
                        ? 'TICKED: Notification is dispatched to all devices AND saved in the in-app Announcement Feed.'
                        : 'UNTICKED: One-time push notification only (will NOT be stored in the Announcement Feed).',
                    style: TextStyle(
                      fontSize: 12,
                      color: _keepInAnnouncementFeed ? const Color(0xFF00E676) : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetBanners() {
    final presets = [
      {'name': 'Hackathon', 'url': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800'},
      {'name': 'Star Night', 'url': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800'},
      {'name': 'RoboWars', 'url': 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800'},
      {'name': 'Workshop', 'url': 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800'},
    ];

    return Wrap(
      spacing: 6,
      children: presets.map((p) {
        return ActionChip(
          backgroundColor: const Color(0xFF1E0A08),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 0.5),
          label: Text(p['name']!, style: GoogleFonts.rajdhani(color: const Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
          onPressed: () {
            setState(() {
              _imageUrlController.text = p['url']!;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLivePhonePreview(Color accentColor) {
    final events = ref.watch(eventsProvider).asData?.value;
    final selectedEvent = _getSelectedEvent(events);

    final title = _titleController.text.trim().isEmpty ? 'Concetto \'26 Official Announcement' : _titleController.text.trim();
    final body = _bodyController.text.trim().isEmpty ? 'Tap to view new festival announcements and competition schedules.' : _bodyController.text.trim();
    final img = (_selectedRouteType == 'exact_event' && selectedEvent != null && selectedEvent.posterUrl.isNotEmpty)
        ? selectedEvent.posterUrl.trim()
        : _imageUrlController.text.trim();
    final category = _effectiveCategory;
    final dest = _selectedRouteType == 'none'
        ? 'Tap: Shows Details'
        : _selectedRouteType == 'exact_event'
            ? 'Tap: ${selectedEvent != null ? selectedEvent.title : 'Exact Event'}'
            : _selectedRouteType == 'external'
                ? 'Tap: Open External Link'
                : 'Tap: $_selectedRouteType';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.phone_android, size: 16, color: Color(0xFF00E5FF)),
            const SizedBox(width: 6),
            Text(
              'LIVE PHONE LOCKSCREEN SIMULATION',
              style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0403),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Center(
                      child: Text('C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CONCETTO \'26 • $category',
                    style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const Spacer(),
                  Text('now', style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white38)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              if (img.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImagePreview(img, height: 90),
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dest,
                  style: GoogleFonts.rajdhani(fontSize: 10.5, fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(Color accentColor) {
    return _BroadcastHistoryView(accentColor: accentColor);
  }
}

class _BroadcastHistoryView extends StatefulWidget {
  final Color accentColor;
  const _BroadcastHistoryView({required this.accentColor});

  @override
  State<_BroadcastHistoryView> createState() => _BroadcastHistoryViewState();
}

class _BroadcastHistoryViewState extends State<_BroadcastHistoryView> {
  StreamSubscription? _sub1;
  StreamSubscription? _sub2;
  final Map<String, Map<String, dynamic>> _broadcastMap = {};
  final Map<String, Map<String, dynamic>> _announcementsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final db = FirestoreConfig.instance;

    _sub1 = db.collection('broadcast_notifications').snapshots().listen((snap) {
      _broadcastMap.clear();
      for (final doc in snap.docs) {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = doc.id;
        m['sourceCollection'] = 'broadcast_notifications';
        _broadcastMap[doc.id] = m;
      }
      if (mounted) setState(() => _isLoading = false);
    }, onError: (e) {
      debugPrint('broadcast_notifications error: $e');
      if (mounted) setState(() => _isLoading = false);
    });

    _sub2 = db.collection('announcements').snapshots().listen((snap) {
      _announcementsMap.clear();
      for (final doc in snap.docs) {
        final m = Map<String, dynamic>.from(doc.data());
        m['id'] = doc.id;
        m['sourceCollection'] = 'announcements';
        _announcementsMap[doc.id] = m;
      }
      if (mounted) setState(() => _isLoading = false);
    }, onError: (e) {
      debugPrint('announcements error: $e');
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    super.dispose();
  }

  DateTime _parseDate(Map<String, dynamic> data) {
    final raw = data['timestamp'] ?? data['sentAt'] ?? data['createdAt'];
    if (raw != null) {
      try {
        return (raw as dynamic).toDate();
      } catch (_) {
        if (raw is String) {
          final d = DateTime.tryParse(raw);
          if (d != null) return d;
        } else if (raw is int) {
          return DateTime.fromMillisecondsSinceEpoch(raw);
        }
      }
    }
    final iso = data['publishedAtIso'];
    if (iso is String) {
      final d = DateTime.tryParse(iso);
      if (d != null) return d;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Color _getCategoryColor(String tag) {
    final upper = tag.toUpperCase();
    if (upper.contains('URGENT') || upper.contains('ALERT')) return const Color(0xFFFF5252);
    if (upper.contains('HACKATHON')) return const Color(0xFF00E5FF);
    if (upper.contains('SCHEDULE')) return const Color(0xFFFFB300);
    if (upper.contains('WORKSHOP')) return const Color(0xFF69F0AE);
    if (upper.contains('CULTURAL') || upper.contains('MUSIC')) return const Color(0xFFE040FB);
    if (upper.contains('FLAGSHIP') || upper.contains('HIGHLIGHTS')) return const Color(0xFFFF6D00);
    if (upper.contains('CDC') || upper.contains('TALKS')) return const Color(0xFF7C4DFF);
    return widget.accentColor;
  }

  Future<void> _deleteBroadcast(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF140706),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Color(0xFFFF5252), size: 24),
            const SizedBox(width: 8),
            Text(
              'DELETE BROADCAST',
              style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$title"? This removes it from both Broadcast History and the App Feed.',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = FirestoreConfig.instance;
    try {
      await db.collection('broadcast_notifications').doc(id).delete();
    } catch (_) {}
    try {
      await db.collection('announcements').doc(id).delete();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "$title"', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF140706),
        ),
      );
    }
  }

  void _showDetailDialog(Map<String, dynamic> data, DateTime dt, Color tagColor) {
    final title = data['title'] as String? ?? 'Untitled';
    final body = data['body'] as String? ?? data['description'] as String? ?? '';
    final category = data['tag'] as String? ?? data['category'] as String? ?? 'GENERAL';
    final route = data['route'] as String? ?? data['targetRoute'] as String? ?? '';
    final contentUrl = data['contentUrl'] as String? ?? data['externalUrl'] as String? ?? data['actionUrl'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final id = data['id'] as String? ?? '';
    final hasRoute = route.trim().isNotEmpty && route.trim() != 'none';
    final hasLink = contentUrl.trim().isNotEmpty;
    final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(dt);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF140706),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tagColor.withValues(alpha: 0.5)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: tagColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.bold, color: tagColor),
                    ),
                  ),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
              const SizedBox(height: 14),
              if (imageUrl.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl.trim(),
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.45),
              ),
              if (hasRoute || hasLink) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(hasLink ? Icons.open_in_new : Icons.navigation, size: 14, color: const Color(0xFF00E5FF)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hasLink ? 'External Link: $contentUrl' : 'In-App Route: $route',
                          style: GoogleFonts.rajdhani(fontSize: 12, color: const Color(0xFF00E5FF)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5252)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteBroadcast(id, title);
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('DELETE'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('CLOSE', style: TextStyle(color: Colors.white60)),
                      ),
                      if (hasLink) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE50914),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            final uri = Uri.tryParse(contentUrl.trim());
                            if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: Text('OPEN LINK', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ] else if (hasRoute) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go(route.trim());
                          },
                          icon: const Icon(Icons.arrow_forward, size: 14),
                          label: Text('TEST NAVIGATE', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
    }

    final merged = <String, Map<String, dynamic>>{};
    for (final entry in _announcementsMap.entries) {
      merged[entry.key] = Map<String, dynamic>.from(entry.value);
    }
    for (final entry in _broadcastMap.entries) {
      if (merged.containsKey(entry.key)) {
        merged[entry.key]!.addAll(entry.value);
      } else {
        merged[entry.key] = Map<String, dynamic>.from(entry.value);
      }
    }

    final items = merged.values.toList();
    items.sort((a, b) {
      final dtA = _parseDate(a);
      final dtB = _parseDate(b);
      return dtB.compareTo(dtA);
    });

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 52, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 14),
            Text('No broadcasts or announcements found', style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = items[index];
        final id = data['id'] as String? ?? '';
        final title = data['title'] as String? ?? 'Untitled';
        final body = data['body'] as String? ?? data['description'] as String? ?? '';
        final category = data['tag'] as String? ?? data['category'] as String? ?? 'General';
        final route = data['route'] as String? ?? data['targetRoute'] as String? ?? '';
        final contentUrl = data['contentUrl'] as String? ?? data['externalUrl'] as String? ?? data['actionUrl'] as String? ?? '';
        final imageUrl = data['imageUrl'] as String? ?? '';
        final keepInFeed = data['keepInFeed'] as bool? ?? data['isPublished'] as bool? ?? true;
        final fcmDispatched = data['fcmDispatched'] as bool? ?? false;
        final dt = _parseDate(data);
        final dateStr = DateFormat('MMM d, h:mm a').format(dt);
        final tagColor = _getCategoryColor(category);
        final isLatest = index == 0;
        final hasRoute = route.trim().isNotEmpty && route.trim() != 'none';
        final hasLink = contentUrl.trim().isNotEmpty;
        final hasImage = imageUrl.trim().isNotEmpty;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetailDialog(data, dt, tagColor),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF140706),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isLatest ? const Color(0xFF00E5FF).withValues(alpha: 0.6) : tagColor.withValues(alpha: 0.3),
                width: isLatest ? 1.2 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLatest ? const Color(0xFF00E5FF).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.3),
                  blurRadius: isLatest ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: tagColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: tagColor,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE50914), Color(0xFFFF5252)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LATEST',
                          style: GoogleFonts.orbitron(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: keepInFeed ? const Color(0xFF00E676).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        keepInFeed ? 'FEED STORED' : 'ONE-TIME',
                        style: GoogleFonts.rajdhani(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: keepInFeed ? const Color(0xFF00E676) : Colors.orange,
                        ),
                      ),
                    ),
                    if (fcmDispatched) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PUSH SENT',
                          style: GoogleFonts.rajdhani(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF)),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      dateStr,
                      style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.35),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl.trim(),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (hasRoute || hasLink) ...[
                      Icon(
                        hasLink ? Icons.open_in_new : Icons.arrow_forward_rounded,
                        size: 13,
                        color: const Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hasLink ? 'Link: $contentUrl' : 'Destination: $route',
                          style: GoogleFonts.rajdhani(fontSize: 11.5, color: const Color(0xFF00E5FF)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    InkWell(
                      onTap: () => _deleteBroadcast(id, title),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline, size: 18, color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
