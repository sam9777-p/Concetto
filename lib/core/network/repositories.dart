import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_item.dart';
import '../../models/core_team_member.dart';
import '../../models/announcement_item.dart';
import 'mock_data.dart';

// --- Master Admin Credentials ---
class MasterAdminConfig {
  /// Primary master password for all club heads and festival conveners
  static const String masterPassword = 'concetto@admin2026';
  
  /// Alternative convenient master password
  static const String fallbackMasterPassword = 'concetto2026';

  static bool verify(String entered) {
    final clean = entered.trim();
    return clean == masterPassword || clean == fallbackMasterPassword;
  }
}

// --- Firestore Configuration ---

class FirestoreConfig {
  /// The Firestore database ID to use.
  /// Set to 'concetto' to connect to the dedicated named database.
  static String databaseId = 'concetto';

  /// Returns the configured FirebaseFirestore instance safely.
  static FirebaseFirestore get instance {
    try {
      if (databaseId.isNotEmpty && databaseId != '(default)' && Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: databaseId,
        );
      }
    } catch (e) {
      debugPrint('FirestoreConfig notice for "$databaseId": $e. Falling back to default instance.');
    }
    return FirebaseFirestore.instance;
  }
}

// --- Service ---

class FirestoreService {
  final FirebaseFirestore? _customDb;

  FirestoreService({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore get _db => _customDb ?? FirestoreConfig.instance;

  /// Hashes raw passcodes with SHA-256 for secure comparison
  static String hashPasscode(String rawPasscode) {
    if (rawPasscode.trim().isEmpty) return '';
    final bytes = utf8.encode(rawPasscode.trim());
    return sha256.convert(bytes).toString();
  }

  /// Default hash for mock events
  static String get defaultPasscodeHash => hashPasscode('concetto2026');

  // --- Read Events ---

  Future<List<EventItem>> getEvents() async {
    try {
      final snapshot = await _db.collection('events').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => EventItem.fromJson(doc.data(), doc.id))
            .toList();
      }
      return MockData.events;
    } catch (e) {
      debugPrint('Firestore getEvents notice: $e. Falling back to local events.');
      return MockData.events;
    }
  }

  // --- Verify Passcode ---

  Future<bool> verifyEventPasscode(String eventId, String rawPasscode) async {
    if (MasterAdminConfig.verify(rawPasscode)) {
      return true;
    }

    final enteredHash = hashPasscode(rawPasscode);

    try {
      final doc = await _db.collection('events').doc(eventId).get();
      if (doc.exists && doc.data() != null) {
        final storedHash = doc.data()!['passwordHash'] as String?;
        if (storedHash != null && storedHash.isNotEmpty) {
          return storedHash == enteredHash;
        }
      }
    } catch (e) {
      debugPrint('Firestore verify notice: $e');
    }

    // Fallback check against local mock data
    final localMatch = MockData.events.where((e) => e.id == eventId);
    if (localMatch.isNotEmpty) {
      final local = localMatch.first;
      if (local.passwordHash.isNotEmpty) {
        return local.passwordHash == enteredHash;
      }
      // If mock event didn't have explicit hash, check against default
      return enteredHash == defaultPasscodeHash;
    }

    return false;
  }

  // --- Create Event ---

  Future<EventItem> createEvent(EventItem event, String rawPasscode) async {
    final String generatedId = event.id.isNotEmpty
        ? event.id
        : 'event_${DateTime.now().millisecondsSinceEpoch}';

    final String finalHash = rawPasscode.isNotEmpty
        ? hashPasscode(rawPasscode)
        : defaultPasscodeHash;

    final updatedEvent = event.copyWith(
      id: generatedId,
      passwordHash: finalHash,
      updatedAt: DateTime.now().toIso8601String(),
    );

    try {
      await _db.collection('events').doc(generatedId).set(updatedEvent.toJson());
      debugPrint('Event "${updatedEvent.title}" written to Firestore.');
    } catch (e) {
      debugPrint('Firestore createEvent notice: $e. Persisting in local session.');
    }

    // Sync with local in-memory MockData
    final existingIndex = MockData.events.indexWhere((e) => e.id == generatedId);
    if (existingIndex >= 0) {
      MockData.events[existingIndex] = updatedEvent;
    } else {
      MockData.events.insert(0, updatedEvent);
    }

    return updatedEvent;
  }

  // --- Update Event ---

