import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../../models/event_item.dart';
import 'mock_data.dart';

class MongoService {
  static const String host = 'f4a6506a-05dc-49cf-90c6-30e3b01ee57e.asia-south2.firestore.goog:443';
  static const String database = 'concetto';

  // SCRAM credentials
  static String username = 'concettoapp';
  static String password = 'lS6Wa1mjNF_nZZNzcCuI1cdwDNiITEaPrM6vwBb6UeqBAfZD';

  static String get connectionUri {
    if (username.isEmpty || password.isEmpty) return '';
    final encUser = Uri.encodeComponent(username);
    final encPass = Uri.encodeComponent(password);
    return 'mongodb://$encUser:$encPass@$host/$database?loadBalanced=true&tls=true&authMechanism=SCRAM-SHA-256&retryWrites=false';
  }

  Db? _db;

  Future<Db?> _getDb() async {
    if (connectionUri.isEmpty) return null;
    if (_db != null && _db!.state == State.open) return _db;
    try {
      _db = await Db.create(connectionUri);
      await _db!.open();
      return _db;
    } catch (e) {
      debugPrint('MongoService connection error: $e');
      return null;
    }
  }

  /// Fetches all events from MongoDB Firestore Enterprise collection 'events'
  Future<List<EventItem>> getEvents({bool includeHidden = false}) async {
    try {
      final db = await _getDb();
      if (db != null) {
        final col = db.collection('events');
        final docs = await col.find().toList();
        if (docs.isNotEmpty) {
          final list = docs.map((d) {
            final id = (d['_id'] ?? d['id'] ?? '').toString();
            return EventItem.fromJson(Map<String, dynamic>.from(d), id);
          }).toList();

          // Sync local mock data cache
          for (final ev in list) {
            final idx = MockData.events.indexWhere((e) => e.id == ev.id);
            if (idx >= 0) {
              MockData.events[idx] = ev;
            } else {
              MockData.events.add(ev);
            }
          }

          if (!includeHidden) {
            return list.where((e) => e.isVisible).toList();
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint('MongoService getEvents error: $e. Falling back to local events.');
    }

    // Fallback to local MockData if offline or credentials not yet entered
    if (!includeHidden) {
      return MockData.events.where((e) => e.isVisible).toList();
    }
    return MockData.events;
  }

  /// Looks up a single event by ID from MongoDB
  Future<EventItem?> getEventById(String eventId) async {
    try {
      final db = await _getDb();
      if (db != null) {
        final col = db.collection('events');
        final doc = await col.findOne(where.eq('_id', eventId));
        if (doc != null) {
          final id = (doc['_id'] ?? doc['id'] ?? eventId).toString();
          return EventItem.fromJson(Map<String, dynamic>.from(doc), id);
        }
      }
    } catch (e) {
      debugPrint('MongoService getEventById error: $e');
    }
    final local = MockData.events.where((e) => e.id == eventId);
    return local.isNotEmpty ? local.first : null;
  }

  /// Saves a newly created event to MongoDB
  Future<bool> saveEvent(EventItem event) async {
    try {
      final db = await _getDb();
      if (db != null) {
        final col = db.collection('events');
        final data = event.toJson();
        data['_id'] = event.id;
        data['id'] = event.id;
        final res = await col.insertOne(data);
        debugPrint('MongoService: Event "${event.title}" saved to MongoDB (errors: ${res.hasWriteErrors}).');
        _syncLocalMock(event);
        return !res.hasWriteErrors;
      }
    } catch (e) {
      debugPrint('MongoService saveEvent error: $e');
    }
    _syncLocalMock(event);
    return false;
  }

  /// Updates an existing event in MongoDB
  Future<bool> updateEvent(EventItem event) async {
    try {
      final db = await _getDb();
      if (db != null) {
        final col = db.collection('events');
        final data = event.toJson();
        data['_id'] = event.id;
        data['id'] = event.id;

        final setMap = Map<String, dynamic>.from(data)..remove('_id');
        var modifier = modify;
        setMap.forEach((key, value) {
          modifier = modifier.set(key, value);
        });

        final res = await col.modernUpdate(
          where.eq('_id', event.id),
          modifier,
          upsert: true,
        );
        debugPrint('MongoService: Event "${event.title}" updated in MongoDB: $res');
        _syncLocalMock(event);
        return true;
      }
    } catch (e) {
      debugPrint('MongoService updateEvent error: $e');
    }
    _syncLocalMock(event);
    return false;
  }

  /// Deletes an event from MongoDB
  Future<bool> deleteEvent(String eventId) async {
    try {
      final db = await _getDb();
      if (db != null) {
        final col = db.collection('events');
        final res = await col.deleteOne(where.eq('_id', eventId));
        debugPrint('MongoService: Event "$eventId" deleted from MongoDB (errors: ${res.hasWriteErrors}).');
        MockData.events.removeWhere((e) => e.id == eventId);
        return !res.hasWriteErrors;
      }
    } catch (e) {
      debugPrint('MongoService deleteEvent error: $e');
    }
    MockData.events.removeWhere((e) => e.id == eventId);
    return true;
  }

  /// Toggles an event's visibility in MongoDB
  Future<bool> toggleVisibility(String eventId, bool isVisible) async {
    try {
      final db = await _getDb();
      if (db != null) {
        final col = db.collection('events');
        final res = await col.modernUpdate(
          where.eq('_id', eventId),
          modify.set('isVisible', isVisible),
        );
        debugPrint('MongoService: Event "$eventId" visibility set to $isVisible: $res');
        final idx = MockData.events.indexWhere((e) => e.id == eventId);
        if (idx >= 0) {
          MockData.events[idx] = MockData.events[idx].copyWith(isVisible: isVisible);
        }
        return true;
      }
    } catch (e) {
      debugPrint('MongoService toggleVisibility error: $e');
    }
    final idx = MockData.events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      MockData.events[idx] = MockData.events[idx].copyWith(isVisible: isVisible);
    }
    return false;
  }

  void _syncLocalMock(EventItem event) {
    final idx = MockData.events.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      MockData.events[idx] = event;
    } else {
      MockData.events.insert(0, event);
    }
  }

  /// Seeds all 55 events into MongoDB
  Future<({int count, String? error})> seedMockEventsToMongo() async {
    try {
      final db = await _getDb();
      if (db == null) {
        return (count: 0, error: 'Database connection failed. Please verify SCRAM credentials.');
      }
      final col = db.collection('events');
      int count = 0;
      for (final event in MockData.events) {
        final data = event.toJson();
        data['_id'] = event.id;
        data['id'] = event.id;

        final setMap = Map<String, dynamic>.from(data)..remove('_id');
        var modifier = modify;
        setMap.forEach((key, value) {
          modifier = modifier.set(key, value);
        });

        await col.modernUpdate(where.eq('_id', event.id), modifier, upsert: true);
        count++;
      }
      return (count: count, error: null);
    } catch (e) {
      return (count: 0, error: e.toString());
    }
  }

  Future<void> dispose() async {
    try {
      if (_db != null && _db!.state == State.open) {
        await _db!.close();
      }
    } catch (_) {}
  }
}
