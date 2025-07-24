import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocationDatabaseService {
  static const String _locationDatabaseName = 'locations.db';
  Database? _database;

  Future<void> initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _locationDatabaseName);

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE locations(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              recorded_at INTEGER NOT NULL,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              gps_status INTEGER NOT NULL,
              battery_level INTEGER,
              synced INTEGER DEFAULT 0
            )
          ''');
        },
      );
    } catch (e) {
      throw Exception('Database initialization error: $e');
    }
  }

  Future<void> saveLocation(Map<String, dynamic> location) async {
    if (_database == null) return;

    try {
      await _database!.insert('locations', {
        'recorded_at': DateTime.now().millisecondsSinceEpoch,
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'gps_status': location['gps_status'],
        'battery_level': location['battery_percentage'],
        'synced': 0,
      });
    } catch (e) {
      throw Exception('Error saving location to database: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLocations() async {
    if (_database == null) return [];
    try {
      return await _database!.query(
        'locations',
        where: 'synced = 0',
        orderBy: 'recorded_at ASC',
      );
    } catch (e) {
      throw Exception('Error getting unsynced locations: $e');
    }
  }

  Future<void> markLocationsAsSynced(List<int> ids) async {
    if (_database == null || ids.isEmpty) return;
    try {
      await _database!.update('locations', {
        'synced': 1,
      }, where: 'id IN (${ids.join(',')})');
    } catch (e) {
      throw Exception('Error marking locations as synced: $e');
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<int?> getLastInsertId() async {
    if (_database == null) return null;
    try {
      final result = await _database!.rawQuery('SELECT last_insert_rowid()');
      return result.isNotEmpty ? result.first.values.first as int : null;
    } catch (e) {
      throw Exception('Error getting last insert ID: $e');
    }
  }
}
