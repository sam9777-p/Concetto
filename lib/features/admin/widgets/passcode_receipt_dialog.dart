import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/event_item.dart';

class PasscodeReceiptDialog extends StatelessWidget {
  final EventItem event;
  final String rawPasscode;
  final bool emailSent;
  final VoidCallback onDismiss;

  const PasscodeReceiptDialog({
    super.key,
    required this.event,
    required this.rawPasscode,
    required this.emailSent,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required EventItem event,
    required String rawPasscode,
    required bool emailSent,
    required VoidCallback onDismiss,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasscodeReceiptDialog(
        event: event,
        rawPasscode: rawPasscode,
        emailSent: emailSent,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordinatorEmail = event.coordinatorEmail.isNotEmpty
        ? event.coordinatorEmail
        : 'Coordinator Contact';

    return Dialog(
      backgroundColor: AppTheme.scaffoldBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.neonEmerald, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.darkCardGradient,
          boxShadow: AppTheme.neonGlow(color: AppTheme.neonEmerald, opacity: 0.25, blur: 24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neonEmerald.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.neonEmerald, width: 1.5),
              ),
              child: const Icon(Icons.check_circle_outline, color: AppTheme.neonEmerald, size: 36),
            ),
            const SizedBox(height: 16),

            Text(
              'EVENT PUBLISHED!',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              event.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.cyberAmber,
              ),
            ),
            Text(
              'Organizing Club: ${event.organizerClub}',
              style: GoogleFonts.rajdhani(
                fontSize: 13,
                color: AppTheme.metallicMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Passcode Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF140806),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.neonOrange, width: 1.2),
                boxShadow: AppTheme.neonGlow(color: AppTheme.neonOrange, opacity: 0.2, blur: 10),
              ),
              child: Column(
                children: [
                  Text(
                    'EVENT PASSCODE',
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.metallicMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    rawPasscode,
                    style: GoogleFonts.orbitron(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: AppTheme.neonOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('COPY PASSCODE'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: rawPasscode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passcode copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(
                    emailSent ? Icons.mark_email_read_outlined : Icons.email_outlined,
                    color: emailSent ? AppTheme.neonEmerald : AppTheme.cyberAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      emailSent
                          ? 'Confirmation & passcode sent to:\n$coordinatorEmail'
                          : 'Notification queued for:\n$coordinatorEmail',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        color: AppTheme.metallicSilver,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'IMPORTANT: Save this passcode! It is required to make any future edits or remove this event.',
              textAlign: TextAlign.center,
              style: GoogleFonts.rajdhani(
                fontSize: 12,
                color: Colors.redAccent.shade100,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonEmerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'DONE & RETURN TO HUB',
                  style: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
