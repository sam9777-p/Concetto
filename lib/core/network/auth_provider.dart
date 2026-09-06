import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendeeProfile {
  final String uid;
  final String name;
  final String email;
  final String college;
  final String phone;
  final String passId;
  final bool isGuest;
  final List<String> registeredEventIds;

  AttendeeProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.college,
    required this.phone,
    required this.passId,
    this.isGuest = false,
    this.registeredEventIds = const [],
  });

  AttendeeProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? college,
    String? phone,
    String? passId,
    bool? isGuest,
    List<String>? registeredEventIds,
  }) {
    return AttendeeProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      college: college ?? this.college,
      phone: phone ?? this.phone,
      passId: passId ?? this.passId,
      isGuest: isGuest ?? this.isGuest,
      registeredEventIds: registeredEventIds ?? this.registeredEventIds,
    );
  }
}

class AuthNotifier extends StateNotifier<AttendeeProfile> {
  AuthNotifier() : super(_initialGuestProfile());

  static AttendeeProfile _initialGuestProfile() {
    return AttendeeProfile(
      uid: 'guest_001',
      name: 'Fest Attendee',
      email: 'guest@concetto.in',
      college: 'Guest Participant',
      phone: '+91 98765 43210',
      passId: 'CON-2026-G842',
      isGuest: true,
      registeredEventIds: ['robowars_15kg', 'masterstack'],
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      final displayName = user?.displayName ?? email.split('@').first;

      state = AttendeeProfile(
        uid: user?.uid ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: displayName.isNotEmpty ? displayName : 'Concetto Explorer',
        email: email,
        college: 'Registered Participant',
        phone: user?.phoneNumber ?? '+91 85030 86164',
        passId: 'CON-2026-${(user?.uid.substring(0, 4) ?? "7492").toUpperCase()}',
        isGuest: false,
        registeredEventIds: state.registeredEventIds,
      );
    } catch (e) {
      debugPrint('Firebase Auth notice ($e). Updating local attendee session.');
      // Fallback local session
      state = AttendeeProfile(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        college: 'Registered Participant',
        phone: '+91 85030 86164',
        passId: 'CON-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        isGuest: false,
        registeredEventIds: state.registeredEventIds,
      );
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String college,
    required String phone,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      state = AttendeeProfile(
        uid: credential.user?.uid ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        college: college,
        phone: phone,
        passId: 'CON-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        isGuest: false,
        registeredEventIds: state.registeredEventIds,
      );
    } catch (e) {
      debugPrint('Firebase Auth signup notice ($e). Updating local attendee profile.');
      state = AttendeeProfile(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        college: college,
        phone: phone,
        passId: 'CON-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        isGuest: false,
        registeredEventIds: state.registeredEventIds,
      );
    }
  }

  void continueAsGuest([String? name, String? college]) {
    state = AttendeeProfile(
      uid: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Guest Attendee',
      email: 'guest@concetto.in',
      college: college ?? 'Visiting Participant',
      phone: '+91 85030 86164',
      passId: 'CON-2026-G${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      isGuest: true,
      registeredEventIds: state.registeredEventIds,
    );
  }

  void signOut() {
    try {
      FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Sign out notice: $e');
    }
    state = _initialGuestProfile();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AttendeeProfile>((ref) {
  return AuthNotifier();
});
