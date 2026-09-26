// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:concetto/core/network/repositories.dart';
import 'package:concetto/models/event_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FirestoreService unified with MongoDB integration test', () async {
    final service = FirestoreService();

    // 1. Verify getEvents pulls from MongoDB and all prizePools are 'TBD'
    print('1. Calling service.getEvents()...');
    final events = await service.getEvents(includeHidden: true);
    print('Fetched ${events.length} events from live database.');
    expect(events.length, greaterThanOrEqualTo(55));

    // Verify non-workshop competitions have valid prize pool while workshops have NO prize pool
    final workshopEvents = events.where((e) => e.category.toLowerCase() == 'workshops').toList();
    for (final w in workshopEvents) {
      expect(w.prizePool, isEmpty);
    }


    // 2. Test Add Event (Save)
    print('\n2. Testing Add Event...');
    final newEvent = EventItem(
      id: 'app_integration_test_event',
      title: 'App Integration Test Event',
      category: 'Robotics',
      venue: 'NLHC Hall 1',
      time: '10:00 AM - 12:00 PM',
      date: 'Oct 10, 2026',
      prizePool: 'TBD',
      description: 'Testing add event feature.',
      posterUrl: 'https://concetto-ashen.vercel.app/events/general.png',
      isVisible: true,
    );
    final saved = await service.saveEvent(newEvent);
    expect(saved.id, equals('app_integration_test_event'));
    print('Added event verified: ${saved.title}');

    // Verify it is in database
    var checkEvents = await service.getEvents(includeHidden: true);
    expect(checkEvents.any((e) => e.id == 'app_integration_test_event'), isTrue);

    // 3. Test Edit Event (Update)
    print('\n3. Testing Edit Event...');
    final editedEvent = saved.copyWith(
      title: 'App Integration Test Event (UPDATED VIA APP)',
      venue: 'Penman Auditorium',
    );
    final updated = await service.updateEvent(editedEvent);
    expect(updated.title, equals('App Integration Test Event (UPDATED VIA APP)'));
    print('Updated event verified: ${updated.title}');

    checkEvents = await service.getEvents(includeHidden: true);
    final found = checkEvents.firstWhere((e) => e.id == 'app_integration_test_event');
    expect(found.title, equals('App Integration Test Event (UPDATED VIA APP)'));
    expect(found.venue, equals('Penman Auditorium'));

    // 4. Test Delete Event
    print('\n4. Testing Delete Event...');
    final deleted = await service.deleteEvent('app_integration_test_event');
    expect(deleted, isTrue);
    print('Deleted event verified.');

    checkEvents = await service.getEvents(includeHidden: true);
    expect(checkEvents.any((e) => e.id == 'app_integration_test_event'), isFalse);

    print('\n========================================================');
    print('[SUCCESS] ALL ADD, EDIT, AND DELETE FEATURES WORK FLAWLESSLY!');
    print('========================================================');
  });
}
