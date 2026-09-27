import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/network/repositories.dart';

/// Exports event registration data as a CSV file (universally compatible with Excel).
/// Follows Unstop-compatible column format: Team Name, Member Name, Email, Phone, College, Role
class RegistrationExporter {
  /// Downloads all registrations for a given eventId and exports them as CSV
  static Future<String> exportToExcel({
    required String eventId,
    required String eventTitle,
  }) async {
    final db = FirestoreConfig.instance;

    final snapshot = await db
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No registrations found for this event.');
    }

    // Build CSV content with Unstop-compatible headers
    final buffer = StringBuffer();
    buffer.writeln(
        'Team Name,Member Name,Email,Phone,College/Institute,Role,Registration Date,Status');

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final teamName = _csvEscape(data['teamName'] ?? 'Individual');
      final status = data['status'] ?? 'CONFIRMED';
      final regDate = data['registeredAtIso'] ?? '';
      final members = data['members'] as List<dynamic>? ?? [];

      if (members.isEmpty) {
        // Legacy individual registration (fallback)
        buffer.writeln('$teamName,,,,,Leader,$regDate,$status');
      } else {
        for (final member in members) {
          if (member is Map) {
            final name = _csvEscape(member['name'] ?? '');
            final email = _csvEscape(member['email'] ?? '');
            final phone = _csvEscape(member['phone'] ?? '');
            final college = _csvEscape(member['college'] ?? '');
            final role =
                (member['isLeader'] == true) ? 'Team Leader' : 'Member';
            buffer.writeln(
                '$teamName,$name,$email,$phone,$college,$role,$regDate,$status');
          }
        }
      }
    }

    // Write to temporary file
    final dir = await getTemporaryDirectory();
    final sanitizedTitle =
        eventTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    final fileName =
        'concetto26_${sanitizedTitle}_registrations_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  /// Shares the exported CSV file via the system share sheet
  static Future<void> shareExport({
    required String eventId,
    required String eventTitle,
  }) async {
    final filePath =
        await exportToExcel(eventId: eventId, eventTitle: eventTitle);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Concetto\'26 — $eventTitle Registrations',
        text:
            'Event registrations for $eventTitle — Concetto\'26 Centenary Edition',
      ),
    );
  }

  /// Returns the total count of registered teams for a given event
  static Future<int> getRegistrationCount(String eventId) async {
    try {
      final db = FirestoreConfig.instance;
      final snapshot = await db
          .collection('events')
          .doc(eventId)
          .collection('registrations')
          .get()
          .timeout(const Duration(seconds: 4));
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Registration count error: $e');
      return 0;
    }
  }

  /// Escapes a CSV field value (wraps in quotes if it contains commas, quotes, or newlines)
  static String _csvEscape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
