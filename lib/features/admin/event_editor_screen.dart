import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/notification_service.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';
import 'widgets/cloudinary_upload_widget.dart';
import 'widgets/passcode_receipt_dialog.dart';

class EventEditorScreen extends ConsumerStatefulWidget {
  final EventItem? initialEvent;
  final String? authorizedPasscode;
  final bool isMasterAdmin;

  const EventEditorScreen({
    super.key,
    this.initialEvent,
    this.authorizedPasscode,
    this.isMasterAdmin = false,
  });

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _customClubController;
  late TextEditingController _venueController;
  late TextEditingController _timeController;
  late TextEditingController _dateController;
  late TextEditingController _prizePoolController;
  late TextEditingController _teamSizeController;
  late TextEditingController _descriptionController;
  late TextEditingController _rulebookUrlController;
  late TextEditingController _registrationUrlController;
  late TextEditingController _coordinatorNameController;
  late TextEditingController _coordinatorEmailController;
  late TextEditingController _coordinatorPhoneController;
  late TextEditingController _passcodeController;

  late String _posterUrl;
  late String _selectedCategory;
  late String _selectedClub;
  late bool _isFlagship;
  bool _obscurePasscode = true;
  bool _isSaving = false;

  final List<String> _popularClubs = [
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
    'Custom / Other',
  ];

  final List<String> _categories = [
    'Flagship',
    'Robotics',
    'Coding',
    'Electronics',
    'Management',
    'Design',
    'Aeromodelling',
    'Open / Gaming',
  ];

  final List<String> _venueSuggestions = [
    'Central Arena (SAC Ground)',
    'NLHC Hall 1',
    'NLHC Hall 2',
    'NVCTI Incubation Center',
    'Computer Center Lab 2',
    'Management Studies Hall',
    'CAD Center',
    'Golden Jubilee Lecture Hall',
  ];

  bool get _isEditing => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initialEvent;

    _titleController = TextEditingController(text: e?.title ?? '');
    _selectedClub = (e != null && _popularClubs.contains(e.organizerClub))
        ? e.organizerClub
        : (e != null ? 'Custom / Other' : 'RoboISM');
    _customClubController = TextEditingController(
      text: (_selectedClub == 'Custom / Other' && e != null) ? e.organizerClub : '',
    );
    _selectedCategory = e?.category ?? 'Robotics';
    _isFlagship = e?.isFlagship ?? false;

