import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class PassScannerScreen extends StatefulWidget {
  const PassScannerScreen({super.key});

  @override
  State<PassScannerScreen> createState() => _PassScannerScreenState();
}

class _PassScannerScreenState extends State<PassScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final TextEditingController _manualIdController = TextEditingController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _statusMessage;
  bool _isError = false;

  @override
  void dispose() {
    _manualIdController.dispose();
    _scannerController.dispose();
    super.dispose();
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
    HapticFeedback.mediumImpact();
    await _lookupAndVerifyPass(rawValue);
  }

  Future<void> _lookupAndVerifyPass(String rawInput) async {
    final cleanInput = rawInput.trim();
    if (cleanInput.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Verifying Pass...';
      _isError = false;
    });

    String passIdToSearch = cleanInput;
    String? userIdHint;

    // Check if payload is JSON formatted: {"uid":"...","passId":"..."}
    if (cleanInput.startsWith('{') && cleanInput.endsWith('}')) {
      try {
        final decoded = jsonDecode(cleanInput);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('passId')) {
            passIdToSearch = decoded['passId'].toString();
          }
          if (decoded.containsKey('uid')) {
            userIdHint = decoded['uid'].toString();
          }
        }
      } catch (_) {}
    }

    Map<String, dynamic>? passData;
    String resolvedPassId = passIdToSearch;
    String resolvedUserId = userIdHint ?? '';

    try {
      // 1. Check in 'passes' collection
      final passDoc = await FirebaseFirestore.instance.collection('passes').doc(passIdToSearch).get();
      if (passDoc.exists && passDoc.data() != null) {
        passData = passDoc.data()!;
        resolvedUserId = passData['userId']?.toString() ?? resolvedUserId;
      }

      // 2. If not found in 'passes', check 'users' by UID
      if (passData == null && userIdHint != null && userIdHint.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userIdHint).get();
        if (userDoc.exists && userDoc.data() != null) {
          passData = userDoc.data()!;
          resolvedPassId = passData['passId']?.toString() ?? resolvedPassId;
          resolvedUserId = userDoc.id;
        }
      }

      // 3. If still not found, query 'users' collection where passId == passIdToSearch
      if (passData == null) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('passId', isEqualTo: passIdToSearch)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          passData = query.docs.first.data();
          resolvedPassId = passData['passId']?.toString() ?? resolvedPassId;
          resolvedUserId = passData['uid']?.toString() ?? query.docs.first.id;
        }
      }

      // 4. Fallback check case-insensitively or formatted query
      if (passData == null && !passIdToSearch.startsWith('CON-')) {
        final formatted = 'CON-26-${passIdToSearch.toUpperCase()}';
        final query = await FirebaseFirestore.instance
            .collection('passes')
            .where('passId', isEqualTo: formatted)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          passData = query.docs.first.data();
          resolvedPassId = formatted;
          resolvedUserId = passData['userId']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error searching pass: $e');
    }

    if (!mounted) return;

    if (passData != null) {
      final name = passData['name']?.toString() ?? 'Attendee';
      final email = passData['email']?.toString() ?? 'N/A';
      final phone = passData['phone']?.toString() ?? 'N/A';
      final college = passData['college']?.toString() ?? 'N/A';
      final passTypeRaw = passData['passType'];
      int passType = 1;
      if (passTypeRaw is int) {
        passType = passTypeRaw;
      } else if (passTypeRaw != null) {
        passType = int.tryParse(passTypeRaw.toString()) ?? 1;
      }
      final passCategoryTitle = AttendeeProfile.passCategoryNames[passType] ?? 'ATTENDEE PASS';

      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });

      _showAdmissionDialog(
        userId: resolvedUserId,
        passId: resolvedPassId,
        name: name,
        email: email,
        phone: phone,
        college: college,
        passType: passType,
        passCategory: passCategoryTitle,
      );
    } else {
      setState(() {
        _isProcessing = false;
        _isError = true;
        _statusMessage = 'Pass "$passIdToSearch" not found in database.';
      });
      HapticFeedback.vibrate();
    }
  }

  void _showAdmissionDialog({
    required String userId,
    required String passId,
    required String name,
    required String email,
    required String phone,
    required String college,
    required int passType,
    required String passCategory,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final badgeColor = _getBadgeColor(passType);
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgContext) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: const Color(0xFF140604),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: badgeColor, width: 1.5),
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with badge
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
                            '$passCategory [TYPE $passType]',
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

                // Details Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D0907),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(Icons.school, 'College', college),
                      const Divider(color: Colors.white10, height: 16),
                      _buildDetailRow(Icons.email, 'Email', email),
                      const Divider(color: Colors.white10, height: 16),
                      _buildDetailRow(Icons.phone, 'Phone', phone),
                      const Divider(color: Colors.white10, height: 16),
                      _buildDetailRow(Icons.qr_code, 'Pass ID', passId, highlight: true, color: badgeColor),
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
                              // Write to Firestore collection 'scan_logs'
                              await FirebaseFirestore.instance.collection('scan_logs').add({
                                'userId': userId,
                                'passId': passId,
                                'name': name,
                                'email': email,
                                'phone': phone,
                                'college': college,
                                'passType': passType,
                                'passCategory': passCategory,
                                'logTime': FieldValue.serverTimestamp(),
                                'scannedBy': 'Organizer Command Hub',
                              });

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
          width: 60,
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
                          hintText: 'e.g. CON-26-A1B2C3',
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
