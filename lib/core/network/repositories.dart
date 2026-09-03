import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_item.dart';
import '../../models/core_team_member.dart';
import '../../models/announcement_item.dart';

// --- Service ---

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<EventItem>> getEvents() async {
    final snapshot = await _db.collection('events').get();
    return snapshot.docs
        .map((doc) => EventItem.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<List<CoreTeamMember>> getTeam() async {
    final snapshot = await _db.collection('team').get();
    return snapshot.docs
        .map((doc) => CoreTeamMember.fromJson(doc.data()))
        .toList();
  }

  Future<List<AnnouncementItem>> getAnnouncements() async {
    final snapshot = await _db.collection('announcements').get();
    return snapshot.docs
        .map((doc) => AnnouncementItem.fromJson(doc.data(), doc.id))
        .toList();
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
