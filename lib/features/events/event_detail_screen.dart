import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import '../admin/widgets/event_passcode_prompt.dart';
import '../admin/event_editor_screen.dart';

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
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.black,
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white54),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Event link for "${event.title}" copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        Text(
                          'ORGANIZED BY ${event.organizerClub.toUpperCase()}',
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.cyberAmber,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      if (event.teamSize.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.groups, size: 16, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(event.teamSize, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      if (event.prizePool.isNotEmpty)
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

                  // Action Buttons: Register Now + Rulebook
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: () => _showRegistrationSheet(context, primaryColor),
                          icon: const Icon(Icons.how_to_reg, color: Colors.black),
                          label: const Text(
                            'REGISTER NOW',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1,
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
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _showRulebookDialog(context, primaryColor),
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: const Text('RULES'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

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
                          IconButton(
                            icon: Icon(Icons.email, color: primaryColor, size: 20),
                            tooltip: 'Contact coordinator',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Contact info: ${event.coordinatorContact}'),
                                ),
                              );
                            },
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${event.title}" saved to your calendar!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
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
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(sheetContext);
                          _showConfirmationDialog(context, primaryColor, nameController.text);
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

  void _showConfirmationDialog(BuildContext context, Color primaryColor, String registrantName) {
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
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
              const SizedBox(width: 10),
              const Text('Registered!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Congratulations, $registrantName!'),
              const SizedBox(height: 8),
              Text(
                'You have successfully registered for "${event.title}".',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Pass ID: CON-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  // --- Rulebook Dialog ---
  void _showRulebookDialog(BuildContext context, Color primaryColor) {
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
              Icon(Icons.gavel, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              const Text('Rules & Guidelines'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Eligibility: All undergraduate, postgraduate, and diploma students with valid college ID are eligible.\n\n'
                  '2. Team Composition: Teams must adhere to the specified member limit. Cross-college teams are permitted.\n\n'
                  '3. Code of Conduct: Any form of plagiarism, malpractice, or unsportsmanlike behavior results in immediate disqualification.\n\n'
                  '4. Evaluation: Decisions made by the official judges and festival committee are final and binding.',
                  style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('CLOSE', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
