import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/network/auth_provider.dart';
import '../../core/network/repositories.dart';
import '../../models/event_item.dart';

/// Data class for a single team member
class TeamMemberData {
  String name;
  String email;
  String phone;
  String college;
  bool isLeader;

  TeamMemberData({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.college = '',
    this.isLeader = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email.toLowerCase().trim(),
        'phone': phone.trim(),
        'college': college.trim(),
        'isLeader': isLeader,
      };
}

class TeamRegistrationScreen extends ConsumerStatefulWidget {
  final EventItem event;

  const TeamRegistrationScreen({super.key, required this.event});

  @override
  ConsumerState<TeamRegistrationScreen> createState() =>
      _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState
    extends ConsumerState<TeamRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final List<TeamMemberData> _members = [];
  final List<List<TextEditingController>> _controllers = [];
  bool _isSubmitting = false;

  late int _minSize;
  late int _maxSize;
  late bool _isSolo;

  @override
  void initState() {
    super.initState();
    _minSize = widget.event.minTeamSize.clamp(1, 100);
    _maxSize = widget.event.maxTeamSize.clamp(_minSize, 100);
    _isSolo = _maxSize <= 1;

    // Add the team leader (logged-in user) as the first member
    final profile = ref.read(authProvider);
    final leader = TeamMemberData(
      name: profile.name,
      email: profile.email,
      phone: profile.phone,
      college: profile.college,
      isLeader: true,
    );
    _members.add(leader);
    _controllers.add(_buildControllers(leader));

    // Add minimum required additional members (minSize includes leader)
    final additionalRequired = _minSize - 1;
    for (int i = 0; i < additionalRequired; i++) {
      _addEmptyMember();
    }
  }

  List<TextEditingController> _buildControllers(TeamMemberData data) {
    return [
      TextEditingController(text: data.name),
      TextEditingController(text: data.email),
      TextEditingController(text: data.phone),
      TextEditingController(text: data.college),
    ];
  }

  void _addEmptyMember() {
    if (_members.length >= _maxSize) return;
    final member = TeamMemberData();
    _members.add(member);
    _controllers.add(_buildControllers(member));
  }

  void _removeMember(int index) {
    // Cannot remove team leader (index 0)
    if (index <= 0 || _members.length <= _minSize) return;
    setState(() {
      for (final c in _controllers[index]) {
        c.dispose();
      }
      _members.removeAt(index);
      _controllers.removeAt(index);
    });
  }

  void _syncControllerToData(int memberIndex) {
    if (memberIndex >= _members.length) return;
    final ctrls = _controllers[memberIndex];
    _members[memberIndex].name = ctrls[0].text.trim();
    _members[memberIndex].email = ctrls[1].text.trim();
    _members[memberIndex].phone = ctrls[2].text.trim();
    _members[memberIndex].college = ctrls[3].text.trim();
  }

  Future<void> _submitRegistration() async {
    // Sync all controllers to data
    for (int i = 0; i < _members.length; i++) {
      _syncControllerToData(i);
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final db = FirestoreConfig.instance;
      final profile = ref.read(authProvider);
      final teamName = _teamNameController.text.trim().isNotEmpty
          ? _teamNameController.text.trim()
          : '${profile.name}\'s Team';

      // Build the team document
      final teamData = {
        'teamName': teamName,
        'eventId': widget.event.id,
        'eventTitle': widget.event.title,
        'leaderUid': profile.uid,
        'leaderEmail': profile.email.toLowerCase().trim(),
        'memberCount': _members.length,
        'members': _members.map((m) => m.toJson()).toList(),
        'registeredAt': FieldValue.serverTimestamp(),
        'registeredAtIso': DateTime.now().toIso8601String(),
        'status': 'CONFIRMED',
      };

      // Save under events/{eventId}/registrations/{auto-id}
      await db
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .add(teamData);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(context, teamName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(BuildContext context, String teamName) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF120504),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Team Registered!',
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.event.title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'TEAM: $teamName',
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_members.length} Member${_members.length > 1 ? 's' : ''} Registered',
                    style: GoogleFonts.rajdhani(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your team has been successfully registered. You can view and manage your team from the event page.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'DONE',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    for (final group in _controllers) {
      for (final c in group) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0202),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'TEAM REGISTRATION',
            style: GoogleFonts.orbitron(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Event Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    const Color(0xFF120504),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: primaryColor.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.groups, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Team Size: $_minSize – $_maxSize members',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.event.date} • ${widget.event.time}',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Team Name
            if (!_isSolo) ...[
              Text(
                'TEAM NAME',
                style: GoogleFonts.rajdhani(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _teamNameController,
                label: 'Enter your team name',
                icon: Icons.flag,
                primaryColor: primaryColor,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Team name is required' : null,
              ),
              const SizedBox(height: 24),
            ],

            // Members Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _isSolo ? 'PARTICIPANT DETAILS' : 'TEAM MEMBERS (${_members.length}/$_maxSize)',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_isSolo && _members.length < _maxSize)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _addEmptyMember());
                    },
                    icon: Icon(Icons.person_add, size: 16, color: primaryColor),
                    label: Text(
                      'ADD MEMBER',
                      style: GoogleFonts.rajdhani(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Member Cards
            ...List.generate(_members.length, (i) {
              final isLeader = _members[i].isLeader;
              return _buildMemberCard(
                index: i,
                isLeader: isLeader,
                primaryColor: primaryColor,
              );
            }),

            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        _isSolo ? 'CONFIRM REGISTRATION' : 'REGISTER TEAM',
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard({
    required int index,
    required bool isLeader,
    required Color primaryColor,
  }) {
    final ctrls = _controllers[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF120504),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLeader
              ? primaryColor.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: isLeader
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLeader
                          ? primaryColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLeader ? '★ TEAM LEADER' : 'MEMBER $index',
                      style: GoogleFonts.rajdhani(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLeader ? primaryColor : Colors.white60,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLeader && _members.length > _minSize)
                InkWell(
                  onTap: () => _removeMember(index),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: ctrls[0],
            label: 'Full Name',
            icon: Icons.person,
            primaryColor: primaryColor,
            readOnly: isLeader,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: ctrls[1],
            label: 'Email Address',
            icon: Icons.email,
            primaryColor: primaryColor,
            readOnly: isLeader,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Valid email required' : null,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: ctrls[2],
            label: 'Phone Number',
            icon: Icons.phone,
            primaryColor: primaryColor,
            readOnly: isLeader,
            validator: (v) =>
                v == null || v.trim().length < 10
                    ? 'Valid phone required'
                    : null,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: ctrls[3],
            label: 'College / Institute',
            icon: Icons.school,
            primaryColor: primaryColor,
            readOnly: isLeader,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'College is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color primaryColor,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        fontSize: 13,
        color: readOnly ? Colors.white38 : Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white60),
        prefixIcon: Icon(icon, size: 18, color: primaryColor),
        suffixIcon: readOnly
            ? Icon(Icons.lock_outline, size: 14, color: Colors.white24)
            : null,
        filled: true,
        fillColor: readOnly
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFF140605),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
