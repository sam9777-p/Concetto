import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/network/auth_provider.dart';
import '../models/event_item.dart';

class EventLikesState {
  final Set<String> guestLikedEventIds;
  final Set<String> userLikedEventIds;
  final Map<String, int> optimisticOffsets;

  const EventLikesState({
    this.guestLikedEventIds = const {},
    this.userLikedEventIds = const {},
    this.optimisticOffsets = const {},
  });

  EventLikesState copyWith({
    Set<String>? guestLikedEventIds,
    Set<String>? userLikedEventIds,
    Map<String, int>? optimisticOffsets,
  }) {
    return EventLikesState(
      guestLikedEventIds: guestLikedEventIds ?? this.guestLikedEventIds,
      userLikedEventIds: userLikedEventIds ?? this.userLikedEventIds,
      optimisticOffsets: optimisticOffsets ?? this.optimisticOffsets,
    );
  }
}

class EventLikesNotifier extends Notifier<EventLikesState> {
  static const String _guestPrefsKey = 'concetto_guest_likes';

  @override
  EventLikesState build() {
    _loadFromLocalCache();
    return const EventLikesState();
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guestList = prefs.getStringList(_guestPrefsKey) ?? [];
      
      final profile = ref.read(authProvider);
      List<String> userList = [];
      if (profile.isLoggedIn && profile.uid.isNotEmpty) {
        userList = prefs.getStringList('concetto_user_likes_${profile.uid}') ?? [];
        _syncFromFirestore(profile.uid);
      }

      state = state.copyWith(
        guestLikedEventIds: guestList.toSet(),
        userLikedEventIds: userList.toSet(),
      );
    } catch (e) {
      debugPrint('EventLikesNotifier: Error loading cache: $e');
    }
  }

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        if (data['likedEvents'] is List) {
          final remoteList = (data['likedEvents'] as List).map((e) => e.toString()).toSet();
          state = state.copyWith(userLikedEventIds: remoteList);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('concetto_user_likes_$uid', remoteList.toList());
        }
      }
    } catch (e) {
      debugPrint('EventLikesNotifier: Error syncing from Firestore: $e');
    }
  }

  bool isEventLiked(String eventId) {
    final profile = ref.read(authProvider);
    if (profile.isLoggedIn) {
      return state.userLikedEventIds.contains(eventId);
    }
    return state.guestLikedEventIds.contains(eventId);
  }

  int getEffectiveLikes(EventItem event) {
    final profile = ref.read(authProvider);
    final base = event.likeCount;
    if (profile.isLoggedIn) {
      final offset = state.optimisticOffsets[event.id] ?? 0;
      final total = base + offset;
      return total < 0 ? 0 : total;
    } else {
      // Guest likes are stored in phone's cache only
      final guestLiked = state.guestLikedEventIds.contains(event.id);
      final total = base + (guestLiked ? 1 : 0);
      return total < 0 ? 0 : total;
    }
  }

  Future<void> toggleLike(EventItem event) async {
    final profile = ref.read(authProvider);
    final prefs = await SharedPreferences.getInstance();
    final eventId = event.id;

    if (!profile.isLoggedIn || profile.uid.isEmpty) {
      // GUEST MODE:
      // "if not login he can like or dislike but that data will not be stored it'll be in his phones cache"
      final currentGuests = Set<String>.from(state.guestLikedEventIds);
      if (currentGuests.contains(eventId)) {
        currentGuests.remove(eventId);
      } else {
        currentGuests.add(eventId);
      }

      state = state.copyWith(guestLikedEventIds: currentGuests);
      await prefs.setStringList(_guestPrefsKey, currentGuests.toList());
      return;
    }

    // LOGGED IN MODE:
    // "every login person can like once if account is login"
    final uid = profile.uid;
    final currentUsers = Set<String>.from(state.userLikedEventIds);
    final isAlreadyLiked = currentUsers.contains(eventId);

    final newOffsets = Map<String, int>.from(state.optimisticOffsets);

    if (isAlreadyLiked) {
      // Unlike
      currentUsers.remove(eventId);
      newOffsets[eventId] = (newOffsets[eventId] ?? 0) - 1;
      state = state.copyWith(
        userLikedEventIds: currentUsers,
        optimisticOffsets: newOffsets,
      );

      await prefs.setStringList('concetto_user_likes_$uid', currentUsers.toList());

      try {
        await FirebaseFirestore.instance.collection('events').doc(eventId).update({
          'likeCount': FieldValue.increment(-1),
        });
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'likedEvents': FieldValue.arrayRemove([eventId]),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('EventLikesNotifier: Failed to update unlike in Firestore: $e');
      }
    } else {
      // Like (can like once)
      currentUsers.add(eventId);
      newOffsets[eventId] = (newOffsets[eventId] ?? 0) + 1;
      state = state.copyWith(
        userLikedEventIds: currentUsers,
        optimisticOffsets: newOffsets,
      );

      await prefs.setStringList('concetto_user_likes_$uid', currentUsers.toList());

      try {
        await FirebaseFirestore.instance.collection('events').doc(eventId).update({
          'likeCount': FieldValue.increment(1),
        });
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'likedEvents': FieldValue.arrayUnion([eventId]),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('EventLikesNotifier: Failed to update like in Firestore: $e');
      }
    }
  }
}

final eventLikesProvider = NotifierProvider<EventLikesNotifier, EventLikesState>(EventLikesNotifier.new);
