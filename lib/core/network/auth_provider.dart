import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendeeProfile {
  final String uid;
  final String name;
  final String email;
  final String college;
  final String phone;
  final String passId;
  final int passType; // 0: Student, 1: Guest, 2: Silver, 3: Gold, 4: Platinum, 5: VIP
  final bool isGuest;
  final bool isEmailVerified;
  final List<String> registeredEventIds;

  AttendeeProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.college,
    required this.phone,
    required this.passId,
    this.passType = 1,
    this.isGuest = false,
    this.isEmailVerified = false,
    this.registeredEventIds = const [],
  });

  static const Map<int, String> passCategoryNames = {
    0: 'STUDENT PASS',
    1: 'GUEST PASS',
    2: 'SILVER PASS',
    3: 'GOLD PASS',
    4: 'DIAMOND PASS',
    5: 'DIAMOND+ MERCH PASS',
  };

  String get passCategoryTitle => passCategoryNames[passType] ?? 'ATTENDEE PASS';

  bool get isLoggedIn => !isGuest && isEmailVerified;

  bool get isIitIsm =>
      college.toLowerCase().contains('ism') ||
      college.toLowerCase().contains('iit (ism)') ||
      email.toLowerCase().endsWith('@iitism.ac.in');

  String get qrPayload => jsonEncode({
        'uid': uid,
        'passId': passId,
      });

  AttendeeProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? college,
    String? phone,
    String? passId,
    int? passType,
    bool? isGuest,
    bool? isEmailVerified,
    List<String>? registeredEventIds,
  }) {
    return AttendeeProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      college: college ?? this.college,
      phone: phone ?? this.phone,
      passId: passId ?? this.passId,
      passType: passType ?? this.passType,
      isGuest: isGuest ?? this.isGuest,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      registeredEventIds: registeredEventIds ?? this.registeredEventIds,
    );
  }
}

class AuthNotifier extends Notifier<AttendeeProfile> {
  @override
  AttendeeProfile build() {
    _initCurrentUser();
    return _initialGuestProfile();
  }

  static AttendeeProfile _initialGuestProfile() {
    return AttendeeProfile(
      uid: '',
      name: '',
      email: '',
      college: '',
      phone: '',
      passId: '',
      passType: 1,
      isGuest: true,
      isEmailVerified: false,
      registeredEventIds: const [],
    );
  }

  Future<void> _initCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;
        if (refreshed != null && refreshed.emailVerified) {
          await _loadProfileFromFirestore(refreshed);
        } else {
          // If not email verified, sign out
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      debugPrint('Init auth notice: $e');
    }
  }

  Future<void> _loadProfileFromFirestore(User user) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final passTypeRaw = data['passType'];
        int parsedPassType = 1;
        if (passTypeRaw is int) {
          parsedPassType = passTypeRaw;
        } else if (passTypeRaw != null) {
          parsedPassType = int.tryParse(passTypeRaw.toString()) ?? 1;
        }

        state = AttendeeProfile(
          uid: user.uid,
          name: (data['name'] as String?)?.isNotEmpty == true
              ? data['name'] as String
              : (user.displayName ?? user.email!.split('@').first),
          email: user.email!,
          college: data['college'] as String? ?? 'IIT (ISM) Dhanbad',
          phone: data['phone'] as String? ?? user.phoneNumber ?? '',
          passId: data['passId'] as String? ?? 'CON-26-${user.uid.substring(0, 6).toUpperCase()}',
          passType: parsedPassType,
          isGuest: false,
          isEmailVerified: true,
          registeredEventIds: state.registeredEventIds,
        );
        return;
      }
    } catch (e) {
      debugPrint('Error loading firestore profile: $e');
    }

    // Fallback if firestore document not found yet
    final isIit = user.email!.toLowerCase().endsWith('@iitism.ac.in');
    state = AttendeeProfile(
      uid: user.uid,
      name: user.displayName ?? user.email!.split('@').first,
      email: user.email!,
      college: isIit ? 'Indian Institute of Technology (ISM) Dhanbad' : 'Registered Participant',
      phone: user.phoneNumber ?? '',
      passId: 'CON-26-${user.uid.substring(0, 6).toUpperCase()}',
      passType: isIit ? 0 : 1,
      isGuest: false,
      isEmailVerified: true,
      registeredEventIds: state.registeredEventIds,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Authentication failed. User not found.');
    }

    // Check email verification status
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser ?? user;
    if (!refreshedUser.emailVerified) {
      // Must not allow login if email not verified
      await FirebaseAuth.instance.signOut();
      throw Exception(
        'Email address not verified yet. Please check your inbox at $cleanEmail and click the verification link before logging in.',
      );
    }

    await _loadProfileFromFirestore(refreshedUser);
  }

  Future<void> resendVerificationEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await user.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<String> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String college,
    required String phone,
  }) async {
    final cleanEmail = email.trim();
    final isIitIsm = college.trim() == 'Indian Institute of Technology (ISM) Dhanbad';

    // Strict IIT ISM validation
    if (isIitIsm && !cleanEmail.toLowerCase().endsWith('@iitism.ac.in')) {
      throw Exception(
        'IIT (ISM) Dhanbad students must register with their official institute email (@iitism.ac.in).',
      );
    }

    // Default pass type: 0 for IIT ISM student, 1 for guest from other colleges
    final int defaultPassType = isIitIsm ? 0 : 1;

    // 1. Create Firebase Auth User
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Failed to create account.');
    }

    await user.updateDisplayName(name);

    // 2. Generate Unique Pass Identifier
    final uniqueSuffix = user.uid.length >= 6
        ? user.uid.substring(0, 6).toUpperCase()
        : DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final passId = 'CON-26-$uniqueSuffix';

    // 3. Persist to Firestore: `users` and `passes` collections
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone.trim(),
        'college': college.trim(),
        'isIitIsm': isIitIsm,
        'passId': passId,
        'passType': defaultPassType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('passes').doc(passId).set({
        'passId': passId,
        'userId': user.uid,
        'name': name.trim(),
        'email': cleanEmail,
        'phone': phone.trim(),
        'college': college.trim(),
        'passType': defaultPassType,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore pass document write notice: $e');
    }

    // 4. Send Confirmation / Verification Email
    await user.sendEmailVerification();

    // 5. User cannot login until verified, so sign out immediately
    await FirebaseAuth.instance.signOut();

    return passId;
  }

  /// Reloads profile from Firestore to pick up any pass changes made in Firebase
  Future<void> refreshProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !state.isGuest) {
      await _loadProfileFromFirestore(user);
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
      passType: 1,
      isGuest: true,
      isEmailVerified: false,
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

final authProvider = NotifierProvider<AuthNotifier, AttendeeProfile>(AuthNotifier.new);

