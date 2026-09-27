import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/network/auth_provider.dart';
import '../../core/network/repositories.dart';
import '../../models/event_item.dart';

/// Screen to view and edit team details after registration
class TeamDetailsScreen extends ConsumerStatefulWidget {
  final EventItem event;
  final Map<String, dynamic> teamData;
  final String teamDocId;

  const TeamDetailsScreen({
    super.key,
    required this.event,
    required this.teamData,
    required this.teamDocId,
  });

  @override
  ConsumerState<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends ConsumerState<TeamDetailsScreen> {
  late List<Map<String, dynamic>> _members;
  late String _teamName;
  late bool _isLeader;
  bool _isEditing = false;
  bool _isSaving = false;

  final _teamNameController = TextEditingController();
  final List<List<TextEditingController>> _memberControllers = [];

  late int _minSize;
  late int _maxSize;

  @override
  void initState() {
    super.initState();
    _minSize = widget.event.minTeamSize.clamp(1, 100);
    _maxSize = widget.event.maxTeamSize.clamp(_minSize, 100);

    _teamName = widget.teamData['teamName'] ?? 'Unnamed Team';
    _teamNameController.text = _teamName;

    final rawMembers = widget.teamData['members'] as List<dynamic>? ?? [];
    _members = rawMembers
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    final profile = ref.read(authProvider);
    _isLeader = widget.teamData['leaderEmail']?.toString().toLowerCase() ==
        profile.email.toLowerCase();

    _rebuildControllers();
  }

  void _rebuildControllers() {
    for (final group in _memberControllers) {
      for (final c in group) {
        c.dispose();
      }
    }
    _memberControllers.clear();
    for (final m in _members) {
      _memberControllers.add([
        TextEditingController(text: m['name'] ?? ''),
        TextEditingController(text: m['email'] ?? ''),
        TextEditingController(text: m['phone'] ?? ''),
        TextEditingController(text: m['college'] ?? ''),
      ]);
    }
  }

  void _syncControllersToData() {
    for (int i = 0; i < _members.length && i < _memberControllers.length; i++) {
      _members[i]['name'] = _memberControllers[i][0].text.trim();
      _members[i]['email'] = _memberControllers[i][1].text.trim().toLowerCase();
      _members[i]['phone'] = _memberControllers[i][2].text.trim();
      _members[i]['college'] = _memberControllers[i][3].text.trim();
    }
    _teamName = _teamNameController.text.trim();
  }

  void _addMember() {
    if (_members.length >= _maxSize) return;
    setState(() {
      _members.add({
        'name': '',
        'email': '',
        'phone': '',
        'college': '',
        'isLeader': false,
      });
      _memberControllers.add([
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ]);
    });
  }

  void _removeMember(int index) {
    if (index <= 0 || _members.length <= _minSize) return;
    if (_members[index]['isLeader'] == true) return;
    setState(() {
      for (final c in _memberControllers[index]) {
        c.dispose();
      }
      _members.removeAt(index);
      _memberControllers.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    _syncControllersToData();
    setState(() => _isSaving = true);

    try {
      final db = FirestoreConfig.instance;
      await db
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .doc(widget.teamDocId)
          .update({
        'teamName': _teamName,
        'memberCount': _members.length,
        'members': _members,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team details updated successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _leaveTeam() async {
    final profile = ref.read(authProvider);
    // Leader cannot leave their own team
    if (_isLeader) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team leader cannot leave the team. Transfer leadership or disband.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF120504),
        title: const Text('Leave Team?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this team? You can register again later.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('LEAVE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final db = FirestoreConfig.instance;
      final updatedMembers = _members
          .where((m) =>
              m['email']?.toString().toLowerCase() != profile.email.toLowerCase())
          .toList();

      if (updatedMembers.length < _minSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Cannot leave — team would fall below minimum size ($_minSize members required).'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await db
          .collection('events')
          .doc(widget.event.id)
          .collection('registrations')
          .doc(widget.teamDocId)
          .update({
        'memberCount': updatedMembers.length,
        'members': updatedMembers,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true); // Signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave team: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    for (final group in _memberControllers) {
      for (final c in group) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isSolo = _maxSize <= 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0202),
      appBar: AppBar(
        title: Text(
          isSolo ? 'REGISTRATION DETAILS' : 'TEAM DETAILS',
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLeader && !_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: primaryColor),
              tooltip: 'Edit Team',
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              tooltip: 'Cancel Edit',
              onPressed: () {
                _rebuildControllers();
                setState(() => _isEditing = false);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // Event Info Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.12),
                  const Color(0xFF120504),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: GoogleFonts.orbitron(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoPill(
                      Icons.check_circle,
                      widget.teamData['status'] ?? 'CONFIRMED',
                      Colors.greenAccent,
                    ),
                    const SizedBox(width: 10),
                    if (!isSolo)
                      _infoPill(
                        Icons.groups,
                        '${_members.length} member${_members.length > 1 ? 's' : ''}',
                        primaryColor,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Team Name
          if (!isSolo) ...[
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
            _isEditing
                ? TextFormField(
                    controller: _teamNameController,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.flag, size: 18, color: primaryColor),
                      filled: true,
                      fillColor: const Color(0xFF140605),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF120504),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag, size: 18, color: primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          _teamName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),
          ],

          // Members
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSolo ? 'PARTICIPANT' : 'TEAM MEMBERS',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1,
                ),
              ),
              if (_isEditing && !isSolo && _members.length < _maxSize)
                TextButton.icon(
                  onPressed: _addMember,
                  icon: Icon(Icons.person_add, size: 15, color: primaryColor),
                  label: Text(
                    'ADD',
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

          ...List.generate(_members.length, (i) {
            final m = _members[i];
            final mIsLeader = m['isLeader'] == true;
            return _buildMemberCard(
              index: i,
              data: m,
              isLeader: mIsLeader,
              primaryColor: primaryColor,
            );
          }),

          const SizedBox(height: 24),

          // Action Buttons
          if (_isEditing) ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'SAVE CHANGES',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],

          if (!_isLeader && !_isEditing) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _leaveTeam,
                icon: const Icon(Icons.exit_to_app, size: 18, color: Colors.redAccent),
                label: Text(
                  'LEAVE TEAM',
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMemberCard({
    required int index,
    required Map<String, dynamic> data,
    required bool isLeader,
    required Color primaryColor,
  }) {
    if (_isEditing) {
      final ctrls = _memberControllers[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF120504),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLeader
                ? primaryColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _memberBadge(isLeader, index, primaryColor),
                if (!isLeader && _members.length > _minSize)
                  InkWell(
                    onTap: () => _removeMember(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close, size: 15, color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _editField(ctrls[0], 'Full Name', Icons.person, primaryColor, isLeader),
            const SizedBox(height: 8),
            _editField(ctrls[1], 'Email', Icons.email, primaryColor, isLeader),
            const SizedBox(height: 8),
            _editField(ctrls[2], 'Phone', Icons.phone, primaryColor, false),
            const SizedBox(height: 8),
            _editField(ctrls[3], 'College', Icons.school, primaryColor, false),
          ],
        ),
      );
    }

    // Read-only card
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF120504),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLeader
              ? primaryColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _memberBadge(isLeader, index, primaryColor),
          const SizedBox(height: 10),
          _infoRow(Icons.person, data['name'] ?? 'Unknown', primaryColor),
          const SizedBox(height: 6),
          _infoRow(Icons.email, data['email'] ?? '', primaryColor),
          const SizedBox(height: 6),
          _infoRow(Icons.phone, data['phone'] ?? '', primaryColor),
          const SizedBox(height: 6),
          _infoRow(Icons.school, data['college'] ?? '', primaryColor),
        ],
      ),
    );
  }

  Widget _memberBadge(bool isLeader, int index, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }

  Widget _infoRow(IconData icon, String text, Color primaryColor) {
    return Row(
      children: [
        Icon(icon, size: 15, color: primaryColor.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon,
      Color primaryColor, bool readOnly) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: 13,
        color: readOnly ? Colors.white38 : Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, size: 16, color: primaryColor),
        filled: true,
        fillColor: readOnly
            ? Colors.white.withValues(alpha: 0.03)
            : const Color(0xFF140605),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.rajdhani(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
