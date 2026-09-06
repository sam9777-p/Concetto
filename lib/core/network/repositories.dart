import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_item.dart';
import '../../models/core_team_member.dart';
import '../../models/announcement_item.dart';
import 'mock_data.dart';

// --- Service ---

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      debugPrint('Firestore getEvents error: $e. Falling back to mock data.');
      return MockData.events;
    }
  }

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
      debugPrint('Firestore getTeam error: $e. Falling back to mock data.');
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
      debugPrint('Firestore getAnnouncements error: $e. Falling back to mock data.');
      return MockData.announcements;
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

