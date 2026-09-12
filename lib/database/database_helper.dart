// SQLite database helper for GlucoTrack.
//
// Schema mirrors the Next.js Prisma schema so data can be exchanged
// between the web and Flutter apps via the JSON backup format.
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

import '../models/health_metric.dart';
import '../models/reading.dart';
import '../models/reminder.dart';
import '../services/keystore_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final bool isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final String dbPath;
    if (isMobile) {
      dbPath = await sqlcipher.getDatabasesPath();
    } else {
      dbPath = await databaseFactory.getDatabasesPath();
    }
    final path = p.join(dbPath, 'glucotrack.db');
    final key = await KeystoreService().getDbKey();

    Future<void> onConfigure(Database db) async {
      try {
        await db.execute('PRAGMA journal_mode=WAL');
      } on Exception catch (e) {
        debugPrint('Failed to set WAL mode: $e');
      }
      await db.execute('PRAGMA foreign_keys=ON');
    }

    Future<void> onCreate(Database db, int version) async {
      // Fresh installs walk the exact same path as upgrades: the v2 schema
      // followed by the additive v3 migration. One source of truth per table
      // version means the migration path stays exercised by tests.
      await createSchemaV2(db);
      await migrateToV3(db);
    }

    Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        // No-op: schema is identical; the password parameter handles encryption
      }
      // v3 — additive only: new tables and nullable/defaulted columns.
      // Existing readings/reminders/settings rows are never touched.
      if (oldVersion < 3) {
        await migrateToV3(db);
      }
    }

    if (isMobile) {
      return sqlcipher.openDatabase(
        path,
        password: key,
        version: 3,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
    } else {
      return databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 3,
          onConfigure: onConfigure,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
        ),
      );
    }
  }

  /// The pre-1.3.0 (v2) schema, unchanged. Kept public (visible for testing)
  /// so the migration test can recreate an old database, seed it with data,
  /// and prove that [migrateToV3] preserves it.
  @visibleForTesting
  static Future<void> createSchemaV2(Database db) async {
    await db.execute('''
      CREATE TABLE readings (
        id TEXT PRIMARY KEY,
        value INTEGER NOT NULL,
        type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        notes TEXT,
        carbs INTEGER,
        insulin INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_readings_timestamp ON readings(timestamp)',
    );
    await db.execute('CREATE INDEX idx_readings_type ON readings(type)');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        time TEXT NOT NULL,
        label TEXT NOT NULL,
        type TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        language TEXT NOT NULL DEFAULT 'ar',
        theme TEXT NOT NULL DEFAULT 'classic',
        diabetes_type TEXT NOT NULL DEFAULT 'type2',
        target_min INTEGER NOT NULL DEFAULT 80,
        target_max INTEGER NOT NULL DEFAULT 180,
        unit TEXT NOT NULL DEFAULT 'mg_dL',
        user_name TEXT NOT NULL DEFAULT '',
        onboarded INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// v2 → v3 migration — additive only: new tables and nullable/defaulted
  /// columns. Never drops or rewrites existing rows.
  @visibleForTesting
  static Future<void> migrateToV3(Database db) async {
    await db.execute(
      "ALTER TABLE reminders ADD COLUMN kind TEXT NOT NULL DEFAULT 'measurement'",
    );
    await db.execute('ALTER TABLE settings ADD COLUMN height_cm REAL');
    await _createHealthMetrics(db);
    await _createWaterLog(db);
  }

  static Future<void> _createHealthMetrics(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS health_metrics (
        id TEXT PRIMARY KEY,
        weight_kg REAL,
        systolic INTEGER,
        diastolic INTEGER,
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_health_metrics_timestamp ON health_metrics(timestamp)',
    );
  }

  static Future<void> _createWaterLog(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS water_log (
        date TEXT PRIMARY KEY,
        cups INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ===== Readings =====
  Future<List<Reading>> getReadings() async {
    final db = await this.db;
    final rows = await db.query('readings', orderBy: 'timestamp DESC');
    return rows.map(Reading.fromDb).toList();
  }

  Future<Reading> insertReading(Reading r) async {
    final db = await this.db;
    await db.insert(
      'readings',
      r.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return r;
  }

  Future<Reading> updateReading(Reading r) async {
    final db = await this.db;
    await db.update('readings', r.toDb(), where: 'id = ?', whereArgs: [r.id]);
    return r;
  }

  Future<void> deleteReading(String id) async {
    final db = await this.db;
    await db.delete('readings', where: 'id = ?', whereArgs: [id]);
  }

  // ===== Reminders =====
  Future<List<Reminder>> getReminders() async {
    final db = await this.db;
    final rows = await db.query('reminders', orderBy: 'time ASC');
    return rows.map(Reminder.fromDb).toList();
  }

  Future<Reminder> insertReminder(Reminder r) async {
    final db = await this.db;
    await db.insert(
      'reminders',
      r.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return r;
  }

  Future<Reminder> updateReminder(Reminder r) async {
    final db = await this.db;
    await db.update('reminders', r.toDb(), where: 'id = ?', whereArgs: [r.id]);
    return r;
  }

  Future<void> deleteReminder(String id) async {
    final db = await this.db;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ===== Settings (singleton) =====
  Future<Map<String, dynamic>?> getSettingsRow() async {
    final db = await this.db;
    final rows = await db.query('settings', where: 'id = 1', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertSettings(Map<String, dynamic> data) async {
    final db = await this.db;
    final existing = await getSettingsRow();
    if (existing == null) {
      await db.insert('settings', {'id': 1, ...data});
    } else {
      await db.update('settings', data, where: 'id = 1');
    }
  }

  // ===== Health metrics (weight / blood pressure) =====
  Future<List<HealthMetric>> getHealthMetrics() async {
    final db = await this.db;
    final rows = await db.query('health_metrics', orderBy: 'timestamp DESC');
    return rows.map(HealthMetric.fromDb).toList();
  }

  Future<HealthMetric> insertHealthMetric(HealthMetric m) async {
    final db = await this.db;
    await db.insert(
      'health_metrics',
      m.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return m;
  }

  Future<void> deleteHealthMetric(String id) async {
    final db = await this.db;
    await db.delete('health_metrics', where: 'id = ?', whereArgs: [id]);
  }

  // ===== Water log =====
  Future<List<WaterEntry>> getWaterLog() async {
    final db = await this.db;
    final rows = await db.query('water_log', orderBy: 'date DESC');
    return rows.map(WaterEntry.fromDb).toList();
  }

  /// Upsert the cup count for the given day.
  Future<void> setWaterCups(String dateKey, int cups) async {
    final db = await this.db;
    await db.insert('water_log', {
      'date': dateKey,
      'cups': cups,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
