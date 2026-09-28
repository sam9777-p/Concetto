import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/repositories.dart';
import '../../../core/theme/app_theme.dart';

class PassScannerScreen extends StatefulWidget {
  const PassScannerScreen({super.key});

  @override
  State<PassScannerScreen> createState() => _PassScannerScreenState();
}

class _PassScannerScreenState extends State<PassScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final TextEditingController _manualIdController = TextEditingController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _statusMessage;
  bool _isError = false;
  String? _lastScannedCode;
  DateTime? _lastScannedTime;


  @override
  void dispose() {
    _manualIdController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _resetScannerForNextPass() {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _statusMessage = null;
      _isError = false;
      _manualIdController.clear();
    });
  }

  String _extractPhone(Map<String, dynamic> data) {
    for (final key in [
      'phone',
      'phoneNumber',
      'phone_number',
      'mobile',
      'contact',
      'contactNumber',
      'mobileNumber',
      'userPhone',
    ]) {
      final val = data[key]?.toString().trim();
      if (val != null && val.isNotEmpty && val != 'null' && val != 'N/A') {
        return val;
      }
    }
    return '';
  }

  Color _getBadgeColor(int passType) {
    switch (passType) {
      case 0:
        return const Color(0xFF00E676); // Student Pass (Emerald Green)
      case 1:
        return const Color(0xFFFFB300); // Guest Pass (Amber)
      case 2:
        return const Color(0xFFCFD8DC); // Silver Pass (Store page)
      case 3:
        return const Color(0xFFFFB300); // Gold Pass (Store page)
      case 4:
        return const Color(0xFF00E5FF); // Diamond Pass (Store page)
      case 5:
        return const Color(0xFFFF4081); // Diamond+ Merch Pass (Store page)
      default:
        return const Color(0xFF00E676);
    }
  }

  Future<void> _handleBarcodeScanned(String rawValue) async {
    if (_isProcessing) return;

    final now = DateTime.now();
    if (_lastScannedCode == rawValue && _lastScannedTime != null) {
      if (now.difference(_lastScannedTime!).inMilliseconds < 2500) {
        return;
      }
    }

    _lastScannedCode = rawValue;
    _lastScannedTime = now;
    HapticFeedback.mediumImpact();
    await _lookupAndVerifyPass(rawValue);
  }

  Future<void> _lookupAndVerifyPass(String rawValue) async {
    if (_isProcessing) return;

    final passIdToSearch = rawValue.trim();

    if (passIdToSearch.isEmpty) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Please enter a valid Pass ID';
          _isError = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'VERIFYING PASS...';
        _isError = false;
      });
    }

    try {
      final db = FirestoreConfig.instance;
      final query = await db
          .collection('users')
          .where('passId', isEqualTo: passIdToSearch)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Pass not found');
      }

      final userDoc = query.docs.first;
      final userId = userDoc.id;
      final data = userDoc.data();

      // Firebase Auth UID must be the Firestore document ID.
      // If a malformed/legacy document is encountered, reject it.
      final storedUid = data['uid']?.toString().trim();
      if (userId.isEmpty ||
          userId.startsWith('CON-') ||
          (storedUid != null && storedUid.isNotEmpty && storedUid != userId)) {
        throw Exception('Invalid user record');
      }

      final name = data['name']?.toString().trim() ?? '';
      final email = data['email']?.toString().trim() ?? '';
      final phone = _extractPhone(data);
      final college = data['college']?.toString().trim() ?? '';

      int passType = 0;
      final rawPassType = data['passType'];
      if (rawPassType is int) {
        passType = rawPassType;
      } else if (rawPassType != null) {
        passType = int.tryParse(rawPassType.toString()) ?? 0;
      }

      String passCategory = data['passCategory']?.toString().trim() ?? '';
      if (passCategory.isEmpty) {
        const categories = {
          0: 'Student Pass',
          1: 'Guest Pass',
          2: 'Silver Pass',
          3: 'Gold Pass',
          4: 'Diamond Pass',
          5: 'Diamond+ Pass',
        };
        passCategory = categories[passType] ?? 'Student Pass';
      }

      int scanCount = 0;
      final rawScanCount = data['scanCount'];
      if (rawScanCount is int) {
        scanCount = rawScanCount;
      } else if (rawScanCount is num) {
        scanCount = rawScanCount.toInt();
      } else if (rawScanCount != null) {
        scanCount = int.tryParse(rawScanCount.toString()) ?? 0;
      }

      final storedPassId = data['passId']?.toString().trim() ?? '';
      if (storedPassId.isEmpty || storedPassId != passIdToSearch) {
        throw Exception('Invalid pass record');
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'PASS VERIFIED';
          _isError = false;
        });
      }

      await _showAdmissionDialog(
        userId: userId,
        passId: storedPassId,
        scanCount: scanCount,
        name: name.isNotEmpty ? name : 'Unnamed',
        email: email,
        phone: phone,
        college: college,
        passType: passType,
        passCategory: passCategory,
      );
    } on FirebaseException catch (e) {
      debugPrint('Pass lookup failed: ${e.code}: ${e.message}');

      if (mounted) {
        setState(() {
          _statusMessage = e.code == 'permission-denied'
              ? 'Permission denied'
              : 'Pass not found';
          _isError = true;
        });
      }
    } catch (e) {
      debugPrint('Pass lookup failed: $e');

      if (mounted) {
        setState(() {
          _statusMessage = 'Invalid or unregistered Pass ID';
          _isError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showAdmissionDialog({
    required String userId,
    required String passId,
    required int scanCount,
    required String name,
    required String email,
    required String phone,
    required String college,
    required int passType,
    required String passCategory,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final badgeColor = _getBadgeColor(passType);
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: const Color(0xFF140604),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: badgeColor, width: 1.5),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge (No TYPE text)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: badgeColor),
                          const SizedBox(width: 6),
                          Text(
                            passCategory.toUpperCase(),
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: isSubmitting ? null : () => Navigator.pop(dlgContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Attendee Name
                Text(
                  name,
                  style: GoogleFonts.rajdhani(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Details Card: Phone Number, Pass Category, Pass ID, Scanned Earlier, Email, College
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D0907),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.verified_outlined, 'Category', passCategory, highlight: true, color: badgeColor),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDetailRow(Icons.qr_code, 'Pass ID', passId, highlight: true, color: badgeColor),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDetailRow(
                        Icons.history,
                        'Scanned',
                        scanCount == 0
                            ? '0 times (First Entry)'
                            : '$scanCount ${scanCount == 1 ? "time" : "times"} earlier',
                        highlight: scanCount > 0,
                        color: scanCount > 0 ? Colors.amber : const Color(0xFF00E676),
                      ),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDetailRow(Icons.phone_android, 'Phone', phone.isNotEmpty && phone != 'N/A' ? phone : 'Not Provided'),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDetailRow(Icons.email_outlined, 'Email', email.isNotEmpty && email != 'N/A' ? email : 'Not Provided'),
                      const Divider(color: Colors.white10, height: 14),
                      _buildDetailRow(Icons.school_outlined, 'College', college.isNotEmpty && college != 'N/A' ? college : 'Not Provided'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // OK / VALIDATE ENTRY Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badgeColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setDlgState(() => isSubmitting = true);
                            try {
                              final effectivePhone = phone.isNotEmpty && phone != 'N/A' ? phone : 'Not Provided';
                              final logData = {
                                'userId': userId,
                                'passId': passId,
                                'name': name,
                                'email': email,
                                'phone': effectivePhone,
                                'college': college,
                                'passCategory': passCategory,
                                'scanNumber': scanCount + 1,
                                'scannedEarlier': scanCount,
                                'logTime': FieldValue.serverTimestamp(),
                                'logTimeIso': DateTime.now().toIso8601String(),
                                'scannedBy': 'Organizer Command Hub',
                              };

                              final userUpdateData = {
                                'scanCount': FieldValue.increment(1),
                                'lastScannedAt': FieldValue.serverTimestamp(),
                                'lastScannedAtIso': DateTime.now().toIso8601String(),
                                'lastScannedBy': 'Organizer Command Hub',
                              };

                              try {
                                final db = FirestoreConfig.instance;
                                // Perform BOTH writes simultaneously in the 'concetto' database:
                                // 1. Continuous audit log of every scan in scan_logs collection
                                // 2. Increment scanCount on the existing users/{uid} document only
                                final futures = <Future>[
                                  db.collection('scan_logs').add(logData),
                                ];

                                if (userId.isNotEmpty) {
                                  futures.add(
                                    db.collection('users').doc(userId).update(
                                          userUpdateData,
                                        ),
                                  );
                                }

                                await Future.wait(futures).timeout(const Duration(seconds: 4));
                                debugPrint('Scan logged and users/$userId updated successfully');
                              } catch (e) {
                                debugPrint('Notice logging scan in concetto database: $e');
                              }

                              if (dlgContext.mounted) {
                                Navigator.pop(dlgContext);
                              }

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Entry Logged for $name ($passCategory)!',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF140604),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } catch (e) {
                              setDlgState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Log failed: $e')),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'OK • VALIDATE ENTRY',
                                style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool highlight = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: highlight ? (color ?? AppTheme.neonOrange) : Colors.white38),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.rajdhani(
              color: highlight ? (color ?? Colors.white) : Colors.white,
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'PASS SCANNER',
          style: GoogleFonts.orbitron(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF140604),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Reset Scanner',
            onPressed: _resetScannerForNextPass,
          ),
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : Colors.white70,
            ),
            tooltip: 'Toggle Flash',
            onPressed: () async {
              await _scannerController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white70),
            tooltip: 'Switch Camera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Camera Viewfinder with Overlay
          Expanded(
            flex: 6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final val = barcode.rawValue;
                      if (val != null && val.isNotEmpty) {
                        _handleBarcodeScanned(val);
                        break;
                      }
                    }
                  },
                ),

                // Futuristic Viewfinder Reticle
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor.withValues(alpha: 0.8), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Scanning line animation
                      AnimatedPositioned(
                        duration: const Duration(seconds: 2),
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Message Overlay
                if (_statusMessage != null)
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_isError ? Colors.red : primaryColor).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusMessage!,
                        style: GoogleFonts.rajdhani(
                          color: _isError ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.neonOrange),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Manual Pass ID Lookup Bar
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFF140604),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OR ENTER PASS IDENTIFIER MANUALLY',
                  style: GoogleFonts.rajdhani(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualIdController,
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter Pass ID',
                          hintStyle: GoogleFonts.orbitron(color: Colors.white24, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF1E0907),
                          prefixIcon: Icon(Icons.tag, color: primaryColor, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        onSubmitted: (val) => _lookupAndVerifyPass(val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _lookupAndVerifyPass(_manualIdController.text),
                        child: Text(
                          'SEARCH',
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
