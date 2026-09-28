import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/network/auth_provider.dart';
import '../../core/network/repositories.dart';
import '../../core/theme/app_theme.dart';

class GuestPassDashboardScreen extends StatefulWidget {
  const GuestPassDashboardScreen({super.key});

  @override
  State<GuestPassDashboardScreen> createState() => _GuestPassDashboardScreenState();
}

class _GuestPassDashboardScreenState extends State<GuestPassDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryFilter; // null = all non-IIT ISM (types 1-5), -1 = all attendees including type 0
  bool _isLoading = true;
  List<Map<String, dynamic>> _attendees = [];
  String? _errorMessage;

  static const Map<int, Color> categoryColors = {
    0: AppTheme.cyberCyan,
    1: AppTheme.neonOrange,
    2: Color(0xFFB0BEC5), // Silver
    3: Color(0xFFFFD700), // Gold
    4: Color(0xFF00E5FF), // Diamond
    5: Color(0xFFE040FB), // Diamond+ Merch
  };


  @override
  void initState() {
    super.initState();
    _fetchAttendees();
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

  Future<void> _fetchAttendees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final db = FirestoreConfig.instance;
    final Map<String, Map<String, dynamic>> mergedUsers = {};

    try {
      final querySnap = await db.collection('users').get().timeout(const Duration(seconds: 7));
      for (final doc in querySnap.docs) {
        final data = doc.data();
        final uid = data['uid'] as String? ?? doc.id;
        
        // Skip any stub pass-id documents that aren't actual user profiles
        if (doc.id.startsWith('CON-') && !data.containsKey('email')) {
          continue;
        }

        mergedUsers[uid] = {
          'docId': doc.id,
          ...data,
        };
      }
    } catch (e) {
      debugPrint('Fetch attendees error from concetto db: $e');
    }

    final list = mergedUsers.values.toList();
    // Sort primarily by pass category desc, then name
    list.sort((a, b) {
      final typeA = (a['passType'] is int) ? a['passType'] as int : int.tryParse(a['passType']?.toString() ?? '1') ?? 1;
      final typeB = (b['passType'] is int) ? b['passType'] as int : int.tryParse(b['passType']?.toString() ?? '1') ?? 1;
      if (typeA != typeB) return typeB.compareTo(typeA);
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    if (mounted) {
      setState(() {
        _attendees = list;
        _isLoading = false;
        if (list.isEmpty) {
          _errorMessage = 'No attendee profiles found in cloud database.';
        }
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAttendees {
    return _attendees.where((att) {
      final passType = (att['passType'] is int)
          ? att['passType'] as int
          : int.tryParse(att['passType']?.toString() ?? '1') ?? 1;
      final college = (att['college'] as String? ?? '').toLowerCase();
      final isIitIsm = (att['isIitIsm'] == true) || college.contains('ism') || college.contains('iit (ism)');

      // Default filter: Only Non-IIT ISM users (Pass categories 1, 2, 3, 4, 5)
      if (_selectedCategoryFilter == null) {
        if (passType == 0 && isIitIsm) return false;
      } else if (_selectedCategoryFilter != -1) {
        if (passType != _selectedCategoryFilter) return false;
      }

      // Search filter matching ANY detail:
      if (_searchQuery.isNotEmpty) {
        final name = (att['name'] as String? ?? '').toLowerCase();
        final email = (att['email'] as String? ?? '').toLowerCase();
        final phone = (att['phone'] as String? ?? '').toLowerCase();
        final passId = (att['passId'] as String? ?? '').toLowerCase();
        final categoryTitle = (att['passCategory'] as String? ?? AttendeeProfile.passCategoryNames[passType] ?? '').toLowerCase();
        final docId = (att['docId'] as String? ?? '').toLowerCase();
        final uid = (att['uid'] as String? ?? '').toLowerCase();

        final matches = name.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            college.contains(_searchQuery) ||
            passId.contains(_searchQuery) ||
            categoryTitle.contains(_searchQuery) ||
            docId.contains(_searchQuery) ||
            uid.contains(_searchQuery);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _showEditPassDialog(Map<String, dynamic> attendee) {
    final docId = attendee['docId'] as String? ?? attendee['uid'] as String? ?? '';
    final currentPassType = (attendee['passType'] is int)
        ? attendee['passType'] as int
        : int.tryParse(attendee['passType']?.toString() ?? '1') ?? 1;

    int selectedPassType = currentPassType;
    final nameCtrl = TextEditingController(text: attendee['name'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: attendee['phone'] as String? ?? '');
    final collegeCtrl = TextEditingController(text: attendee['college'] as String? ?? '');
    bool isSaving = false;
    String? dialogError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            margin: const EdgeInsets.only(top: 60),
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.8), width: 1.5),
              boxShadow: AppTheme.neonGlow(opacity: 0.3, blur: 24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.neonOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.badge_outlined, color: AppTheme.neonOrange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MODIFY ATTENDEE PASS',
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pass ID: ${attendee['passId'] ?? "N/A"}',
                              style: GoogleFonts.rajdhani(
                                fontSize: 13,
                                color: AppTheme.cyberAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.metallicMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (dialogError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent, width: 0.8),
                      ),
                      child: Text(
                        dialogError!,
                        style: GoogleFonts.rajdhani(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),

                  // Select Pass Category Title
                  Text(
                    'ASSIGN PASS CATEGORY / TYPE:',
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.metallicSilver,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Option Selector Cards
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AttendeeProfile.passCategoryNames.entries.map((entry) {
                      final type = entry.key;
                      final label = entry.value;
                      final isSelected = selectedPassType == type;
                      final color = categoryColors[type] ?? AppTheme.neonOrange;

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setModalState(() {
                            selectedPassType = type;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.22) : const Color(0xFF140705),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : AppTheme.metallicMuted.withValues(alpha: 0.25),
                              width: isSelected ? 1.6 : 0.8,
                            ),
                            boxShadow: isSelected ? AppTheme.neonGlow(color: color, opacity: 0.35, blur: 8) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.metallicSilver,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, size: 14, color: color),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Editable Name
                  Text(
                    'ATTENDEE NAME',
                    style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.metallicMuted),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF140705),
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.neonOrange, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Editable Phone
                  Text(
                    'PHONE NUMBER',
                    style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.metallicMuted),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF140705),
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.cyberAmber, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Editable College
                  Text(
                    'COLLEGE / INSTITUTION',
                    style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.metallicMuted),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: collegeCtrl,
                    style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF140705),
                      prefixIcon: const Icon(Icons.school_outlined, color: AppTheme.cyberCyan, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Save & Update Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonOrange,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() {
                                isSaving = true;
                                dialogError = null;
                              });

                              final newCategoryName = AttendeeProfile.passCategoryNames[selectedPassType] ?? 'ATTENDEE PASS';
                              final updatedName = nameCtrl.text.trim();
                              final updatedPhone = phoneCtrl.text.trim();
                              final updatedCollege = collegeCtrl.text.trim();
                              final isIitIsm = selectedPassType == 0 ||
                                  updatedCollege.toLowerCase().contains('ism') ||
                                  updatedCollege.toLowerCase().contains('iit (ism)');

                              final updateMap = {
                                'passType': selectedPassType,
                                'passCategory': newCategoryName,
                                'name': updatedName,
                                'phone': updatedPhone,
                                'college': updatedCollege,
                                'isIitIsm': isIitIsm,
                                'lastModified': FieldValue.serverTimestamp(),
                                'lastModifiedByOrganizer': true,
                              };

                              final db = FirestoreConfig.instance;
                              bool success = false;

                              try {
                                await db.collection('users').doc(docId).set(
                                  updateMap,
                                  SetOptions(merge: true),
                                ).timeout(const Duration(seconds: 4));
                                success = true;
                              } catch (e) {
                                debugPrint('Update attendee notice on concetto db: $e');
                              }

                              if (!context.mounted) return;

                              if (success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Updated $updatedName to $newCategoryName!',
                                            style: GoogleFonts.rajdhani(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF140806),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                _fetchAttendees();
                              } else {
                                setModalState(() {
                                  isSaving = false;
                                  dialogError = 'Failed to update in cloud database. Please verify internet connection.';
                                });
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.black),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SAVE & UPDATE PASS IN CLOUD',
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAttendees;
    final totalCount = _attendees.length;
    final nonIitCount = _attendees.where((a) {
      final pt = (a['passType'] is int) ? a['passType'] as int : int.tryParse(a['passType']?.toString() ?? '1') ?? 1;
      return pt != 0;
    }).length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'GUEST PASS DASHBOARD',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Attendees',
            icon: const Icon(Icons.refresh, color: AppTheme.neonOrange),
            onPressed: _fetchAttendees,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar with Live Filter across ANY detail
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF140705),
                hintText: 'Search by Name, Email, Phone, College, Pass ID...',
                hintStyle: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.neonOrange, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.metallicMuted, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.neonOrange.withValues(alpha: 0.35)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
                ),
              ),
            ),
          ),

          // 2. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Non-IIT Guests ($nonIitCount)',
                  isSelected: _selectedCategoryFilter == null,
                  onTap: () => setState(() => _selectedCategoryFilter = null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Type 1: Guest',
                  color: categoryColors[1],
                  isSelected: _selectedCategoryFilter == 1,
                  onTap: () => setState(() => _selectedCategoryFilter = 1),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Type 2: Silver',
                  color: categoryColors[2],
                  isSelected: _selectedCategoryFilter == 2,
                  onTap: () => setState(() => _selectedCategoryFilter = 2),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Type 3: Gold',
                  color: categoryColors[3],
                  isSelected: _selectedCategoryFilter == 3,
                  onTap: () => setState(() => _selectedCategoryFilter = 3),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Type 4: Diamond',
                  color: categoryColors[4],
                  isSelected: _selectedCategoryFilter == 4,
                  onTap: () => setState(() => _selectedCategoryFilter = 4),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Type 5: Diamond+',
                  color: categoryColors[5],
                  isSelected: _selectedCategoryFilter == 5,
                  onTap: () => setState(() => _selectedCategoryFilter = 5),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'All ($totalCount)',
                  isSelected: _selectedCategoryFilter == -1,
                  onTap: () => setState(() => _selectedCategoryFilter = -1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 3. Attendee List / Loading State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonOrange),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined, size: 54, color: AppTheme.metallicMuted.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No attendees match "$_searchQuery"'
                                  : (_errorMessage ?? 'No guest attendees found.'),
                              style: GoogleFonts.rajdhani(
                                fontSize: 16,
                                color: AppTheme.metallicMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () => _searchController.clear(),
                                child: Text(
                                  'CLEAR SEARCH',
                                  style: GoogleFonts.rajdhani(color: AppTheme.cyberAmber, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.neonOrange,
                        onRefresh: _fetchAttendees,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final attendee = filtered[index];
                            return _buildAttendeeCard(attendee);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = color ?? AppTheme.neonOrange;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.22) : const Color(0xFF140705),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.metallicMuted.withValues(alpha: 0.25),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.rajdhani(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.metallicSilver,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendeeCard(Map<String, dynamic> attendee) {
    final name = attendee['name'] as String? ?? 'Unnamed Attendee';
    final email = attendee['email'] as String? ?? 'No email';
    final phone = attendee['phone'] as String? ?? '';
    final college = attendee['college'] as String? ?? 'Visiting Guest';
    final passId = attendee['passId'] as String? ?? 'NO-PASS-ID';
    final passType = (attendee['passType'] is int)
        ? attendee['passType'] as int
        : int.tryParse(attendee['passType']?.toString() ?? '1') ?? 1;
    final categoryTitle = attendee['passCategory'] as String? ??
        AttendeeProfile.passCategoryNames[passType] ??
        'ATTENDEE PASS';
    final scanCount = (attendee['scanCount'] is int)
        ? attendee['scanCount'] as int
        : int.tryParse(attendee['scanCount']?.toString() ?? '0') ?? 0;

    final badgeColor = categoryColors[passType] ?? AppTheme.neonOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF140705),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Pass Badge + Scan Count Indicator
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor, width: 1),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 13, color: badgeColor),
                          const SizedBox(width: 5),
                          Text(
                            categoryTitle,
                            style: GoogleFonts.rajdhani(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scanCount > 0
                        ? const Color(0xFF00E676).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        scanCount > 0 ? Icons.check_circle_outline : Icons.schedule,
                        size: 13,
                        color: scanCount > 0 ? const Color(0xFF00E676) : AppTheme.metallicMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scanCount > 0 ? 'Scanned: $scanCount' : 'Unscanned',
                        style: GoogleFonts.rajdhani(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: scanCount > 0 ? const Color(0xFF00E676) : AppTheme.metallicMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name & Pass ID
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: passId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied Pass ID $passId to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              passId,
                              style: GoogleFonts.rajdhani(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.cyberAmber,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, size: 12, color: AppTheme.cyberAmber),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Edit Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonOrange.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.neonOrange,
                    side: const BorderSide(color: AppTheme.neonOrange, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'EDIT PASS',
                      style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                  onPressed: () => _showEditPassDialog(attendee),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // College
            Row(
              children: [
                const Icon(Icons.school_outlined, size: 14, color: AppTheme.metallicMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    college,
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: AppTheme.metallicSilver,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Phone
            if (phone.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppTheme.metallicMuted),
                  const SizedBox(width: 6),
                  Text(
                    phone,
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: AppTheme.metallicSilver,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Email
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 14, color: AppTheme.metallicMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email,
                    style: GoogleFonts.rajdhani(
                      fontSize: 13,
                      color: AppTheme.metallicMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
