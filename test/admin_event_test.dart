import 'package:flutter_test/flutter_test.dart';
import 'package:concetto/models/event_item.dart';
import 'package:concetto/core/network/repositories.dart';
import 'package:concetto/core/network/cloudinary_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('Admin & Event Management Unit Tests', () {
    test('EventItem serialization supports organizing club and passcode hash', () {
      final event = EventItem(
        id: 'test_event_01',
        title: 'Robo Sumo Challenge',
        category: 'Robotics',
        venue: 'SAC Ground Room 1',
        time: '10:00 AM - 01:00 PM',
        description: 'Sumo bots contest',
        posterUrl: 'https://example.com/poster.jpg',
        organizerClub: 'RoboISM',
        coordinatorEmail: 'coordinator@iitism.ac.in',
        coordinatorPhone: '+91 9876543210',
        passwordHash: FirestoreService.hashPasscode('sumo2026'),
        isFlagship: true,
      );

      final json = event.toJson();
      expect(json['title'], 'Robo Sumo Challenge');
      expect(json['organizerClub'], 'RoboISM');
      expect(json['coordinatorEmail'], 'coordinator@iitism.ac.in');
      expect(json['coordinatorPhone'], '+91 9876543210');
      expect(json['isFlagship'], true);
      expect(json['passwordHash'].isNotEmpty, true);

      final deserialized = EventItem.fromJson(json, 'test_event_01');
      expect(deserialized.id, 'test_event_01');
      expect(deserialized.title, event.title);
      expect(deserialized.organizerClub, 'RoboISM');
      expect(deserialized.coordinatorEmail, 'coordinator@iitism.ac.in');
      expect(deserialized.coordinatorPhone, '+91 9876543210');
      expect(deserialized.passwordHash, event.passwordHash);
      expect(deserialized.isFlagship, true);
    });

    test('MasterAdminConfig verifies correct master passwords', () {
      expect(MasterAdminConfig.verify('Concetto@Master2026'), isTrue);
      expect(MasterAdminConfig.verify('Concetto@Master26'), isTrue);
      expect(MasterAdminConfig.verify('  concetto@master2026  '), isTrue);
      expect(MasterAdminConfig.verify('wrong_password'), isFalse);
      expect(MasterAdminConfig.verify(''), isFalse);
    });

    test('MasterAdminConfig verifies developer passwords including new pattern', () {
      expect(MasterAdminConfig.verifyDev('concetto2026@dev2!2!'), isTrue);
      expect(MasterAdminConfig.verifyDev('Concetto2026@dev2!2!'), isTrue);
      expect(MasterAdminConfig.verifyDev('Concetto#Dev2026'), isTrue);
      expect(MasterAdminConfig.verifyDev('wrong_dev_pass'), isFalse);
    });

    test('FirestoreService hashPasscode produces deterministic SHA-256 hash', () {
      final hash1 = FirestoreService.hashPasscode('my_event_pin_123');
      final hash2 = FirestoreService.hashPasscode('my_event_pin_123');
      final hashDifferent = FirestoreService.hashPasscode('another_pin');

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(hashDifferent)));
      expect(hash1.length, equals(64)); // Standard 64-hex-char SHA-256
    });

    test('CloudinaryConfig provides curated poster presets and upload URL', () {
      expect(CloudinaryConfig.posterPresets.isNotEmpty, isTrue);
      expect(CloudinaryConfig.posterPresets.first['title'], isNotNull);
      expect(CloudinaryConfig.posterPresets.first['url'], contains('http'));
      expect(CloudinaryConfig.apiKey, equals('571655651469164'));
      expect(CloudinaryConfig.apiSecret, equals('hbL-NcjtC87u98k9SWx3C0X9OvQ'));
      expect(CloudinaryConfig.folderPosters, equals('concetto_posters'));
      expect(CloudinaryConfig.folderRulebooks, equals('concetto_rulebooks'));
    });

    test('CloudinaryConfig hardcoded cloudName and upload endpoints', () {
      expect(CloudinaryConfig.cloudName, equals('dcfjykkek'));
      expect(CloudinaryConfig.isConfigured, isTrue);
      expect(CloudinaryConfig.imageUploadUrl, equals('https://api.cloudinary.com/v1_1/dcfjykkek/image/upload'));
      expect(CloudinaryConfig.autoUploadUrl, equals('https://api.cloudinary.com/v1_1/dcfjykkek/auto/upload'));
    });
  });
}
