import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter/foundation.dart';
import '../../models/event_item.dart';

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
      final db = await Db.create(connectionUri);
      await db.open().timeout(const Duration(seconds: 3));
      _db = db;
      return _db;
    } catch (e) {
      debugPrint('MongoService connection notice: $e');
      try {
        await _db?.close();
      } catch (_) {}
      _db = null;
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

          if (!includeHidden) {
            return list.where((e) => e.isVisible).toList();
          }
          return list;
        }
      }
    } catch (e) {
      debugPrint('MongoService getEvents error: $e.');
    }

    return const [];
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
    return null;
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
        return !res.hasWriteErrors;
      }
    } catch (e) {
      debugPrint('MongoService saveEvent error: $e');
    }
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
        return true;
      }
    } catch (e) {
      debugPrint('MongoService updateEvent error: $e');
    }
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
        return !res.hasWriteErrors;
      }
    } catch (e) {
      debugPrint('MongoService deleteEvent error: $e');
    }
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
        return true;
      }
    } catch (e) {
      debugPrint('MongoService toggleVisibility error: $e');
    }
    return false;
  }



  Future<void> dispose() async {
    try {
      if (_db != null && _db!.state == State.open) {
        await _db!.close();
      }
    } catch (_) {}
  }
}
