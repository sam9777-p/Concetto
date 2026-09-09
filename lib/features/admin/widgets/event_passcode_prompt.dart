import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/repositories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/event_item.dart';

class EventPasscodePrompt extends ConsumerStatefulWidget {
  final EventItem event;
  final String actionTitle; // 'Edit Event' or 'Delete Event'
  final Function(String passcode, bool isMaster) onAuthorized;

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
    required Function(String passcode, bool isMaster) onAuthorized,
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
  final TextEditingController _passcodeController = TextEditingController();
  bool _obscure = true;
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final entered = _passcodeController.text.trim();
    if (entered.isEmpty) {
      setState(() => _error = 'Please enter the event passcode or master password.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    final firestoreService = ref.read(firestoreServiceProvider);

    // Check if master password
    if (MasterAdminConfig.verify(entered)) {
      Navigator.of(context).pop();
      widget.onAuthorized(entered, true);
      return;
    }

    // Check event passcode
    final isAuthorized = await firestoreService.verifyEventPasscode(widget.event.id, entered);

    if (!mounted) return;

    if (isAuthorized) {
      Navigator.of(context).pop();
      widget.onAuthorized(entered, false);
    } else {
      setState(() {
        _verifying = false;
        _error = 'Incorrect passcode! Please check the confirmation email or ask your club head.';
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
                    'Organized by: ${widget.event.organizerClub}',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.cyberAmber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Enter the event passcode created by the coordinator, or the Master Admin password to proceed.',
              style: GoogleFonts.rajdhani(
                color: AppTheme.metallicSilver,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _passcodeController,
              obscureText: _obscure,
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF140705),
                hintText: 'Event Passcode or Master Key',
                hintStyle: GoogleFonts.rajdhani(color: Colors.white30),
                prefixIcon: const Icon(Icons.password, color: AppTheme.neonOrange, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.neonOrange.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.neonOrange, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _verify(),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.rajdhani(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
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
                            'CONFIRM',
                            style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
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
