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
import 'mongo_service.dart';

// --- Master & Developer Access Config ---
class MasterAdminConfig {
  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  // One-way cryptographic SHA-256 hashes only. Strictly case-sensitive, no alternatives accepted.
  // Master Password: 'concetto@master2026'
  static const String _masterHash =
      'e64575142425195ea6195639cc0cacb60173d19ffacfa535a6fd79401f1d0c2d';

  // Developer Password: 'COncetto2026@56932!'
  static const String _devHash =
      '40a0702c53def4d439c9aea8dc0de47a289d5382a51b4e120f1f68ae3fdb48bb';

  /// Verifies Master General Password strictly (case-sensitive, exact match)
  static bool verifyMaster(String entered) {
    if (entered.isEmpty) return false;
    return _sha256(entered) == _masterHash;
  }

  /// Legacy alias
  static bool verify(String entered) => verifyMaster(entered);

  /// Verifies Developer Password strictly (case-sensitive, exact match)
  static bool verifyDev(String entered) {
    if (entered.isEmpty) return false;
    return _sha256(entered) == _devHash;
  }

  /// Verifies login to Organizer Portal (accepts Master or Developer)
  static bool verifyOrganizerLogin(String entered) {
    return verifyMaster(entered) || verifyDev(entered);
  }

  /// Verifies credentials required to add a new event (MUST have BOTH Master + Developer)
  static bool verifyAddEvent({
    required String masterEntered,
    required String devEntered,
  }) {
    return verifyMaster(masterEntered) && verifyDev(devEntered);
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
  final MongoService _mongo = MongoService();

  FirestoreService({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore get _db => _customDb ?? FirestoreConfig.instance;

  /// Hashes raw passcodes with SHA-256 for secure comparison
  static String hashPasscode(String rawPasscode) {
    if (rawPasscode.trim().isEmpty) return '';
    final bytes = utf8.encode(rawPasscode.trim());
    return sha256.convert(bytes).toString();
  }

  /// Generates a new unique specific password for an event
  static String generateSpecificPassword(String titleOrId) {
    final clean = titleOrId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final slug = clean.isNotEmpty ? (clean.length > 8 ? clean.substring(0, 8) : clean) : 'event';
    final rand = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    return 'c26_${slug}_$rand';
  }

  // --- Read Events ---

  Future<List<EventItem>> getEvents({bool includeHidden = false}) async {
    // 1. Try Google Cloud Firestore Enterprise (MongoDB API)
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        final mongoEvents = await _mongo.getEvents(includeHidden: includeHidden);
        if (mongoEvents.isNotEmpty) {
          return mongoEvents;
        }
      } catch (e) {
        debugPrint('MongoService getEvents error: $e');
      }
    }

    // 2. Try Firestore Native API
    try {
      final snapshot = await _db.collection('events').get();
      if (snapshot.docs.isNotEmpty) {
        final List<EventItem> firestoreList = [];
        final Set<String> firestoreIds = {};

        for (final doc in snapshot.docs) {
          try {
            final item = EventItem.fromJson(doc.data(), doc.id);
            firestoreList.add(item);
            firestoreIds.add(item.id);
          } catch (e) {
            debugPrint('Error parsing Firestore event ${doc.id}: $e');
          }
        }

        if (firestoreList.isNotEmpty) {
          // If Firestore is missing some of the 55 events, sync missing ones in background
          if (firestoreList.length < MockData.events.length) {
            _syncMissingEventsToFirestore(firestoreIds);
          }

          if (!includeHidden) {
            return firestoreList.where((e) => e.isVisible).toList();
          }
          return firestoreList;
        }
      } else {
        // Firestore exists but has 0 documents! Trigger background batch seed of all 55 events!
        _syncMissingEventsToFirestore({});
      }
    } catch (e) {
      debugPrint('Firestore getEvents notice: $e. Falling back to local events backup.');
    }

    // Fallback to local MockData as requested by user
    if (!includeHidden) {
      return MockData.events.where((e) => e.isVisible).toList();
    }
    return MockData.events;
  }

  void _syncMissingEventsToFirestore(Set<String> existingIds) {
    Future.microtask(() async {
      try {
        final missing = MockData.events.where((e) => !existingIds.contains(e.id)).toList();
        if (missing.isEmpty) return;
        debugPrint('Auto-syncing ${missing.length} missing events to Firestore...');

        for (int i = 0; i < missing.length; i += 400) {
          final end = (i + 400 < missing.length) ? i + 400 : missing.length;
          final chunk = missing.sublist(i, end);
          final batch = _db.batch();
          for (final event in chunk) {
            final specific = event.specificPassword.isNotEmpty
                ? event.specificPassword
                : generateSpecificPassword(event.title);
            final prepared = event.copyWith(
              specificPassword: specific,
              passwordHash: hashPasscode(specific),
              isVisible: event.isVisible,
              updatedAt: DateTime.now().toIso8601String(),
            );
            batch.set(_db.collection('events').doc(event.id), prepared.toJson(), SetOptions(merge: true));
          }
          await batch.commit();
        }
        debugPrint('Auto-sync completed. All 55 events are in Cloud Firestore.');
      } catch (e) {
        debugPrint('Auto-sync to Firestore notice: $e');
      }
    });
  }

  // --- Verify Passcode for Editing ---

  /// Strictly verifies the dual passkey rule:
  /// 1. Master General Password is REQUIRED
  /// 2. Specific Event Password OR Developer Password is REQUIRED
  Future<bool> verifyEditAuthorization({
    required String eventId,
    required String masterEntered,
    required String secondaryEntered,
  }) async {
    // 1. Master General Password verification
    if (!MasterAdminConfig.verifyMaster(masterEntered)) {
      return false;
    }

    // 2. Developer password override
    if (MasterAdminConfig.verifyDev(secondaryEntered)) {
      return true;
    }

    // 3. Event-specific password verification
    return verifyEventSpecificPasscode(eventId, secondaryEntered);
  }

  /// Verifies an event's specific passcode
  Future<bool> verifyEventSpecificPasscode(String eventId, String rawPasscode) async {
    final enteredClean = rawPasscode.trim();
    if (enteredClean.isEmpty) return false;

    // Check Developer Password override
    if (MasterAdminConfig.verifyDev(enteredClean)) {
      return true;
    }

    final enteredHash = hashPasscode(enteredClean);

    // 1. Check local MockData (Instantaneous)
    final localMatch = MockData.events.where((e) => e.id == eventId);
    if (localMatch.isNotEmpty) {
      final local = localMatch.first;
      if (local.specificPassword.isNotEmpty && local.specificPassword == enteredClean) {
        return true;
      }
      if (local.passwordHash.isNotEmpty && local.passwordHash == enteredHash) {
        return true;
      }
      if (local.specificPassword.isNotEmpty && hashPasscode(local.specificPassword) == enteredHash) {
        return true;
      }
    }

    // 2. Check MongoDB (Firestore Enterprise)
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        final mongoEvent = await _mongo.getEventById(eventId).timeout(const Duration(seconds: 2));
        if (mongoEvent != null) {
          if (mongoEvent.specificPassword.isNotEmpty && mongoEvent.specificPassword == enteredClean) {
            return true;
          }
          if (mongoEvent.passwordHash.isNotEmpty && mongoEvent.passwordHash == enteredHash) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('Mongo verify notice: $e');
      }
    }

    // 3. Fallback check Native Firestore with strict non-blocking timeout
    try {
      final doc = await _db.collection('events').doc(eventId).get().timeout(const Duration(milliseconds: 600));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final specificPass = (data['specificPassword'] as String?)?.trim() ?? '';
        final storedHash = (data['passwordHash'] as String?)?.trim() ?? '';

        if (specificPass.isNotEmpty && specificPass == enteredClean) {
          return true;
        }
        if (storedHash.isNotEmpty && storedHash == enteredHash) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Firestore verify notice: $e');
    }

    return false;
  }

