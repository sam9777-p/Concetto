import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/cloudinary_service.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_item.dart';

class EventEditorScreen extends ConsumerStatefulWidget {
  final EventItem? initialEvent;
  final String? authorizedPasscode;
  final bool isMasterAdmin;
  final bool isDeveloperMode;

  const EventEditorScreen({
    super.key,
    this.initialEvent,
    this.authorizedPasscode,
    this.isMasterAdmin = false,
    this.isDeveloperMode = false,
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
  late TextEditingController _specificPasswordController;
  late TextEditingController _posterUrlController;
  late TextEditingController _tagsController;
  late TextEditingController _scheduleBreakdownController;

  late String _selectedClub;
  late Set<String> _selectedCategories;
  late bool _isFlagship;
  late bool _isVisible;
  late bool _isStageExperience;
  late bool _isOpenRegistration;
  late int _minTeamSize;
  late int _maxTeamSize;
  late TextEditingController _minTeamSizeController;
  late TextEditingController _maxTeamSizeController;
  late List<EventStage> _stages;
  bool _obscurePasscode = true;
  bool _isSaving = false;

  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploadingPoster = false;
  double _posterUploadProgress = 0.0;
  bool _isUploadingPdf = false;
  double _pdfUploadProgress = 0.0;

  final List<String> _popularClubs = [
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
    'Custom / Other',
  ];

  final List<String> _allCategories = [
    'Flagship',
    'Robotics',
    'Coding',
    'Electronics',
    'Management',
    'Departmental',
    'Clubs',
    'Design',
    'Aeromodelling',
    'Stage',
    'Gaming & Fun',
  ];

  final List<Map<String, String>> _officialPosterPresets = [
    {'name': 'Default / General', 'url': 'https://concetto-ashen.vercel.app/events/general.png'},
    {'name': 'RoboWars', 'url': 'https://concetto-ashen.vercel.app/events/roboWars.png'},
    {'name': 'CaseBlitz', 'url': 'https://concetto-ashen.vercel.app/events/Caseblitz.png'},
    {'name': 'QuesTree', 'url': 'https://concetto-ashen.vercel.app/events/questree.png'},
    {'name': 'DevDash', 'url': 'https://concetto-ashen.vercel.app/events/devdash.jpg'},
    {'name': 'Sparkathon', 'url': 'https://concetto-ashen.vercel.app/events/Saparkthon.jpeg'},
    {'name': 'AeroGlide', 'url': 'https://concetto-ashen.vercel.app/events/AeroGlide.png'},
    {'name': 'Gate Craft', 'url': 'https://concetto-ashen.vercel.app/events/GateCraft.png'},
    {'name': 'Mathalon', 'url': 'https://concetto-ashen.vercel.app/events/mathalon.png'},
    {'name': 'Archway Arena', 'url': 'https://concetto-ashen.vercel.app/events/archway-arena.png'},
    {'name': 'Edge AI', 'url': 'https://concetto-ashen.vercel.app/events/EdgeAi.png'},
    {'name': 'DJ Night', 'url': 'https://concetto-ashen.vercel.app/events/dj-night.png'},
    {'name': 'Comedy Night', 'url': 'https://concetto-ashen.vercel.app/events/comedy-night.png'},
    {'name': 'Star Night', 'url': 'https://concetto-ashen.vercel.app/events/star-night.png'},
    {'name': 'Stunt Show', 'url': 'https://concetto-ashen.vercel.app/events/stunt-show.png'},
  ];

  final List<String> _venueSuggestions = [
    'Central Arena (SAC Ground)',
    'Penman Auditorium',
    'NLHC Hall 1',
    'NLHC Hall 2',
    'Library 4th floor, GJLT',
    'NVCTI Incubation Center',
    'Computer Center Lab 2',
    'Management Studies Hall',
    'Golden Jubilee Lecture Hall',
    'Mining Dept Ground',
    'SAC Lawn & Grounds',
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

    // Initial category selection
    _selectedCategories = {};
    if (e != null) {
      if (e.category.isNotEmpty) _selectedCategories.add(e.category);
      for (final t in e.tags) {
        if (_allCategories.any((c) => c.toLowerCase() == t.toLowerCase())) {
          final matched = _allCategories.firstWhere((c) => c.toLowerCase() == t.toLowerCase());
          _selectedCategories.add(matched);
        }
      }
    }
    if (_selectedCategories.isEmpty) {
      _selectedCategories.add('Robotics');
    }

    _isFlagship = e?.isFlagship ?? false;
    _isVisible = e?.isVisible ?? true;
    _isStageExperience = e?.isStageExperience ?? false;
    _stages = List<EventStage>.from(e?.stages ?? []);

    final initialPoster = (e?.posterUrl != null && e!.posterUrl.isNotEmpty)
        ? e.posterUrl
        : 'https://concetto-ashen.vercel.app/events/general.png';
    _posterUrlController = TextEditingController(text: initialPoster);

    _dateController = TextEditingController(text: e?.date ?? 'Oct 10, 2026');
    _timeController = TextEditingController(text: e?.time ?? '10:00 AM - 01:00 PM');
    _venueController = TextEditingController(text: e?.venue ?? 'Central Arena (SAC Ground)');
    _prizePoolController = TextEditingController(text: e?.prizePool ?? '₹ 30,000');
    _teamSizeController = TextEditingController(text: e?.teamSize ?? '1 - 4 Members');
    _isOpenRegistration = e?.isOpenRegistration ?? false;
    _minTeamSize = e?.minTeamSize ?? 1;
    _maxTeamSize = e?.maxTeamSize ?? 4;
    if (e != null && (e.teamSize.toLowerCase().contains('open') || e.teamSize.toLowerCase().contains('individual'))) {
      _isOpenRegistration = true;
    }
    _minTeamSizeController = TextEditingController(text: _minTeamSize.toString());
    _maxTeamSizeController = TextEditingController(text: _maxTeamSize.toString());

    _descriptionController = TextEditingController(text: e?.description ?? '');
    _rulebookUrlController = TextEditingController(text: e?.rulebookUrl ?? '');
    _registrationUrlController = TextEditingController(text: e?.registrationUrl ?? '');
    _coordinatorNameController = TextEditingController(text: e?.coordinatorName ?? '');
    _coordinatorEmailController = TextEditingController(text: e?.coordinatorEmail ?? '');
    _coordinatorPhoneController = TextEditingController(
      text: e?.coordinatorPhone.isNotEmpty == true ? e!.coordinatorPhone : (e?.coordinatorContact ?? ''),
    );

    // Specific password
    final initialPass = (e != null && e.specificPassword.isNotEmpty)
        ? e.specificPassword
        : (widget.authorizedPasscode?.isNotEmpty == true
            ? widget.authorizedPasscode!
            : FirestoreService.generateSpecificPassword(e?.title ?? 'newevent'));

    _specificPasswordController = TextEditingController(text: initialPass);

    final initialTags = e != null && e.tags.isNotEmpty
        ? e.tags
        : _selectedCategories.toList();
    _tagsController = TextEditingController(text: initialTags.join(', '));
    _scheduleBreakdownController = TextEditingController(text: e?.scheduleBreakdown ?? '');
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
    _minTeamSizeController.dispose();
    _maxTeamSizeController.dispose();
    _descriptionController.dispose();
    _rulebookUrlController.dispose();
    _registrationUrlController.dispose();
    _coordinatorNameController.dispose();
    _coordinatorEmailController.dispose();
    _coordinatorPhoneController.dispose();
    _specificPasswordController.dispose();
    _posterUrlController.dispose();
    _tagsController.dispose();
    _scheduleBreakdownController.dispose();
    super.dispose();
  }

  void _syncTagsWithCategories() {
    final existingCustomTags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !_allCategories.any((c) => c.toLowerCase() == t.toLowerCase()))
        .toList();

    final allCombined = [..._selectedCategories, ...existingCustomTags];
    _tagsController.text = allCombined.join(', ');
  }

  Future<void> _launchExternalUrl(String rawUrl, String label) async {
    final clean = rawUrl.trim();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a $label first.')),
      );
      return;
    }
    final uri = Uri.tryParse(clean);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open invalid URL: $clean')),
        );
      }
    }
  }

  void _showStageEditorDialog({EventStage? stage, int? index}) {
    final nameCtrl = TextEditingController(text: stage?.name ?? '');
    final dateCtrl = TextEditingController(text: stage?.date ?? _dateController.text);
    final timeCtrl = TextEditingController(text: stage?.time ?? _timeController.text);
    final venueCtrl = TextEditingController(text: stage?.venue ?? _venueController.text);
    final synopsisCtrl = TextEditingController(text: stage?.synopsis ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.scaffoldBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.neonOrange, width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.timeline, color: AppTheme.neonOrange),
            const SizedBox(width: 8),
            Text(
              stage == null ? 'ADD STAGE / ROUND' : 'EDIT STAGE / ROUND',
              style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Stage / Round Name *',
                  hintText: 'e.g. Round 1 - Prelims, Arena Battles, Finals',
                  labelStyle: GoogleFonts.rajdhani(color: AppTheme.cyberAmber),
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Date *',
                  hintText: 'e.g. Oct 9, 2026',
                  labelStyle: GoogleFonts.rajdhani(color: AppTheme.cyberAmber),
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeCtrl,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Time Slot *',
                  hintText: 'e.g. 10:00 AM - 01:00 PM',
                  labelStyle: GoogleFonts.rajdhani(color: AppTheme.cyberAmber),
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: venueCtrl,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Venue *',
                  hintText: 'e.g. Penman Auditorium, Central Arena',
                  labelStyle: GoogleFonts.rajdhani(color: AppTheme.cyberAmber),
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: synopsisCtrl,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Synopsis / Instructions (Optional)',
                  hintText: 'Brief summary of what happens in this stage',
                  labelStyle: GoogleFonts.rajdhani(color: AppTheme.cyberAmber),
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                  filled: true,
                  fillColor: AppTheme.cardSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonOrange, foregroundColor: Colors.black),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final newStage = EventStage(
                name: name,
                date: dateCtrl.text.trim(),
                time: timeCtrl.text.trim(),
                venue: venueCtrl.text.trim(),
                synopsis: synopsisCtrl.text.trim(),
              );
              setState(() {
                if (index != null && index >= 0 && index < _stages.length) {
                  _stages[index] = newStage;
                } else {
                  _stages.add(newStage);
                }
              });
              Navigator.of(ctx).pop();
            },
            child: Text(stage == null ? 'ADD STAGE' : 'SAVE STAGE', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPoster(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _isUploadingPoster = true;
        _posterUploadProgress = 0.0;
      });

      final String uploadedUrl = await _cloudinaryService.uploadImage(
        file: file,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _posterUploadProgress = progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isUploadingPoster = false;
          _posterUrlController.text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E676)),
                SizedBox(width: 8),
                Expanded(child: Text('Poster uploaded & URL updated!')),
              ],
            ),
            backgroundColor: Color(0xFF140806),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPoster = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Poster upload error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.neonOrange, width: 0.8),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT POSTER SOURCE',
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppTheme.neonOrange),
                  title: Text(
                    'Device Gallery',
                    style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Choose image from device gallery to upload',
                    style: GoogleFonts.rajdhani(color: AppTheme.metallicMuted, fontSize: 12),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: AppTheme.cardSurface,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUploadPoster(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.cyberAmber),
                  title: Text(
                    'Camera',
                    style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Take a picture with device camera and upload',
                    style: GoogleFonts.rajdhani(color: AppTheme.metallicMuted, fontSize: 12),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  tileColor: AppTheme.cardSurface,
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUploadPoster(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadRulebookPdf() async {
    try {
      final List<PlatformFile> pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pickedFiles.isEmpty) return;

      setState(() {
        _isUploadingPdf = true;
        _pdfUploadProgress = 0.0;
      });

      final String uploadedUrl = await _cloudinaryService.uploadRulebookPdf(
        file: pickedFiles.first,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _pdfUploadProgress = progress);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isUploadingPdf = false;
          _rulebookUrlController.text = uploadedUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF00E676)),
                SizedBox(width: 8),
                Expanded(child: Text('Rulebook PDF uploaded & URL updated!')),
              ],
            ),
            backgroundColor: Color(0xFF140806),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rulebook PDF upload error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Expanded(child: Text('Please check and fill in all required fields marked with *.')),
            ],
          ),
          backgroundColor: Color(0xFF240A08),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final finalClub = _selectedClub == 'Custom / Other'
        ? (_customClubController.text.trim().isNotEmpty
            ? _customClubController.text.trim()
            : 'Concetto Organizing Team')
        : _selectedClub;

    final parsedTags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final primaryCategory = _selectedCategories.isNotEmpty
        ? _selectedCategories.first
        : 'General';

    final cleanPosterUrl = _posterUrlController.text.trim().isNotEmpty
        ? _posterUrlController.text.trim()
        : 'https://concetto-ashen.vercel.app/events/general.png';

    final finalSpecificPassword = _specificPasswordController.text.trim().isNotEmpty
        ? _specificPasswordController.text.trim()
        : FirestoreService.generateSpecificPassword(_titleController.text.trim());

    if (!_isOpenRegistration && !_isStageExperience) {
      final minParsed = int.tryParse(_minTeamSizeController.text.trim()) ?? _minTeamSize;
      final maxParsed = int.tryParse(_maxTeamSizeController.text.trim()) ?? _maxTeamSize;
      if (minParsed < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimum team size must be at least 1 member')),
        );
        return;
      }
      if (maxParsed < minParsed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Max team size must be greater than or equal to min team size')),
        );
        return;
      }
      _minTeamSize = minParsed;
      _maxTeamSize = maxParsed;
    }

    final computedTeamSize = _isStageExperience
        ? 'Open Showcase'
        : (_isOpenRegistration
            ? 'Open Registration'
            : (_minTeamSize == _maxTeamSize
                ? (_minTeamSize <= 1 ? 'Solo (1 Member)' : '$_minTeamSize Members')
                : '$_minTeamSize - $_maxTeamSize Members'));

    final eventItem = EventItem(
      id: widget.initialEvent?.id ?? '',
      title: _titleController.text.trim(),
      organizerClub: finalClub,
      category: primaryCategory,
      tags: parsedTags.isNotEmpty ? parsedTags : _selectedCategories.toList(),
      venue: _venueController.text.trim(),
      time: _timeController.text.trim(),
      date: _dateController.text.trim(),
      prizePool: primaryCategory.toLowerCase() == 'workshops' ? '' : _prizePoolController.text.trim(),
      teamSize: computedTeamSize,
      minTeamSize: _minTeamSize,
      maxTeamSize: _maxTeamSize,
      isOpenRegistration: _isOpenRegistration,
      description: _descriptionController.text.trim(),
      posterUrl: cleanPosterUrl,
      rulebookUrl: (_isStageExperience || primaryCategory.toLowerCase() == 'workshops') ? '' : _rulebookUrlController.text.trim(),
      registrationUrl: _isStageExperience ? '' : _registrationUrlController.text.trim(),
      coordinatorName: _coordinatorNameController.text.trim(),
      coordinatorEmail: _coordinatorEmailController.text.trim(),
      coordinatorPhone: _coordinatorPhoneController.text.trim(),
      isFlagship: _isFlagship,
      isVisible: _isVisible,
      isStageExperience: _isStageExperience,
      isWatchableOnly: _isStageExperience,
      scheduleBreakdown: _scheduleBreakdownController.text.trim(),
      stages: _stages,
      specificPassword: finalSpecificPassword,
      passwordHash: FirestoreService.hashPasscode(finalSpecificPassword),
    );

    setState(() => _isSaving = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      if (_isEditing) {
        await firestoreService.updateEvent(eventItem);
        ref.invalidate(adminEventsProvider);
        ref.invalidate(eventsProvider);
        setState(() => _isSaving = false);

        if (mounted) {
          final successMsg = 'Event "${eventItem.title}" updated successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      successMsg,
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
          Navigator.of(context).pop(successMsg);
        }
      } else {
        final createdEvent = await firestoreService.createEvent(
          eventItem,
          explicitSpecificPassword: finalSpecificPassword,
        );
        ref.invalidate(adminEventsProvider);
        ref.invalidate(eventsProvider);
        setState(() => _isSaving = false);

        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => Dialog(
              backgroundColor: AppTheme.scaffoldBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF00E676), width: 1.5),
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppTheme.darkCardGradient,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0x2200E676),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'EVENT CREATED & PUBLISHED!',
                      style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A unique Specific Event Passkey has been generated for this event. Provide this passkey to the event coordinator.',
                      style: GoogleFonts.rajdhani(color: AppTheme.metallicSilver, fontSize: 13, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Passkey Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF160907),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.neonOrange, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SPECIFIC EVENT PASSKEY:',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neonOrange,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                SelectableText(
                                  createdEvent.specificPassword,
                                  style: GoogleFonts.orbitron(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppTheme.neonOrange, size: 20),
                            tooltip: 'Copy Passkey',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: createdEvent.specificPassword));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Passkey copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonOrange,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'DONE & RETURN TO HUB',
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving event: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
          _isEditing ? 'EDIT FESTIVAL EVENT' : 'CREATE NEW EVENT',
          style: GoogleFonts.orbitron(
            fontSize: 15,
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
                : const Icon(Icons.cloud_upload_outlined, color: AppTheme.neonOrange, size: 20),
            label: Text(
              _isEditing ? 'SAVE CHANGES' : 'PUBLISH EVENT',
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
            // 1. Basic Info
            _buildSectionHeader('1. BASIC INFORMATION', Icons.info_outline),
            _buildTextField(
              controller: _titleController,
              label: 'Event Title *',
              hint: 'e.g. RoboWars — 15kg Combat Arena',
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
                label: 'Enter Custom Club / Society Name',
                hint: 'e.g. Astronomy Club, Mining Society',
              ),
            ],
            const SizedBox(height: 14),

            // Stage Experience Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _isStageExperience ? const Color(0x22FF6D00) : AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isStageExperience ? AppTheme.neonOrange : Colors.white12,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isStageExperience ? AppTheme.neonOrange : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.theater_comedy,
                      color: _isStageExperience ? Colors.black : Colors.white60,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STAGE EXPERIENCE / SHOWCASE',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isStageExperience ? AppTheme.neonOrange : Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Open stage show, guest talk, star night, or showcase. No registration link, Google form, team size, or rulebook required.',
                          style: GoogleFonts.rajdhani(
                            fontSize: 11,
                            color: AppTheme.metallicSilver,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isStageExperience,
                    activeThumbColor: AppTheme.neonOrange,
                    activeTrackColor: AppTheme.neonOrange.withValues(alpha: 0.4),
                    onChanged: (val) => setState(() => _isStageExperience = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Categories Selection (Grey & Orange Checkbox options)
            _buildSectionHeader('2. CATEGORIES & DOMAINS', Icons.category_outlined),
            Text(
              'Select applicable categories (Multi-select options with glowing orange highlight):',
              style: GoogleFonts.rajdhani(color: AppTheme.metallicSilver, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCategories.map((cat) => _buildCategoryOption(cat)).toList(),
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: _tagsController,
              label: 'Search Tags / Domains (comma separated)',
              hint: 'e.g. Departmental, Coding, Electronics, Hardware, Case Study',
            ),
            const SizedBox(height: 16),

            // Flagship & Visibility Toggles in Row
            Row(
              children: [
                // Flagship Toggle
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Flagship?',
                              style: GoogleFonts.rajdhani(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isFlagship ? AppTheme.neonOrange : AppTheme.metallicMuted,
                              ),
                            ),
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
                const SizedBox(width: 10),

                // Visibility Toggle
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isVisible ? const Color(0xFF00E676) : Colors.orangeAccent,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isVisible ? 'LIVE VISIBLE' : 'HIDDEN DRAFT',
                              style: GoogleFonts.rajdhani(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _isVisible ? const Color(0xFF00E676) : Colors.orangeAccent,
                              ),
                            ),
                            Text(
                              _isVisible ? 'Shown to students' : 'Hidden from students',
                              style: GoogleFonts.rajdhani(fontSize: 10, color: Colors.white38),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isVisible,
                          activeThumbColor: const Color(0xFF00E676),
                          activeTrackColor: const Color(0x5500E676),
                          inactiveThumbColor: Colors.orangeAccent,
                          inactiveTrackColor: Colors.white12,
                          onChanged: (val) => setState(() => _isVisible = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Timing, Venue & Schedule Breakdown
            _buildSectionHeader('3. SCHEDULE, TIMELINE & ROUNDS BREAKDOWN', Icons.calendar_month_outlined),
            Text(
              'Quick Festival Day Selector:',
              style: GoogleFonts.rajdhani(color: AppTheme.cyberAmber, fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                {'day': 'DAY 0 (Oct 8)', 'val': 'Oct 8, 2026'},
                {'day': 'DAY 1 (Oct 9)', 'val': 'Oct 9, 2026'},
                {'day': 'DAY 2 (Oct 10)', 'val': 'Oct 10, 2026'},
                {'day': 'DAY 3 (Oct 11)', 'val': 'Oct 11, 2026'},
                {'day': 'OCT 10-12 (ALL DAYS)', 'val': 'Oct 10-12, 2026'},
              ].map((d) {
                final isSelected = _dateController.text.contains(d['val']!.split(',')[0]);
                return ActionChip(
                  label: Text(
                    d['day']!,
                    style: GoogleFonts.rajdhani(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                  ),
                  backgroundColor: isSelected ? AppTheme.neonOrange : AppTheme.cardSurface,
                  side: BorderSide(
                    color: isSelected ? AppTheme.neonOrange : Colors.white12,
                  ),
                  onPressed: () => setState(() => _dateController.text = d['val']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _dateController,
                    label: 'Date *',
                    hint: 'e.g. Oct 10, 2026',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Date is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _timeController,
                    label: 'Time Slot *',
                    hint: 'e.g. 10:00 AM - 01:00 PM',
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
            const SizedBox(height: 16),

            // Schedule Breakdown & Rounds part
            _buildTextField(
              controller: _scheduleBreakdownController,
              label: 'Schedule Breakdown / Rounds & Stages Timeline',
              hint: 'Detail rounds & timings:\nRound 1: Screening & Problem Analysis (Oct 8, 4:00 PM)\nRound 2: Arena Elimination Battles (Oct 9, 10:00 AM)\nFinals: Grand Presentation & Valediction (Oct 10, 2:00 PM)',
              maxLines: 4,
            ),
            const SizedBox(height: 8),

            // Quick Breakdown Templates
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.playlist_add, size: 14, color: AppTheme.cyberAmber),
                  label: Text('2-Round Format', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  backgroundColor: const Color(0xFF1B0B08),
                  side: const BorderSide(color: Colors.white12),
                  onPressed: () {
                    setState(() {
                      _scheduleBreakdownController.text =
                          'Round 1: Online Screening & Problem Submission\n'
                          'Round 2: On-Campus Arena Presentation & Judging';
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.playlist_add, size: 14, color: AppTheme.neonOrange),
                  label: Text('3-Round Format', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  backgroundColor: const Color(0xFF1B0B08),
                  side: const BorderSide(color: Colors.white12),
                  onPressed: () {
                    setState(() {
                      _scheduleBreakdownController.text =
                          'Round 1: Preliminary Aptitude & Coding Round (Day 1)\n'
                          'Round 2: Prototype Development / Arena Combat (Day 2)\n'
                          'Finals: Grand Finale & Valediction (Day 3)';
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.playlist_add, size: 14, color: Color(0xFF00E676)),
                  label: Text('Single Stage', style: GoogleFonts.rajdhani(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                  backgroundColor: const Color(0xFF1B0B08),
                  side: const BorderSide(color: Colors.white12),
                  onPressed: () {
                    setState(() {
                      _scheduleBreakdownController.text =
                          'Stage 1: Main Event & Arena Exhibition (6:00 PM - 9:30 PM)';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Multi-Stage / Multi-Round Timeline Manager
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _stages.isNotEmpty ? AppTheme.neonOrange.withValues(alpha: 0.5) : Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hub_outlined, color: AppTheme.neonOrange, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'INDIVIDUAL ROUNDS & STAGES (${_stages.length})',
                            style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.cyberAmber,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          'ADD STAGE',
                          style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _showStageEditorDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Multi-stage events appear automatically under their respective days and times in the festival schedule.',
                    style: GoogleFonts.rajdhani(color: AppTheme.metallicMuted, fontSize: 11),
                  ),
                  if (_stages.isEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white38, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No specific rounds configured. This event will show in the festival schedule using the master date, time, and venue above.',
                              style: GoogleFonts.rajdhani(color: Colors.white60, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final st = _stages[idx];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF140806),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0x33FF6D00),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neonOrange,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      st.name,
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (st.date.isNotEmpty) ...[
                                          const Icon(Icons.calendar_today, size: 11, color: AppTheme.cyberAmber),
                                          const SizedBox(width: 3),
                                          Text(
                                            st.date,
                                            style: GoogleFonts.rajdhani(fontSize: 11, color: AppTheme.cyberAmber),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (st.time.isNotEmpty) ...[
                                          const Icon(Icons.access_time, size: 11, color: AppTheme.metallicSilver),
                                          const SizedBox(width: 3),
                                          Text(
                                            st.time,
                                            style: GoogleFonts.rajdhani(fontSize: 11, color: AppTheme.metallicSilver),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (st.venue.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 11, color: Colors.white54),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            child: Text(
                                              st.venue,
                                              style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white54),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (st.synopsis.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        st.synopsis,
                                        style: GoogleFonts.rajdhani(fontSize: 11, color: Colors.white38, fontStyle: FontStyle.italic),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.cyberAmber),
                                onPressed: () => _showStageEditorDialog(stage: st, index: idx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() => _stages.removeAt(idx));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Details & Team Size / Prize Pool
            _buildSectionHeader('4. DETAILS & REGISTRATION SPECS', Icons.groups_outlined),
            if (!_selectedCategories.contains('Workshops')) ...[
              _buildTextField(
                controller: _prizePoolController,
                label: 'Prize Money',
                hint: 'e.g. ₹ 50,000 (Leave empty if no cash prize)',
              ),
              const SizedBox(height: 12),
            ],
            if (!_isStageExperience) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isOpenRegistration ? AppTheme.neonOrange.withValues(alpha: 0.5) : Colors.white12,
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppTheme.neonOrange,
                  title: Text(
                    'Open Registration',
                    style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Enable if registration is open without fixed team limits (no min/max required)',
                    style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12),
                  ),
                  value: _isOpenRegistration,
                  onChanged: (val) {
                    setState(() {
                      _isOpenRegistration = val;
                    });
                  },
                ),
              ),
              if (!_isOpenRegistration) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Min Team Size (Low) *',
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.metallicSilver,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _minTeamSizeController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.cardSurface,
                              hintText: 'e.g. 1',
                              hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.neonOrange)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Max Team Size (High) *',
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.metallicSilver,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _maxTeamSizeController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.cardSurface,
                              hintText: 'e.g. 4',
                              hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.neonOrange)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final minVal = int.tryParse(_minTeamSizeController.text.trim()) ?? 1;
                    final maxVal = int.tryParse(_maxTeamSizeController.text.trim()) ?? 4;
                    final isInvalid = maxVal < minVal;
                    final displayText = minVal == maxVal
                        ? (minVal <= 1 ? 'Solo (1 Member)' : '$minVal Members')
                        : '$minVal - $maxVal Members';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isInvalid ? Colors.redAccent.withValues(alpha: 0.1) : AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isInvalid ? Colors.redAccent : AppTheme.neonOrange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isInvalid ? Icons.warning_amber_rounded : Icons.info_outline,
                            size: 16,
                            color: isInvalid ? Colors.redAccent : AppTheme.neonOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isInvalid
                                  ? 'Max team size (High) must be greater than or equal to Min team size (Low)'
                                  : 'Display Output: $displayText',
                              style: GoogleFonts.rajdhani(
                                color: isInvalid ? Colors.redAccent : Colors.white70,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],

            _buildTextField(
              controller: _descriptionController,
              label: 'Event Description & Rules Overview *',
              hint: 'Describe problem statement, format, rounds, eligibility, and rules...',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),
            const SizedBox(height: 24),

            // 5. Image / Poster URL Studio
            _buildSectionHeader('5. EVENT POSTER IMAGE', Icons.image_outlined),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cloudinary Upload Action Bar
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUploadingPoster ? null : _showImageSourcePicker,
                          icon: _isUploadingPoster
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: Text(
                            _isUploadingPoster
                                ? 'UPLOADING (${(_posterUploadProgress * 100).toInt()}%)'
                                : 'UPLOAD POSTER',
                            style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonOrange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isUploadingPoster) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _posterUploadProgress > 0 ? _posterUploadProgress : null,
                      backgroundColor: Colors.white12,
                      color: AppTheme.neonOrange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _posterUrlController,
                    label: 'Poster Image Direct URL *',
                    hint: 'https://... or direct image link',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Image URL is required' : null,
                  ),
                  const SizedBox(height: 10),

                  // Quick Poster Presets
                  Text(
                    'Quick Presets (Official Verified Posters):',
                    style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyberAmber),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _officialPosterPresets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final p = _officialPosterPresets[index];
                        final isSelected = _posterUrlController.text.trim() == p['url'];
                        return ActionChip(
                          label: Text(
                            p['name']!,
                            style: GoogleFonts.rajdhani(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.black : Colors.white70,
                            ),
                          ),
                          backgroundColor: isSelected ? AppTheme.neonOrange : const Color(0xFF1E1E1E),
                          onPressed: () => setState(() => _posterUrlController.text = p['url']!),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live Preview Box (Ratio 3:2)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'LIVE PREVIEW (3:2 CARD RATIO)',
                          style: GoogleFonts.rajdhani(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.metallicMuted),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 240,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.5)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: _posterUrlController.text.trim().isNotEmpty
                                ? _posterUrlController.text.trim()
                                : 'https://concetto-ashen.vercel.app/events/general.png',
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: Colors.black38, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (_, _, _) => Container(
                              color: const Color(0xFF1E0A08),
                              child: const Center(child: Icon(Icons.broken_image, color: Colors.white38, size: 32)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. External Links & Documents
            _buildSectionHeader('6. RULEBOOK & REGISTRATION LINKS', Icons.link_rounded),
            if (_isStageExperience)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x18FF6D00),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.theater_comedy, color: AppTheme.neonOrange, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STAGE EXPERIENCE MODE ACTIVE',
                            style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.neonOrange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Registration link, Google forms, and rulebook are omitted for open stage shows, star nights, and exhibitions.',
                            style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cloudinary Rulebook PDF upload button
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploadingPdf ? null : _pickAndUploadRulebookPdf,
                            icon: _isUploadingPdf
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: Text(
                              _isUploadingPdf
                                  ? 'UPLOADING PDF (${(_pdfUploadProgress * 100).toInt()}%)'
                                  : 'UPLOAD RULEBOOK PDF',
                              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isUploadingPdf) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _pdfUploadProgress > 0 ? _pdfUploadProgress : null,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _rulebookUrlController,
                            label: 'Rulebook Link (PDF / Drive)',
                            hint: 'https://.../rulebook.pdf',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Test Rulebook Link in Browser',
                          icon: const Icon(Icons.open_in_new, color: AppTheme.cyberAmber),
                          onPressed: () => _launchExternalUrl(_rulebookUrlController.text, 'Rulebook Link'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _registrationUrlController,
                            label: 'Registration Form (Google Form / Unstop Link)',
                            hint: 'https://docs.google.com/forms/d/e/.../viewform',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Test Google Form Link in Browser',
                          icon: const Icon(Icons.open_in_new, color: AppTheme.cyberAmber),
                          onPressed: () => _launchExternalUrl(_registrationUrlController.text, 'Google Form Link'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // 7. Coordinator Contacts
            _buildSectionHeader('7. EVENT COORDINATOR CONTACT', Icons.person_outline),
            _buildTextField(
              controller: _coordinatorNameController,
              label: 'Lead Coordinator Name *',
              hint: 'e.g. Utkarsh / Anish Kumar',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Coordinator name is required' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _coordinatorPhoneController,
                    label: 'Coordinator Phone / WhatsApp',
                    hint: '+91 98765 43210',
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _coordinatorEmailController,
                    label: 'Coordinator Email',
                    hint: 'club@iitism.ac.in',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 8. Specific Passkey
            _buildSectionHeader('8. SPECIFIC EVENT PASSKEY', Icons.key_rounded),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF140806),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Specific Passkey for this event (Used along with Master Password to edit):'
                        : 'Auto-generated Specific Passkey for this new event:',
                    style: GoogleFonts.rajdhani(color: AppTheme.metallicSilver, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _specificPasswordController,
                    obscureText: _obscurePasscode,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF1E0C09),
                      prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppTheme.neonOrange, size: 20),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(_obscurePasscode ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                            onPressed: () => setState(() => _obscurePasscode = !_obscurePasscode),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppTheme.cyberAmber, size: 20),
                            tooltip: 'Copy Passkey',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _specificPasswordController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Passkey copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.neonOrange)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Big Save Button
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
                  _isEditing ? 'SAVE CHANGES' : 'CREATE & PUBLISH EVENT',
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

  Widget _buildCategoryOption(String cat) {
    final isSelected = _selectedCategories.contains(cat);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedCategories.length > 1) {
              _selectedCategories.remove(cat);
            }
          } else {
            _selectedCategories.add(cat);
          }
          _syncTagsWithCategories();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonOrange : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF9E80) : const Color(0xFF383838),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.neonOrange.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 17,
              color: isSelected ? Colors.black : const Color(0xFF8E8E93),
            ),
            const SizedBox(width: 7),
            Text(
              cat.toUpperCase(),
              style: GoogleFonts.rajdhani(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black : const Color(0xFFD1D1D6),
                letterSpacing: 0.8,
              ),
            ),
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
