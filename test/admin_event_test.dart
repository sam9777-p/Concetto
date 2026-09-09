import 'package:flutter_test/flutter_test.dart';
import 'package:concetto/models/event_item.dart';
import 'package:concetto/core/network/repositories.dart';
import 'package:concetto/core/network/cloudinary_config.dart';

void main() {
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
      expect(MasterAdminConfig.verify('concetto@admin2026'), isTrue);
      expect(MasterAdminConfig.verify('concetto2026'), isTrue);
      expect(MasterAdminConfig.verify('  concetto@admin2026  '), isTrue);
      expect(MasterAdminConfig.verify('wrong_password'), isFalse);
      expect(MasterAdminConfig.verify(''), isFalse);
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
      expect(CloudinaryConfig.uploadUrl, contains('api.cloudinary.com'));
    });
  });
}