  // --- Toggle Visibility ---

  Future<void> toggleEventVisibility(String eventId, bool isVisible) async {
    // 1. Sync local in-memory MockData immediately
    final index = MockData.events.indexWhere((e) => e.id == eventId);
    if (index >= 0) {
      MockData.events[index] = MockData.events[index].copyWith(isVisible: isVisible);
    }

    // 2. Sync to MongoDB (Firestore Enterprise)
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.toggleVisibility(eventId, isVisible).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Mongo toggleEventVisibility notice: $e');
      }
    }

    // 3. Dispatch to Firestore Native without blocking
    try {
      _db.collection('events').doc(eventId).set(
        {'isVisible': isVisible},
        SetOptions(merge: true),
      ).timeout(const Duration(milliseconds: 600)).catchError((e) {
        debugPrint('Firestore toggleEventVisibility notice: $e');
      });
    } catch (e) {
      debugPrint('Firestore toggleEventVisibility notice: $e');
    }
  }

  // --- Create / Save Event ---

  Future<EventItem> saveEvent(EventItem event, {String? explicitSpecificPassword}) =>
      createEvent(event, explicitSpecificPassword: explicitSpecificPassword);

  Future<EventItem> createEvent(
    EventItem event, {
    String? explicitSpecificPassword,
  }) async {
    final String generatedId = event.id.isNotEmpty
        ? event.id
        : 'event_${DateTime.now().millisecondsSinceEpoch}';

    final String finalSpecificPassword = (explicitSpecificPassword != null && explicitSpecificPassword.trim().isNotEmpty)
        ? explicitSpecificPassword.trim()
        : (event.specificPassword.isNotEmpty
            ? event.specificPassword
            : generateSpecificPassword(event.title.isNotEmpty ? event.title : generatedId));

    final String finalHash = hashPasscode(finalSpecificPassword);

    final updatedEvent = event.copyWith(
      id: generatedId,
      specificPassword: finalSpecificPassword,
      passwordHash: finalHash,
      isVisible: event.isVisible,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. Sync with local in-memory MockData first
    final existingIndex = MockData.events.indexWhere((e) => e.id == generatedId);
    if (existingIndex >= 0) {
      MockData.events[existingIndex] = updatedEvent;
    } else {
      MockData.events.insert(0, updatedEvent);
    }

    // 2. Write to Google Cloud Firestore Enterprise (MongoDB API)
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.saveEvent(updatedEvent).timeout(const Duration(seconds: 4));
        debugPrint('Event "${updatedEvent.title}" written to MongoDB Enterprise.');
      } catch (e) {
        debugPrint('Mongo createEvent notice: $e');
      }
    }

    // 3. Dispatch to Firestore Native without blocking
    try {
      _db.collection('events').doc(generatedId).set(updatedEvent.toJson())
          .timeout(const Duration(milliseconds: 600))
          .catchError((e) => debugPrint('Firestore createEvent notice: $e'));
    } catch (e) {
      debugPrint('Firestore createEvent notice: $e');
    }

    return updatedEvent;
  }

  // --- Update Event ---

  Future<EventItem> updateEvent(EventItem event) async {
    final String specific = event.specificPassword.isNotEmpty
        ? event.specificPassword
        : (MockData.events.where((e) => e.id == event.id).isNotEmpty
            ? MockData.events.firstWhere((e) => e.id == event.id).specificPassword
            : '');

    final String finalHash = specific.isNotEmpty ? hashPasscode(specific) : event.passwordHash;

    final updatedEvent = event.copyWith(
      specificPassword: specific,
      passwordHash: finalHash,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. Sync with local MockData first
    final existingIndex = MockData.events.indexWhere((e) => e.id == event.id);
    if (existingIndex >= 0) {
      MockData.events[existingIndex] = updatedEvent;
    } else {
      MockData.events.insert(0, updatedEvent);
    }

    // 2. Update in Google Cloud Firestore Enterprise (MongoDB API)
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.updateEvent(updatedEvent).timeout(const Duration(seconds: 4));
        debugPrint('Event "${updatedEvent.title}" updated in MongoDB Enterprise.');
      } catch (e) {
        debugPrint('Mongo updateEvent notice: $e');
      }
    }

    // 3. Dispatch to Firestore Native without blocking
    try {
      _db.collection('events').doc(event.id).set(
            updatedEvent.toJson(),
            SetOptions(merge: true),
          )
          .timeout(const Duration(milliseconds: 600))
          .catchError((e) => debugPrint('Firestore updateEvent notice: $e'));
    } catch (e) {
      debugPrint('Firestore updateEvent notice: $e');
    }

    return updatedEvent;
  }

  // --- Delete Event ---

  Future<bool> deleteEvent(String eventId) async {
    // 1. Remove from local MockData first
    MockData.events.removeWhere((e) => e.id == eventId);

    // 2. Delete from Google Cloud Firestore Enterprise (MongoDB API)
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.deleteEvent(eventId).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Mongo deleteEvent notice: $e');
      }
    }

    // 3. Dispatch delete from Firestore Native without blocking
    try {
      _db.collection('events').doc(eventId).delete()
          .timeout(const Duration(milliseconds: 600))
          .catchError((e) => debugPrint('Firestore deleteEvent notice: $e'));
    } catch (e) {
      debugPrint('Firestore deleteEvent notice: $e');
    }

    return true;
  }

  // --- Seed Mock Data to Firestore ---

  Future<({int count, String? error})> seedMockEventsToFirestore() async {
    int count = 0;
    try {
      // Also seed to MongoDB
      if (MongoService.connectionUri.isNotEmpty) {
        try {
          await _mongo.seedMockEventsToMongo();
        } catch (_) {}
      }

      final batch = _db.batch();
      int batchCount = 0;

      for (final event in MockData.events) {
        final specific = event.specificPassword.isNotEmpty
            ? event.specificPassword
            : generateSpecificPassword(event.title);
        final preparedEvent = event.copyWith(
          specificPassword: specific,
          passwordHash: hashPasscode(specific),
          isVisible: event.isVisible,
          updatedAt: DateTime.now().toIso8601String(),
        );
        batch.set(
          _db.collection('events').doc(event.id),
          preparedEvent.toJson(),
          SetOptions(merge: true),
        );
        batchCount++;
        count++;

        if (batchCount >= 400) {
          await batch.commit();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }
      debugPrint('Successfully seeded $count events to Cloud Firestore!');
      return (count: count, error: null);
    } catch (e) {
      debugPrint('Error batch seeding events: $e');
      return (count: 0, error: e.toString());
    }
  }

  Future<Map<String, int>> seedAllDataToFirestore() async {
    final eventsRes = await seedMockEventsToFirestore();
    final eventsCount = eventsRes.count;
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
final mongoServiceProvider = Provider((ref) => MongoService());

/// Student-facing events provider: prefers MongoDB when configured, then Firestore, then local mock
final eventsProvider = FutureProvider<List<EventItem>>((ref) async {
  final mongo = ref.watch(mongoServiceProvider);
  if (MongoService.connectionUri.isNotEmpty) {
    try {
      final list = await mongo.getEvents(includeHidden: false);
      if (list.isNotEmpty) return list;
    } catch (_) {}
  }
  final service = ref.watch(firestoreServiceProvider);
  return service.getEvents(includeHidden: false);
});

/// Admin/Developer events provider: returns all events including hidden
final adminEventsProvider = FutureProvider<List<EventItem>>((ref) async {
  final mongo = ref.watch(mongoServiceProvider);
  if (MongoService.connectionUri.isNotEmpty) {
    try {
      final list = await mongo.getEvents(includeHidden: true);
      if (list.isNotEmpty) return list;
    } catch (_) {}
  }
  final service = ref.watch(firestoreServiceProvider);
  return service.getEvents(includeHidden: true);
});

final teamProvider = FutureProvider<List<CoreTeamMember>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTeam();
});

final announcementsProvider = FutureProvider<List<AnnouncementItem>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getAnnouncements();
});
