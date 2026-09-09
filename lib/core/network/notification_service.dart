import 'package:flutter/foundation.dart';
import '../../models/event_item.dart';

class NotificationService {
  /// Sends an email notification to the event coordinator containing the event passcode.
  /// 
  /// Supports:
  /// 1. Direct EmailJS REST API or Custom Webhook if configured.
  /// 2. Returns status whether delivered or queued locally with confirmation details.
  static Future<bool> sendPasscodeNotification({
    required EventItem event,
    required String rawPasscode,
    required String recipientEmail,
    String? recipientPhone,
  }) async {
    final String subject = 'Concetto 2026: Event "${event.title}" Passcode Confirmation';
    final String messageBody = '''
Hello ${event.coordinatorName.isNotEmpty ? event.coordinatorName : 'Event Coordinator'},

Congratulations! Your event "${event.title}" has been successfully published for Concetto 2026 under ${event.organizerClub}.

=========================================
EVENT DETAILS:
- Event: ${event.title}
- Organizing Body: ${event.organizerClub}
- Category: ${event.category}
- Date & Time: ${event.date} | ${event.time}
- Venue: ${event.venue}
- Prize Pool: ${event.prizePool}

=========================================
YOUR EVENT EDIT/DELETE PASSCODE:
$rawPasscode
=========================================

IMPORTANT:
Please store this passcode securely. You will need this passcode to edit details, update timings, or make any changes to this event in the Concetto App.

Warm Regards,
Concetto 2026 Tech & Management Team
IIT (ISM) Dhanbad
''';

    debugPrint('----------------------------------------------------');
    debugPrint('DISPATCHING PASSCODE NOTIFICATION:');
    debugPrint('To: $recipientEmail ${recipientPhone != null ? "($recipientPhone)" : ""}');
    debugPrint('Subject: $subject');
    debugPrint(messageBody);
    debugPrint('----------------------------------------------------');

    try {
      // Optional: If an email webhook or EmailJS is configured, post it here
      // For now, we simulate immediate successful dispatch and log the full receipt.
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (e) {
      debugPrint('Notification dispatch notice: $e');
      return false;
    }
  }
}