    _posterUrl = e?.posterUrl ??
        'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800&q=80';
    _dateController = TextEditingController(text: e?.date ?? 'Oct 11, 2026');
    _timeController = TextEditingController(text: e?.time ?? '02:00 PM - 06:00 PM');
    _venueController = TextEditingController(text: e?.venue ?? 'Central Arena (SAC Ground)');
    _prizePoolController = TextEditingController(text: e?.prizePool ?? '₹ 30,000');
    _teamSizeController = TextEditingController(text: e?.teamSize ?? '1 - 4 Members');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _rulebookUrlController = TextEditingController(text: e?.rulebookUrl ?? '');
    _registrationUrlController = TextEditingController(text: e?.registrationUrl ?? '');
    _coordinatorNameController = TextEditingController(text: e?.coordinatorName ?? '');
    _coordinatorEmailController = TextEditingController(text: e?.coordinatorEmail ?? '');
    _coordinatorPhoneController = TextEditingController(
      text: e?.coordinatorPhone.isNotEmpty == true ? e!.coordinatorPhone : (e?.coordinatorContact ?? ''),
    );
    _passcodeController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customClubController.dispose();
    _venueController.dispose();
    _timeController.dispose();
    _dateController.dispose();
    _prizePoolController.dispose();
    _teamSizeController.dispose();
    _descriptionController.dispose();
    _rulebookUrlController.dispose();
    _registrationUrlController.dispose();
    _coordinatorNameController.dispose();
    _coordinatorEmailController.dispose();
    _coordinatorPhoneController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawPasscode = _passcodeController.text.trim();
    if (!_isEditing && rawPasscode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set an event passcode for this new event!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final finalClub = _selectedClub == 'Custom / Other'
        ? (_customClubController.text.trim().isNotEmpty
            ? _customClubController.text.trim()
            : 'Concetto Society')
        : _selectedClub;

    final eventItem = EventItem(
      id: widget.initialEvent?.id ?? '',
      title: _titleController.text.trim(),
      organizerClub: finalClub,
      category: _selectedCategory,
      venue: _venueController.text.trim(),
      time: _timeController.text.trim(),
      date: _dateController.text.trim(),
      prizePool: _prizePoolController.text.trim(),
      teamSize: _teamSizeController.text.trim(),
      description: _descriptionController.text.trim(),
      posterUrl: _posterUrl.trim(),
      rulebookUrl: _rulebookUrlController.text.trim(),
      registrationUrl: _registrationUrlController.text.trim(),
      coordinatorName: _coordinatorNameController.text.trim(),
      coordinatorEmail: _coordinatorEmailController.text.trim(),
      coordinatorPhone: _coordinatorPhoneController.text.trim(),
      isFlagship: _isFlagship,
      passwordHash: widget.initialEvent?.passwordHash ?? '',
    );

    setState(() => _isSaving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      if (_isEditing) {
        // Update existing event
        final passcodeToUse = rawPasscode.isNotEmpty
            ? rawPasscode
            : (widget.authorizedPasscode ?? '');

        await firestoreService.updateEvent(
          eventItem,
          passcodeToUse,
          isMasterAdmin: widget.isMasterAdmin,
        );

        ref.invalidate(eventsProvider);
        setState(() => _isSaving = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${eventItem.title}" updated successfully!'),
              backgroundColor: AppTheme.neonEmerald,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Create new event
        final createdEvent = await firestoreService.createEvent(eventItem, rawPasscode);
        ref.invalidate(eventsProvider);

        // Dispatch email notification
        bool emailSent = false;
        if (eventItem.coordinatorEmail.isNotEmpty) {
          emailSent = await NotificationService.sendPasscodeNotification(
            event: createdEvent,
            rawPasscode: rawPasscode,
            recipientEmail: eventItem.coordinatorEmail,
            recipientPhone: eventItem.coordinatorPhone,
          );
        }

        setState(() => _isSaving = false);

        if (mounted) {
          PasscodeReceiptDialog.show(
            context,
            event: createdEvent,
            rawPasscode: rawPasscode,
            emailSent: emailSent,
            onDismiss: () {
              Navigator.of(context).pop();
            },
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving event: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: Text(
          _isEditing ? 'EDIT EVENT' : 'CREATE NEW EVENT',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          TextButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonOrange),
                  )
                : const Icon(Icons.check_circle_outline, color: AppTheme.neonOrange, size: 20),
            label: Text(
              _isEditing ? 'SAVE' : 'PUBLISH',
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppTheme.neonOrange,
                letterSpacing: 1.1,
              ),
            ),
            onPressed: _isSaving ? null : _saveEvent,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          children: [
            // 1. Poster Studio Section
            _buildSectionHeader('1. EVENT POSTER (CLOUDINARY / URL)', Icons.image_outlined),
            CloudinaryUploadWidget(
              currentImageUrl: _posterUrl,
              onImageUrlChanged: (newUrl) {
                setState(() => _posterUrl = newUrl);
              },
            ),
            const SizedBox(height: 24),

            // 2. Basic Information
            _buildSectionHeader('2. BASIC INFORMATION', Icons.info_outline),
            _buildTextField(
              controller: _titleController,
              label: 'Event Title *',
              hint: 'e.g. RoboWars - 15kg Category',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Event title is required' : null,
            ),
            const SizedBox(height: 14),

            // Organizing Club Dropdown
            Text(
              'Organizing Club / Society *',
              style: GoogleFonts.rajdhani(color: AppTheme.metallicSilver, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClub,
                  isExpanded: true,
                  dropdownColor: AppTheme.scaffoldBg,
                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  items: _popularClubs
                      .map((club) => DropdownMenuItem(
                            value: club,
                            child: Text(club),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedClub = val);
                  },
                ),
              ),
            ),
            if (_selectedClub == 'Custom / Other') ...[
              const SizedBox(height: 10),
              _buildTextField(
                controller: _customClubController,
                label: 'Enter Club / Society Name',
                hint: 'e.g. Lit-C, Astronomy Club, C-Cube',
              ),
            ],
            const SizedBox(height: 14),

            // Category & Flagship Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category *',
                        style: GoogleFonts.rajdhani(color: AppTheme.metallicSilver, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            dropdownColor: AppTheme.scaffoldBg,
                            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.only(top: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isFlagship ? AppTheme.neonOrange : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Flagship?',
                          style: GoogleFonts.rajdhani(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isFlagship ? AppTheme.neonOrange : AppTheme.metallicMuted,
                          ),
                        ),
                        Switch(
                          value: _isFlagship,
                          activeThumbColor: AppTheme.neonOrange,
                          onChanged: (val) => setState(() => _isFlagship = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Schedule & Location
            _buildSectionHeader('3. TIMING & VENUE', Icons.calendar_month_outlined),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _dateController,
                    label: 'Date *',
                    hint: 'e.g. Oct 11, 2026',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Date is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _timeController,
                    label: 'Time Slot *',
                    hint: 'e.g. 02:00 PM - 06:00 PM',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Time is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _venueController,
              label: 'Venue *',
              hint: 'e.g. Central Arena (SAC Ground)',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Venue is required' : null,
            ),
            const SizedBox(height: 6),

            // Venue suggestions
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _venueSuggestions.map((venue) {
                return InkWell(
                  onTap: () => setState(() => _venueController.text = venue),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      venue,
                      style: GoogleFonts.rajdhani(fontSize: 11, color: AppTheme.metallicMuted),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 4. Details & Prize
            _buildSectionHeader('4. DETAILS & PRIZES', Icons.emoji_events_outlined),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _prizePoolController,
                    label: 'Prize Pool',
                    hint: 'e.g. ₹ 50,000',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _teamSizeController,
                    label: 'Team Size',
                    hint: 'e.g. 1 - 4 Members',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _descriptionController,
              label: 'Event Description *',
              hint: 'Describe problem statement, format, rounds, and rules...',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _rulebookUrlController,
              label: 'Rulebook URL (Optional)',
              hint: 'https://drive.google.com/... or Notion link',
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _registrationUrlController,
              label: 'Registration URL (Optional)',
              hint: 'Unstop / Google Form link',
            ),
            const SizedBox(height: 24),

            // 5. Coordinator Contact Details
            _buildSectionHeader('5. LEAD COORDINATOR CONTACT', Icons.person_outline),
            _buildTextField(
              controller: _coordinatorNameController,
              label: 'Lead Coordinator Name *',
              hint: 'e.g. Anish Kumar Singh',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Coordinator name is required' : null,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _coordinatorEmailController,
              label: 'Coordinator Email (Passcode will be sent here) *',
              hint: 'e.g. 22je0116@iitism.ac.in',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Coordinator email is required' : null,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _coordinatorPhoneController,
              label: 'Coordinator Phone / WhatsApp',
              hint: '+91 98765 43210',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // 6. Security Passcode
            _buildSectionHeader('6. EVENT SECURITY PASSCODE', Icons.lock_outline),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF140806),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.5), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Leave blank to keep existing passcode, or enter a new one to change:'
                        : 'Set an Event Passcode (4 to 8 characters):',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.metallicSilver,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passcodeController,
                    obscureText: _obscurePasscode,
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E0C09),
                      hintText: _isEditing ? '•••• (Unchanged)' : 'Enter event passcode',
                      hintStyle: GoogleFonts.rajdhani(color: Colors.white30, letterSpacing: 1.0),
                      prefixIcon: const Icon(Icons.key, color: AppTheme.neonOrange, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasscode ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePasscode = !_obscurePasscode),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.neonOrange),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TIP: The coordinator will receive this passcode by email and will need it whenever making changes.',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.cyberAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Big Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.rocket_launch, size: 22),
                label: Text(
                  _isEditing ? 'SAVE CHANGES' : 'PUBLISH EVENT',
                  style: GoogleFonts.rajdhani(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonOrange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving ? null : _saveEvent,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonOrange, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.orbitron(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: AppTheme.metallicSilver,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.rajdhani(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.cardSurface,
            hintText: hint,
            hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.neonOrange),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
