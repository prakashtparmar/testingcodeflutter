import 'package:flutter/foundation.dart';
import 'package:snap_check/models/day_log_detail_response_model.dart';
import 'package:snap_check/models/day_log_store_locations_data_model.dart';
import 'package:snap_check/models/day_log_store_locations_response_model.dart';
import 'package:snap_check/models/day_logs_data_model.dart';
import 'package:snap_check/models/login_response_model.dart';
import 'package:snap_check/models/post_day_log_response_model.dart';
import 'package:snap_check/models/register_response_model.dart';
import 'package:snap_check/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        is_sync INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
        CREATE TABLE tour_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT
        )
      ''');
    await db.execute('''
        CREATE TABLE vehicle_types (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT
        )
      ''');
    await db.execute('''
        CREATE TABLE tour_purposes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT
        )
      ''');

    await db.execute('''
      CREATE TABLE day_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        tour_purpose_id INTEGER,
        vehicle_type_id INTEGER,
        tour_type_id INTEGER,
        party_id INTEGER,
        place_visit TEXT,
        opening_km TEXT,
        opening_km_image TEXT,
        opening_km_latitude REAL,
        opening_km_longitude REAL,
        closing_km TEXT,
        closing_km_image TEXT,
        closing_km_latitude REAL,
        closing_km_longitude REAL,
        note TEXT,
        approval_status TEXT DEFAULT 'pending',
        approved_by INTEGER,
        approval_reason TEXT,
        approved_at TEXT
      )
    ''');
    await db.execute('''
        CREATE TABLE day_log_locations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          day_log_id INTEGER,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          FOREIGN KEY (day_log_id) REFERENCES day_logs(id) ON DELETE SET NULL
        )
    ''');
  }

  Future<RegisterResponseModel> registerUser(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final db = await database;
    final userMap = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
    };

    final id = await db.insert('users', userMap);
    final user = User(
      id: id,
      email: email,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    return RegisterResponseModel.fromJson({
      'message': 'User registered successfully.',
      'data': user.toJson(),
    });
  }

  Future<LoginResponseModel?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      final user = result.first;

      final token = '${user['id']}|${DateTime.now().millisecondsSinceEpoch}';
      debugPrint("token $token");
      final userData = {
        'id': user['id'],
        'first_name': user['first_name'],
        'last_name': user['last_name'],
        'address_line1': null,
        'address_line2': null,
        'city_id': null,
        'state_id': null,
        'country_id': null,
        'email': user['email'],
        'email_verified_at': null,
        'created_at': '2025-04-25T19:28:24.000000Z',
        'updated_at': '2025-04-25T19:28:24.000000Z',
        'deleted_at': null,
      };

      final loginData = {'token': token, 'user': userData};

      return LoginResponseModel.fromJson({
        'success': true,
        'message': 'User login successfully.',
        'data': loginData,
      });
    } else {
      return LoginResponseModel.fromJson({
        'success': false,
        'message': 'Invalid email or password.',
        'data': null,
      });
    }
  }

  Future<List<DayLogsDataModel>> getDayLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT 
      day_logs.*,
      tour_purposes.name AS tour_purpose_name,
      tour_types.name AS tour_type_name,
      vehicle_types.name AS vehicle_type_name
    FROM day_logs
    LEFT JOIN tour_purposes ON day_logs.tour_purpose_id = tour_purposes.id
    LEFT JOIN tour_types ON day_logs.tour_type_id = tour_types.id
    LEFT JOIN vehicle_types ON day_logs.vehicle_type_id = vehicle_types.id
  ''');
    return result.map((map) => DayLogsDataModel.fromJson(map)).toList();
  }

  Future<DayLogDetailResponseModel> getDayLogById(int dayLogId) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
    SELECT 
      day_logs.*,
      tour_purposes.id AS tour_purpose_id,
      tour_purposes.name AS tour_purpose_name,
      tour_purposes.created_at AS tour_purpose_created_at,
      tour_purposes.updated_at AS tour_purpose_updated_at,
      tour_purposes.deleted_at AS tour_purpose_deleted_at,

      tour_types.id AS tour_type_id,
      tour_types.name AS tour_type_name,
      tour_types.created_at AS tour_type_created_at,
      tour_types.updated_at AS tour_type_updated_at,
      tour_types.deleted_at AS tour_type_deleted_at,

      vehicle_types.id AS vehicle_type_id,
      vehicle_types.name AS vehicle_type_name,
      vehicle_types.created_at AS vehicle_type_created_at,
      vehicle_types.updated_at AS vehicle_type_updated_at,
      vehicle_types.deleted_at AS vehicle_type_deleted_at

    FROM day_logs
    LEFT JOIN tour_purposes ON day_logs.tour_purpose_id = tour_purposes.id
    LEFT JOIN tour_types ON day_logs.tour_type_id = tour_types.id
    LEFT JOIN vehicle_types ON day_logs.vehicle_type_id = vehicle_types.id
    WHERE day_logs.id = ?
  ''',
      [dayLogId],
    );

    if (result.isEmpty) {
      return DayLogDetailResponseModel.fromJson({
        "success": false,
        "message": "Day log not found",
        "data": null,
      });
    }

    final row = result.first;

    final responseJson = {
      "success": true,
      "message": "Day log fetched successfully",
      "data": {
        "id": row['id'],
        "tour_purpose_id": row['tour_purpose_id'],
        "vehicle_type_id": row['vehicle_type_id'],
        "tour_type_id": row['tour_type_id'],
        "party_id": row['party_id'],
        "place_visit": row['place_visit'],
        "opening_km": row['opening_km'],
        "opening_km_image": row['opening_km_image'],
        "closing_km": row['closing_km'],
        "closing_km_image": row['closing_km_image'],
        "note": row['note'],
        "created_at": row['created_at'],
        "updated_at": row['updated_at'],
        "deleted_at": row['deleted_at'],
        "tour_purpose": {
          "id": row['tour_purpose_id'],
          "name": row['tour_purpose_name'],
          "created_at": row['tour_purpose_created_at'],
          "updated_at": row['tour_purpose_updated_at'],
          "deleted_at": row['tour_purpose_deleted_at'],
        },
        "vehicle_type": {
          "id": row['vehicle_type_id'],
          "name": row['vehicle_type_name'],
          "created_at": row['vehicle_type_created_at'],
          "updated_at": row['vehicle_type_updated_at'],
          "deleted_at": row['vehicle_type_deleted_at'],
        },
        "tour_type": {
          "id": row['tour_type_id'],
          "name": row['tour_type_name'],
          "created_at": row['tour_type_created_at'],
          "updated_at": row['tour_type_updated_at'],
          "deleted_at": row['tour_type_deleted_at'],
        },
      },
    };

    return DayLogDetailResponseModel.fromJson(responseJson);
  }

  Future<PostDayLogsResponseModel> addDayLog(
    int? userId,
    int? tourPurposeId,
    int? vehicleTypeId,
    int? tourTypeId,
    int? partyId,
    String? placeVisit,
    String? openingKm,
    String? openingKmImage,
    double? openingKmLatitude,
    double? openingKmLongitude,
  ) async {
    final db = await database;
    final dayLog = {
      'user_id': userId,
      'tour_purpose_id': tourPurposeId,
      'vehicle_type_id': vehicleTypeId,
      'tour_type_id': tourTypeId,
      'party_id': partyId,
      'place_visit': placeVisit,
      'opening_km': openingKm,
      'opening_km_image': openingKmImage,
    };

    try {
      final id = await db.insert('day_logs', dayLog);

      final responseMap = {
        'success': true,
        'message': 'Day logs created successfully',
        'data': {
          'id': id,
          'tour_purpose_id': tourPurposeId,
          'vehicle_type_id': vehicleTypeId,
          'tour_type_id': tourTypeId,
          'party_id': partyId,
          'place_visit': placeVisit,
          'opening_km': openingKm,
          'opening_km_image': openingKmImage,
        },
      };

      return PostDayLogsResponseModel.fromJson(responseMap);
    } catch (e) {
      return PostDayLogsResponseModel.fromJson({
        'success': false,
        'message': 'Failed to create day log: ${e.toString()}',
        'data': null,
      });
    }
  }

  Future<DayLogStoreLocationResponseModel> saveDayLogLocations(
    Map<String, dynamic> body,
  ) async {
    final db = await database;

    try {
      final int dayLogId = body['day_log_id'];
      final List locations = body['locations'];
      final now = DateTime.now().toIso8601String();

      final List<DayLogStoreLocationsDataModel> insertedLocations = [];

      for (final loc in locations) {
        final locationMap = {
          'day_log_id': dayLogId,
          'latitude': loc['latitude'],
          'longitude': loc['longitude'],
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        };

        final id = await db.insert('day_log_locations', locationMap);

        insertedLocations.add(
          DayLogStoreLocationsDataModel(
            id: id,
            dayLogId: dayLogId.toString(),
            latitude: loc['latitude'],
            longitude: loc['longitude'],
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      return DayLogStoreLocationResponseModel(
        success: true,
        message: "Locations saved successfully",
        data: insertedLocations,
      );
    } catch (e) {
      return DayLogStoreLocationResponseModel(
        success: false,
        message: "Error saving locations: ${e.toString()}",
        data: [],
      );
    }
  }

  Future<PostDayLogsResponseModel> closeDayLog(
    int? dayLogId,
    String? closingKm,
    double? closingKmLatitude,
    double? closingKmLongitude,
    String? closingKmImage,
    String? note,
  ) async {
    final db = await database;

    final updateMap = {
      'closing_km': closingKm,
      'closing_km_latitude': closingKmLatitude,
      'closing_km_longitude': closingKmLongitude,
      'closing_km_image': closingKmImage,
      'note': note,
    };

    try {
      final rowsAffected = await db.update(
        'day_logs',
        updateMap,
        where: 'id = ?',
        whereArgs: [dayLogId],
      );

      if (rowsAffected == 0) {
        return PostDayLogsResponseModel.fromJson({
          'success': false,
          'message': 'No day log found with ID $dayLogId',
          'data': null,
        });
      }

      return PostDayLogsResponseModel.fromJson({
        'success': true,
        'message': 'Day log closed successfully',
        'data': null,
      });
    } catch (e) {
      return PostDayLogsResponseModel.fromJson({
        'success': false,
        'message': 'Failed to close day log: ${e.toString()}',
        'data': null,
      });
    }
  }
}