  Future<EventItem> updateEvent(
    EventItem event,
    String rawPasscode, {
    bool isMasterAdmin = false,
  }) async {
    // Authorization check
    if (!isMasterAdmin) {
      final isAuthorized = await verifyEventPasscode(event.id, rawPasscode);
      if (!isAuthorized) {
        throw Exception('Incorrect passcode! You are not authorized to edit "${event.title}".');
      }
    }

    final String finalHash = rawPasscode.isNotEmpty
        ? hashPasscode(rawPasscode)
        : (event.passwordHash.isNotEmpty ? event.passwordHash : defaultPasscodeHash);

    final updatedEvent = event.copyWith(
      passwordHash: finalHash,
      updatedAt: DateTime.now().toIso8601String(),
    );

    try {
      await _db.collection('events').doc(event.id).set(
            updatedEvent.toJson(),
            SetOptions(merge: true),
          );
      debugPrint('Event "${updatedEvent.title}" updated in Firestore.');
    } catch (e) {
      debugPrint('Firestore updateEvent notice: $e. Persisting in local session.');
    }

    // Sync with local MockData
    final existingIndex = MockData.events.indexWhere((e) => e.id == event.id);
    if (existingIndex >= 0) {
      MockData.events[existingIndex] = updatedEvent;
    } else {
      MockData.events.insert(0, updatedEvent);
    }

    return updatedEvent;
  }

  // --- Delete Event ---

  Future<bool> deleteEvent(
    String eventId,
    String rawPasscode, {
    bool isMasterAdmin = false,
  }) async {
    if (!isMasterAdmin) {
      final isAuthorized = await verifyEventPasscode(eventId, rawPasscode);
      if (!isAuthorized) {
        throw Exception('Incorrect passcode! You are not authorized to delete this event.');
      }
    }

    try {
      await _db.collection('events').doc(eventId).delete();
      debugPrint('Event "$eventId" deleted from Firestore.');
    } catch (e) {
      debugPrint('Firestore deleteEvent notice: $e');
    }

    MockData.events.removeWhere((e) => e.id == eventId);
    return true;
  }

  // --- Seed Mock Data to Firestore ---

  Future<int> seedMockEventsToFirestore() async {
    int count = 0;
    final defaultHash = hashPasscode('concetto2026');

    for (final event in MockData.events) {
      try {
        final preparedEvent = event.copyWith(
          passwordHash: event.passwordHash.isNotEmpty ? event.passwordHash : defaultHash,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _db.collection('events').doc(event.id).set(preparedEvent.toJson());
        count++;
      } catch (e) {
        debugPrint('Error seeding event ${event.id}: $e');
      }
    }
    return count;
  }

  Future<Map<String, int>> seedAllDataToFirestore() async {
    final eventsCount = await seedMockEventsToFirestore();
    int announcementsCount = 0;
    int teamCount = 0;

    for (final ann in MockData.announcements) {
      try {
        await _db.collection('announcements').doc(ann.id).set(ann.toJson());
        announcementsCount++;
      } catch (e) {
        debugPrint('Error seeding announcement ${ann.id}: $e');
      }
    }

    for (final member in MockData.team) {
      try {
        final docId = 'team_${member.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
        await _db.collection('team').doc(docId).set(member.toJson());
        teamCount++;
      } catch (e) {
        debugPrint('Error seeding team member ${member.name}: $e');
      }
    }

    return {
      'events': eventsCount,
      'announcements': announcementsCount,
      'team': teamCount,
    };
  }

  // --- Team & Announcements ---

  Future<List<CoreTeamMember>> getTeam() async {
    try {
      final snapshot = await _db.collection('team').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => CoreTeamMember.fromJson(doc.data()))
            .toList();
      }
      return MockData.team;
    } catch (e) {
      debugPrint('Firestore getTeam notice: $e. Falling back to mock data.');
      return MockData.team;
    }
  }

  Future<List<AnnouncementItem>> getAnnouncements() async {
    try {
      final snapshot = await _db.collection('announcements').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => AnnouncementItem.fromJson(doc.data(), doc.id))
            .toList();
      }
      return MockData.announcements;
    } catch (e) {
      debugPrint('Firestore getAnnouncements notice: $e. Falling back to mock data.');
      return MockData.announcements;
    }
  }

  // --- Registrations ---

  Future<void> saveRegistration(Map<String, dynamic> regData) async {
    try {
      await _db.collection('registrations').add(regData);
      debugPrint('Registration for "${regData['eventTitle']}" saved to Firestore.');
    } catch (e) {
      debugPrint('Firestore registration notice: $e');
    }
  }
}

// --- Providers ---

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final eventsProvider = FutureProvider<List<EventItem>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getEvents();
});

final teamProvider = FutureProvider<List<CoreTeamMember>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTeam();
});

final announcementsProvider = FutureProvider<List<AnnouncementItem>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getAnnouncements();
});
