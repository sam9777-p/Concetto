import 'dart:async';
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
  // 1. Master Password: Main Organizer Hub entrance
  static const String _masterHash =
      'e64575142425195ea6195639cc0cacb60173d19ffacfa535a6fd79401f1d0c2d';

  // 2. Developer Password: Universal Override for all 3 organizer modules
  static const String _devHash =
      '40a0702c53def4d439c9aea8dc0de47a289d5382a51b4e120f1f68ae3fdb48bb';

  // 3. Event Password: Edit Events & Operations
  static const String _eventHash =
      'c22353fcea4323e52464b15510fbb78024e0885ea15356b501a22c776844d337';

  // 4. Security Password: Gate Pass Scanner
  static const String _securityHash =
      'fb536f8c72da0b506f05a8d98136f1825968ca2343fa87171b85cacd079711b1';

  // 5. Hospitality Password: Edit Passes / Non-IIT ISM Guest Management
  static const String _hospitalityHash =
      '7e31792f969f85b3357557ad1a7a8564179b959bca8bd7b3f98c31dcb28b51eb';

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

  /// Verifies Event Password strictly, with Developer Password override
  static bool verifyEvent(String entered) {
    if (entered.isEmpty) return false;
    final hash = _sha256(entered);
    return hash == _eventHash || hash == _devHash;
  }

  /// Verifies Security Password strictly, with Developer Password override
  static bool verifySecurity(String entered) {
    if (entered.isEmpty) return false;
    final hash = _sha256(entered);
    return hash == _securityHash || hash == _devHash;
  }

  /// Verifies Hospitality Password strictly, with Developer Password override
  static bool verifyHospitality(String entered) {
    if (entered.isEmpty) return false;
    final hash = _sha256(entered);
    return hash == _hospitalityHash || hash == _devHash;
  }

  /// Verifies login to Organizer Portal (strictly Master Password only)
  static bool verifyOrganizerLogin(String entered) {
    return verifyMaster(entered);
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

  /// Returns candidate Firestore instances: default and named 'concetto'
  static List<FirebaseFirestore> get allInstances {
    final list = <FirebaseFirestore>[];
    // Dedicated 'concetto' database must be FIRST
    try {
      if (databaseId.isNotEmpty && databaseId != '(default)' && Firebase.apps.isNotEmpty) {
        list.add(FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: databaseId,
        ));
      }
    } catch (e) {
      debugPrint('FirestoreConfig notice for "$databaseId": $e.');
    }
    // Fallback default instance
    try {
      list.add(FirebaseFirestore.instance);
    } catch (_) {}
    return list;
  }

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
  static FirebaseFirestore? _activeInstance;

  FirestoreService({FirebaseFirestore? db}) : _customDb = db;

  FirebaseFirestore get _db => _customDb ?? FirestoreConfig.instance;

  static List<FirebaseFirestore> get _firestoreInstances {
    return FirestoreConfig.allInstances;
  }

  /// Automatically detects and caches which Firestore instance holds active event data
  Future<FirebaseFirestore> getActiveFirestore() async {
    if (_customDb != null) return _customDb;
    if (_activeInstance != null) return _activeInstance!;
    for (final db in _firestoreInstances) {
      try {
        final snap = await db.collection('events').limit(1).get(const GetOptions(source: Source.serverAndCache)).timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) {
          _activeInstance = db;
          debugPrint('Active Firestore database detected: ${db.databaseId}');
          return db;
        }
      } catch (e) {
        debugPrint('Candidate database check for ${db.databaseId}: $e');
      }
    }
    _activeInstance = FirestoreConfig.instance;
    return _activeInstance!;
  }

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

    // 2. Try candidate Firestore databases with cache-first and server refresh
    for (final db in _firestoreInstances) {
      try {
        final snapshot = await db.collection('events').get(const GetOptions(source: Source.serverAndCache)).timeout(const Duration(seconds: 4));
        if (snapshot.docs.isNotEmpty) {
          final List<EventItem> firestoreList = [];
          for (final doc in snapshot.docs) {
            try {
              final item = EventItem.fromJson(doc.data(), doc.id);
              firestoreList.add(item);
            } catch (e) {
              debugPrint('Error parsing Firestore event ${doc.id}: $e');
            }
          }

          if (firestoreList.isNotEmpty) {
            _activeInstance = db;
            if (!includeHidden) {
              return firestoreList.where((e) => e.isVisible).toList();
            }
            return firestoreList;
          }
        }
      } catch (e) {
        debugPrint('Firestore (${db.databaseId}) getEvents notice: $e');
      }
    }

    return const [];
  }

  /// Real-time stream of events using Firestore live snapshots
  Stream<List<EventItem>> getEventsStream({bool includeHidden = false}) async* {

    // Initial emission
    final initial = await getEvents(includeHidden: includeHidden);
    if (initial.isNotEmpty) {
      yield initial;
    }

    // Listen to real-time snapshots from active database
    final db = await getActiveFirestore();
    yield* db.collection('events').snapshots().map((snapshot) {
      final List<EventItem> list = [];
      for (final doc in snapshot.docs) {
        try {
          list.add(EventItem.fromJson(doc.data(), doc.id));
        } catch (e) {
          debugPrint('Error parsing snapshot event ${doc.id}: $e');
        }
      }
      if (!includeHidden) {
        return list.where((e) => e.isVisible).toList();
      }
      return list;
    });
  }

  /// Fetches a single event directly from Cloud Firestore by ID (checks all databases)
  Future<EventItem?> getEventById(String eventId) async {
    for (final db in _firestoreInstances) {
      try {
        final doc = await db.collection('events').doc(eventId).get().timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          return EventItem.fromJson(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('Error getting event by ID $eventId from Firestore (${db.databaseId}): $e');
      }
    }
    return null;
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

    // 1. Check MongoDB (Firestore Enterprise) if configured
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

    // 2. Check Candidate Firestore Databases
    for (final db in _firestoreInstances) {
      try {
        final doc = await db.collection('events').doc(eventId).get();
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
          if (specificPass.isNotEmpty && hashPasscode(specificPass) == enteredHash) {
            return true;
          }
        }
      } catch (e) {
        debugPrint('Firestore verify notice for ${db.databaseId}: $e');
      }
    }

    return false;
  }

  // --- Toggle Visibility ---

  Future<void> toggleEventVisibility(String eventId, bool isVisible) async {
    // 1. Sync to MongoDB (Firestore Enterprise)
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.toggleVisibility(eventId, isVisible).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Mongo toggleEventVisibility notice: $e');
      }
    }

    // 2. Write to all Firestore candidate databases in parallel with timeout
    final futures = _firestoreInstances.map((db) async {
      try {
        await db.collection('events').doc(eventId).set(
          {'isVisible': isVisible},
          SetOptions(merge: true),
        ).timeout(const Duration(seconds: 4));
        debugPrint('Firestore (${db.databaseId}) toggleEventVisibility updated for $eventId');
      } catch (e) {
        debugPrint('Firestore (${db.databaseId}) toggleEventVisibility notice: $e');
      }
    });
    await Future.wait(futures);
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

    // 1. Write to Google Cloud Firestore Enterprise (MongoDB API) with timeout
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.saveEvent(updatedEvent).timeout(const Duration(seconds: 4));
        debugPrint('Event "${updatedEvent.title}" written to MongoDB Enterprise.');
      } catch (e) {
        debugPrint('Mongo createEvent notice: $e');
      }
    }

    // 2. Write directly to all candidate Firestore databases in parallel with timeout
    final futures = _firestoreInstances.map((db) async {
      try {
        await db.collection('events').doc(generatedId).set(updatedEvent.toJson()).timeout(const Duration(seconds: 4));
        debugPrint('Event "${updatedEvent.title}" saved to Cloud Firestore (${db.databaseId}).');
      } catch (e) {
        debugPrint('Firestore (${db.databaseId}) createEvent notice: $e');
      }
    });
    await Future.wait(futures);

    return updatedEvent;
  }

  // --- Update Event ---

  Future<EventItem> updateEvent(EventItem event) async {
    final String docId = event.id.isNotEmpty
        ? event.id
        : 'event_${DateTime.now().millisecondsSinceEpoch}';

    final String specific = event.specificPassword.isNotEmpty
        ? event.specificPassword
        : '';

    final String finalHash = specific.isNotEmpty ? hashPasscode(specific) : event.passwordHash;

    final updatedEvent = event.copyWith(
      id: docId,
      specificPassword: specific,
      passwordHash: finalHash,
      updatedAt: DateTime.now().toIso8601String(),
    );

    // 1. Update in Google Cloud Firestore Enterprise (MongoDB API) with timeout
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.updateEvent(updatedEvent).timeout(const Duration(seconds: 4));
        debugPrint('Event "${updatedEvent.title}" updated in MongoDB Enterprise.');
      } catch (e) {
        debugPrint('Mongo updateEvent notice: $e');
      }
    }

    // 2. Write directly to all candidate Cloud Firestore databases in parallel with timeout
    final futures = _firestoreInstances.map((db) async {
      try {
        await db.collection('events').doc(docId).set(
              updatedEvent.toJson(),
              SetOptions(merge: true),
            ).timeout(const Duration(seconds: 4));
        debugPrint('Event "${updatedEvent.title}" updated in Cloud Firestore (${db.databaseId}).');
      } catch (e) {
        debugPrint('Firestore (${db.databaseId}) updateEvent notice: $e');
      }
    });
    await Future.wait(futures);

    return updatedEvent;
  }

  // --- Delete Event ---

  Future<bool> deleteEvent(String eventId) async {
    // 1. Delete from Google Cloud Firestore Enterprise (MongoDB API) with timeout
    if (MongoService.connectionUri.isNotEmpty) {
      try {
        await _mongo.deleteEvent(eventId).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Mongo deleteEvent notice: $e');
      }
    }

    // 2. Delete directly from all candidate Cloud Firestore databases in parallel with timeout
    final futures = _firestoreInstances.map((db) async {
      try {
        await db.collection('events').doc(eventId).delete().timeout(const Duration(seconds: 4));
        debugPrint('Event "$eventId" deleted from Cloud Firestore (${db.databaseId}).');
      } catch (e) {
        debugPrint('Firestore (${db.databaseId}) deleteEvent notice: $e');
      }
    });
    await Future.wait(futures);

    return true;
  }

  // --- Team & Announcements ---

  Future<List<CoreTeamMember>> getTeam() async {
    try {
      final snapshot = await _db.collection('team').get().timeout(const Duration(milliseconds: 700));
      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs
            .map((doc) => CoreTeamMember.fromJson(doc.data()))
            .toList();
        final mockMap = {for (var m in MockData.team) m.name: m};
        for (int i = 0; i < list.length; i++) {
          final mock = mockMap[list[i].name] ??
              (list[i].name.contains('Arun') ? mockMap['Prof. Arun Udai'] : null);
          if (mock != null) {
            list[i] = list[i].copyWith(
              name: mock.name,
              role: mock.role,
              quote: list[i].quote.isEmpty ? mock.quote : list[i].quote,
              phone: list[i].phone.isEmpty ? mock.phone : list[i].phone,
              imageUrl: list[i].imageUrl.isEmpty ? mock.imageUrl : list[i].imageUrl,
              order: mock.order,
            );
          }
        }
        list.sort((a, b) => a.order.compareTo(b.order));
        if (list.length >= 50) {
          return list;
        }
      }
      return MockData.team;
    } catch (e) {
      debugPrint('Firestore getTeam notice: $e. Falling back to verified mock data.');
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

/// Student-facing events provider: live real-time stream from Firestore with offline cache
final eventsProvider = StreamProvider<List<EventItem>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getEventsStream(includeHidden: false);
});

/// Admin/Developer events provider: live real-time stream returning all events including hidden
final adminEventsProvider = StreamProvider<List<EventItem>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getEventsStream(includeHidden: true);
});

final teamProvider = FutureProvider<List<CoreTeamMember>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getTeam();
});

final announcementsProvider = FutureProvider<List<AnnouncementItem>>((ref) async {
  final service = ref.watch(firestoreServiceProvider);
  return service.getAnnouncements();
});
