import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/repositories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/event_item.dart';

class EventPasscodePrompt extends ConsumerStatefulWidget {
  final EventItem event;
  final String actionTitle; // 'Edit Event' or 'Delete Event'
  final Function(String masterPass, String secondaryPass, bool isDevOverride) onAuthorized;

  const EventPasscodePrompt({
    super.key,
    required this.event,
    required this.actionTitle,
    required this.onAuthorized,
  });

  static Future<void> show(
    BuildContext context, {
    required EventItem event,
    required String actionTitle,
    required Function(String masterPass, String secondaryPass, bool isDevOverride) onAuthorized,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EventPasscodePrompt(
        event: event,
        actionTitle: actionTitle,
        onAuthorized: onAuthorized,
      ),
    );
  }

  @override
  ConsumerState<EventPasscodePrompt> createState() => _EventPasscodePromptState();
}

class _EventPasscodePromptState extends ConsumerState<EventPasscodePrompt> {
  final TextEditingController _masterController = TextEditingController();
  final TextEditingController _secondaryController = TextEditingController();
  bool _obscureMaster = true;
  bool _obscureSecondary = true;
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _masterController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final masterEntered = _masterController.text.trim();
    final secondaryEntered = _secondaryController.text.trim();

    if (masterEntered.isEmpty || secondaryEntered.isEmpty) {
      setState(() => _error = 'Both Master Password and Event Passkey (or Dev Key) are required.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    final firestoreService = ref.read(firestoreServiceProvider);

    // 1. Verify Master General Password
    if (!MasterAdminConfig.verifyMaster(masterEntered)) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Invalid Master General Password. Check organizer credentials.';
      });
      return;
    }

    // 2. Check if Secondary is Developer Password Override
    final isDevOverride = MasterAdminConfig.verifyDev(secondaryEntered);
    if (isDevOverride) {
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAuthorized(masterEntered, secondaryEntered, true);
      return;
    }

    // 3. Verify Specific Event Password
    final isSpecificValid = await firestoreService.verifyEventSpecificPasscode(widget.event.id, secondaryEntered);

    if (!mounted) return;

    if (isSpecificValid) {
      Navigator.of(context).pop();
      widget.onAuthorized(masterEntered, secondaryEntered, false);
    } else {
      setState(() {
        _verifying = false;
        _error = 'Incorrect Specific Event Passkey! Enter the dedicated password for "${widget.event.title}" or the Developer override password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDelete = widget.actionTitle.toLowerCase().contains('delete');

    return Dialog(
      backgroundColor: AppTheme.scaffoldBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDelete ? Colors.redAccent : AppTheme.neonOrange,
          width: 1.2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.darkCardGradient,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Icon(
                  isDelete ? Icons.delete_forever : Icons.key_rounded,
                  color: isDelete ? Colors.redAccent : AppTheme.neonOrange,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.actionTitle.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Event Info Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF160907),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isDelete ? Icons.delete_forever : Icons.verified_user_outlined,
                    color: isDelete ? Colors.redAccent : AppTheme.neonOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.actionTitle.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Event Info Pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF160907),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Club: ${widget.event.organizerClub}',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.cyberAmber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Security Policy: Requires Master General Password PLUS either this Event\'s Specific Passkey or Developer Override Key.',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.metallicSilver,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),

              // 1. Master General Password Input
              Text(
                '1. MASTER GENERAL PASSWORD *',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.neonOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _masterController,
                obscureText: _obscureMaster,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF140705),
                  hintText: 'Enter Master Password',
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                  prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.neonOrange, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureMaster ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 18),
                    onPressed: () => setState(() => _obscureMaster = !_obscureMaster),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Specific Event Passkey / Developer Override
              Text(
                '2. SPECIFIC EVENT PASSKEY OR DEV KEY *',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.cyberAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _secondaryController,
                obscureText: _obscureSecondary,
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF140705),
                  hintText: 'Event Passkey (e.g. c26_...) or Dev Key',
                  hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                  prefixIcon: const Icon(Icons.key, color: AppTheme.cyberAmber, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureSecondary ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 18),
                    onPressed: () => setState(() => _obscureSecondary = !_obscureSecondary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.cyberAmber.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.cyberAmber, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _verify(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.rajdhani(color: AppTheme.metallicMuted, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDelete ? Colors.redAccent : AppTheme.neonOrange,
                        foregroundColor: isDelete ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _verifying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'VERIFY & PROCEED',
                              style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
