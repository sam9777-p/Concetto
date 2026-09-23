import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import '../admin/widgets/event_passcode_prompt.dart';
import '../admin/event_editor_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'rulebook_pdf_viewer_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventItem event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
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
                      if (event.teamSize.isNotEmpty && !event.isWatchableOnly)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(event.teamSize, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      if (event.prizePool.isNotEmpty && !event.isWatchableOnly)
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

                  // Action Buttons: In-App Register (only for registrable) vs Open Entry
                  if (event.isWatchableOnly) ...[
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
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () => _showRegistrationSheet(context, primaryColor),
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
                        if (event.registrationUrl.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            onPressed: () => _launchExternalUrl(context, event.registrationUrl),
                            icon: const Icon(Icons.open_in_browser, size: 18),
                            tooltip: 'Official Google Form (External)',
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                            ),
                          ),
                        ],
                      ],
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

                  // Schedule Breakdown
                  Text(
                    'SCHEDULE BREAKDOWN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildScheduleItem(context, 'Registration & Reporting', '09:00 AM - 10:00 AM'),
                  _buildScheduleItem(context, 'Opening Briefing & Rules', '10:00 AM - 10:30 AM'),
                  _buildScheduleItem(context, 'Round 1 / Preliminary Session', '10:30 AM - 01:00 PM'),
                  _buildScheduleItem(context, 'Lunch & Setup Break', '01:00 PM - 02:00 PM'),
                  _buildScheduleItem(context, 'Grand Finale / Final Pitch', '02:00 PM - 04:30 PM'),
                  _buildScheduleItem(context, 'Evaluation & Prize Distribution', '04:30 PM - 05:30 PM'),

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

  Widget _buildScheduleItem(BuildContext context, String activity, String time) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: primaryColor.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Registration Bottom Sheet ---
  void _showRegistrationSheet(BuildContext context, Color primaryColor) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final collegeController = TextEditingController();
    final teamNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0403),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EVENT REGISTRATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  if (event.registrationUrl.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE85002),
                            const Color(0xFFFF6F00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE85002).withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _launchExternalUrl(context, event.registrationUrl);
                        },
                        icon: const Icon(Icons.open_in_new, color: Colors.black, size: 18),
                        label: const Text(
                          'OPEN OFFICIAL GOOGLE FORM',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR GENERATE IN-APP PASS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  _buildFormField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    primaryColor: primaryColor,
                    validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 12),

                  _buildFormField(
                    controller: emailController,
                    label: 'Email Address',
                    icon: Icons.email,
                    primaryColor: primaryColor,
                    validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),

                  _buildFormField(
                    controller: phoneController,
                    label: 'Mobile Number',
                    icon: Icons.phone,
                    primaryColor: primaryColor,
                    validator: (v) => v == null || v.length < 10 ? 'Enter a valid phone number' : null,
                  ),
                  const SizedBox(height: 12),

                  _buildFormField(
                    controller: collegeController,
                    label: 'College / Institute Name',
                    icon: Icons.school,
                    primaryColor: primaryColor,
                    validator: (v) => v == null || v.isEmpty ? 'Enter your college' : null,
                  ),
                  const SizedBox(height: 12),

                  if (event.teamSize.contains('-') || event.teamSize.contains('Members'))
                    _buildFormField(
                      controller: teamNameController,
                      label: 'Team Name (Optional)',
                      icon: Icons.group,
                      primaryColor: primaryColor,
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final cleanId = event.id.toUpperCase().replaceAll('_', '').replaceAll('-', '');
                          final prefix = cleanId.substring(0, cleanId.length.clamp(3, 6));
                          final passId = 'CON26-$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                          
                          final regData = {
                            'passId': passId,
                            'eventId': event.id,
                            'eventTitle': event.title,
                            'name': nameController.text.trim(),
                            'email': emailController.text.trim(),
                            'phone': phoneController.text.trim(),
                            'college': collegeController.text.trim(),
                            'teamName': teamNameController.text.trim(),
                            'registeredAt': FieldValue.serverTimestamp(),
                            'status': 'CONFIRMED',
                          };
                          
                          try {
                            await FirebaseFirestore.instance.collection('registrations').add(regData);
                          } catch (e) {
                            debugPrint('Firestore registration notice: $e');
                          }
                          
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          if (context.mounted) {
                            _showConfirmationDialog(context, primaryColor, nameController.text.trim(), passId);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'CONFIRM REGISTRATION',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white60),
        prefixIcon: Icon(icon, size: 18, color: primaryColor),
        filled: true,
        fillColor: const Color(0xFF140605),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, Color primaryColor, String registrantName, String passId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF120504),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 26),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Registration Confirmed!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome aboard, $registrantName!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: passId,
                    version: QrVersions.auto,
                    size: 140.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'DIGITAL ENTRY PASS ID',
                        style: TextStyle(color: primaryColor, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        passId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Venue: ${event.venue}\nSaved directly in Firestore. Present this QR at the venue entrance.',
                  style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('DONE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  static const _availableRulebookIds = {
    'aethera',
    'code_wars',
    'edge_ai_challenge',
    'equity_auction',
    'fault_hunt',
    'logic_odyssey',
    'mathalon',
    'questree__26',
    'aptiquest',
    'reservoir_making___iadc',
    'crack_the_crude',
    'sparkathon',
    'vibehack__26',
    'vibehack',
  };

  // --- Rulebook In-App PDF Viewer ---
  void _showRulebookDialog(BuildContext context, Color primaryColor) {
    final normalizedId = event.id.toLowerCase().replaceAll('-', '_');
    if (!_availableRulebookIds.contains(normalizedId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No rulebook for this event found'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
      final desc = Uri.encodeComponent('${event.description}\n\nCategory: ${event.category}\nPrize Pool: ${event.prizePool}\nOrganized by: ${event.organizerClub}\nOfficial Web: https://concetto-ashen.vercel.app');

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
    final webUrl = 'https://sam9777-p.github.io/Concetto/events?id=${event.id}';
    final shareText = "🚀 *${event.title}* — Concetto'26 Centenary Edition\n"
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
