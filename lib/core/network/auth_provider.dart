import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'repositories.dart';

class AttendeeProfile {
  final String uid;
  final String name;
  final String email;
  final String college;
  final String phone;
  final String passId;
  final int passType; // 0: Student, 1: Guest, 2: Silver, 3: Gold, 4: Diamond, 5: Diamond+ Merch
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

  String get passCategoryTitle {
    if (isIitIsm && (passType == 0 || passType == 1)) {
      return 'STUDENT PASS';
    }
    return passCategoryNames[passType] ?? 'ATTENDEE PASS';
  }

  bool get isLoggedIn => !isGuest && isEmailVerified;

  bool get isIitIsm {
    final c = college.toLowerCase().trim();
    final e = email.toLowerCase().trim();
    return c.contains('ism') ||
        c.contains('iit (ism)') ||
        c.contains('dhanbad') ||
        c.contains('indian institute of technology') ||
        e.endsWith('@iitism.ac.in');
  }

  String get qrPayload => passId;

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

  static List<FirebaseFirestore> _getFirestoreInstances() {
    final list = <FirebaseFirestore>[];
    try {
      // 1. Default Firestore database
      list.add(FirebaseFirestore.instance);
    } catch (_) {}
    try {
      // 2. Named 'concetto' database
      if (FirestoreConfig.databaseId.isNotEmpty && FirestoreConfig.databaseId != '(default)') {
        list.add(FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: FirestoreConfig.databaseId,
        ));
      }
    } catch (_) {}
    return list;
  }

  static Future<void> _persistUserToFirestore({
    required String uid,
    required String passId,
    required Map<String, dynamic> userData,
  }) async {
    for (final db in _getFirestoreInstances()) {
      try {
        // ONLY persist user profile under their unique Auth UID
        await db.collection('users').doc(uid).set(userData, SetOptions(merge: true)).timeout(const Duration(seconds: 4));
        debugPrint('Successfully persisted user to Firestore database ${db.databaseId}');
      } catch (e) {
        debugPrint('Notice persisting to Firestore (${db.databaseId}): $e');
      }
    }
  }

  static Future<Map<String, dynamic>?> _readUserFromFirestore(String uid) async {
    for (final db in _getFirestoreInstances()) {
      try {
        final doc = await db.collection('users').doc(uid).get().timeout(const Duration(seconds: 4));
        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
      } catch (e) {
        debugPrint('Notice reading user from Firestore (${db.databaseId}): $e');
      }
    }
    return null;
  }

  Future<void> _initCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        await user.reload();
        final refreshed = FirebaseAuth.instance.currentUser;
        if (refreshed != null && refreshed.emailVerified) {
          // Try local cache first for instant rendering
          await _loadProfileFromLocalCache(refreshed.uid);
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

  Future<void> _loadProfileFromLocalCache(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_profile_$uid');
      if (cachedJson != null) {
        final map = jsonDecode(cachedJson) as Map<String, dynamic>;
        final college = (map['college'] as String? ?? '').toLowerCase();
        final email = (map['email'] as String? ?? '').toLowerCase();
        final isIit = college.contains('ism') ||
            college.contains('iit (ism)') ||
            college.contains('dhanbad') ||
            college.contains('indian institute of technology') ||
            email.endsWith('@iitism.ac.in');

        int pType = map['passType'] is int ? map['passType'] as int : (isIit ? 0 : 1);
        if (isIit && (pType == 1 || pType == 0)) {
          pType = 0;
        }

        state = AttendeeProfile(
          uid: uid,
          name: map['name'] ?? '',
          email: map['email'] ?? '',
          college: map['college'] ?? '',
          phone: map['phone'] ?? '',
          passId: map['passId'] ?? '',
          passType: pType,
          isGuest: false,
          isEmailVerified: true,
          registeredEventIds: state.registeredEventIds,
        );
      }
    } catch (e) {
      debugPrint('Cache load notice: $e');
    }
  }

  Future<void> _saveProfileToLocalCache(AttendeeProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_profile_${profile.uid}',
        jsonEncode({
          'uid': profile.uid,
          'name': profile.name,
          'email': profile.email,
          'college': profile.college,
          'phone': profile.phone,
          'passId': profile.passId,
          'passType': profile.passType,
        }),
      );
    } catch (e) {
      debugPrint('Cache save notice: $e');
    }
  }

  Future<void> _loadProfileFromFirestore(User user) async {
    try {
      final data = await _readUserFromFirestore(user.uid);
      if (data != null) {
        final passTypeRaw = data['passType'];
        final passCatRaw = (data['passCategory'] as String? ?? '').toUpperCase();
        final collegeRaw = (data['college'] as String? ?? '').trim();
        final emailRaw = (user.email ?? data['email'] as String? ?? '').trim();

        final isIit = (data['isIitIsm'] == true) ||
            collegeRaw.toLowerCase().contains('ism') ||
            collegeRaw.toLowerCase().contains('iit (ism)') ||
            collegeRaw.toLowerCase().contains('dhanbad') ||
            collegeRaw.toLowerCase().contains('indian institute of technology') ||
            emailRaw.toLowerCase().endsWith('@iitism.ac.in') ||
            passCatRaw.contains('STUDENT');

        int parsedPassType = isIit ? 0 : 1;
        if (passTypeRaw is int) {
          parsedPassType = passTypeRaw;
        } else if (passTypeRaw != null) {
          parsedPassType = int.tryParse(passTypeRaw.toString()) ?? (isIit ? 0 : 1);
        }

        // Auto-heal: If user is from IIT ISM and passType is 1, heal to 0 (STUDENT PASS)
        if (isIit && (parsedPassType == 1 || parsedPassType == 0)) {
          parsedPassType = 0;
        }

        final existingPhone = (data['phone'] as String?)?.trim() ?? '';
        final resolvedPhone = existingPhone.isNotEmpty
            ? existingPhone
            : (state.phone.isNotEmpty ? state.phone : (user.phoneNumber ?? ''));

        final profile = AttendeeProfile(
          uid: user.uid,
          name: (data['name'] as String?)?.isNotEmpty == true
              ? data['name'] as String
              : (user.displayName ?? user.email!.split('@').first),
          email: user.email!,
          college: collegeRaw.isNotEmpty ? collegeRaw : (isIit ? 'IIT (ISM) Dhanbad' : 'Visiting Participant'),
          phone: resolvedPhone,
          passId: data['passId'] as String? ?? 'CON-26-${user.uid.substring(0, 6).toUpperCase()}',
          passType: parsedPassType,
          isGuest: false,
          isEmailVerified: true,
          registeredEventIds: state.registeredEventIds,
        );
        state = profile;
        await _saveProfileToLocalCache(profile);

        // Auto-heal Firestore document if passType or isIitIsm was misconfigured
        if (passTypeRaw != parsedPassType || data['isIitIsm'] != isIit) {
          _persistUserToFirestore(
            uid: user.uid,
            passId: profile.passId,
            userData: {
              'passType': parsedPassType,
              'passCategory': AttendeeProfile.passCategoryNames[parsedPassType] ?? 'STUDENT PASS',
              'isIitIsm': isIit,
            },
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Error loading firestore profile: $e');
    }

    // Fallback if firestore document not found yet: generate and repair Firestore instantly!
    final isIit = user.email!.toLowerCase().endsWith('@iitism.ac.in') ||
        state.college.toLowerCase().contains('ism') ||
        state.college.toLowerCase().contains('dhanbad') ||
        state.isIitIsm;
    final uniqueSuffix = user.uid.length >= 6
        ? user.uid.substring(0, 6).toUpperCase()
        : DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final passId = 'CON-26-$uniqueSuffix';
    final passType = isIit ? 0 : 1;
    final college = isIit ? 'Indian Institute of Technology (ISM) Dhanbad' : 'Visiting Participant';
    final name = user.displayName?.isNotEmpty == true ? user.displayName! : user.email!.split('@').first;
    final fallbackPhone = state.phone.isNotEmpty ? state.phone : (user.phoneNumber ?? '');

    final profile = AttendeeProfile(
      uid: user.uid,
      name: name,
      email: user.email!,
      college: college,
      phone: fallbackPhone,
      passId: passId,
      passType: passType,
      isGuest: false,
      isEmailVerified: true,
      registeredEventIds: state.registeredEventIds,
    );
    state = profile;
    await _saveProfileToLocalCache(profile);

    // Save to Firestore in background
    _persistUserToFirestore(
      uid: user.uid,
      passId: passId,
      userData: {
        'uid': user.uid,
        'name': name,
        'email': user.email!,
        'phone': fallbackPhone,
        'college': college,
        'isIitIsm': isIit,
        'passId': passId,
        'passType': passType,
        'passCategory': AttendeeProfile.passCategoryNames[passType] ?? 'STUDENT PASS',
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtIso': DateTime.now().toIso8601String(),
      },
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
        'Email address not verified yet. Please check your inbox and SPAM folder at $cleanEmail and click the verification link before logging in.',
      );
    }

    await _loadProfileFromFirestore(refreshedUser);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception('Please enter your email address.');
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: cleanEmail);
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
    final passCategoryTitle = AttendeeProfile.passCategoryNames[defaultPassType] ?? 'STUDENT PASS';

    // 1. Create Firebase Auth User
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Failed to create account.');
    }

    try {
      await user.updateDisplayName(name.trim());
    } catch (_) {}

    // 2. IMMEDIATELY send Verification Email right away!
    try {
      await user.sendEmailVerification();
      debugPrint('Verification email dispatched to $cleanEmail');
    } catch (e) {
      debugPrint('Error sending verification email: $e');
    }

    // 3. Generate Unique Pass Identifier
    final uniqueSuffix = user.uid.length >= 6
        ? user.uid.substring(0, 6).toUpperCase()
        : DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final passId = 'CON-26-$uniqueSuffix';

    final userData = {
      'uid': user.uid,
      'name': name.trim(),
      'email': cleanEmail,
      'phone': phone.trim(),
      'college': college.trim(),
      'isIitIsm': isIitIsm,
      'passId': passId,
      'passType': defaultPassType,
      'passCategory': passCategoryTitle,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtIso': DateTime.now().toIso8601String(),
    };

    // 4. Save to local cache immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_profile_${user.uid}',
        jsonEncode({
          'uid': user.uid,
          'name': name.trim(),
          'email': cleanEmail,
          'phone': phone.trim(),
          'college': college.trim(),
          'passId': passId,
          'passType': defaultPassType,
        }),
      );
    } catch (_) {}

    // 5. Persist to Firestore: ONLY `users` collection!
    await _persistUserToFirestore(
      uid: user.uid,
      passId: passId,
      userData: userData,
    );

    // 6. User cannot login until email is verified, so sign out
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

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

