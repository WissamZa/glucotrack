// SQLite database helper for GlucoTrack.
//
// Schema mirrors the Next.js Prisma schema so data can be exchanged
// between the web and Flutter apps via the JSON backup format.
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

import '../models/health_metric.dart';
import '../models/medication_info.dart';
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
      // followed by the additive migrations. One source of truth per table
      // version means the migration path stays exercised by tests.
      await createSchemaV2(db);
      await migrateToV3(db);
      await migrateToV4(db);
      await migrateToV5(db);
      await migrateToV6(db);
      await migrateToV7(db);
      await migrateToV8(db);
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
      // v4 — additive only: richer medication schedules (weekday mask +
      // multiple times per day), the medication-taken log, and the
      // uses_insulin preference. Never touches existing rows.
      if (oldVersion < 4) {
        await migrateToV4(db);
      }
      // v5 — additive only: structured dose (form + amount), an optional
      // RxNorm link per reminder, and the offline medication cache.
      if (oldVersion < 5) {
        await migrateToV5(db);
      }
      // v6 — the medication cache becomes multi-source (saudi/rxnorm/
      // openfda). Pure cache: dropping and recreating loses nothing.
      if (oldVersion < 6) {
        await migrateToV6(db);
      }
      // v7 — additive: indications / ingredients / otc columns on the cache.
      if (oldVersion < 7) {
        await migrateToV7(db);
      }
      // v8 — additive: dosage / method columns on the cache.
      if (oldVersion < 8) {
        await migrateToV8(db);
      }
    }

    if (isMobile) {
      return sqlcipher.openDatabase(
        path,
        password: key,
        version: 8,
        onConfigure: onConfigure,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
    } else {
      return databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 8,
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

  /// v3 → v4 migration — additive only: richer medication schedules
  /// (weekday mask + multiple times per day), the medication-taken log,
  /// and the uses_insulin preference.
  @visibleForTesting
  static Future<void> migrateToV4(Database db) async {
    await db.execute(
      'ALTER TABLE reminders ADD COLUMN days_mask INTEGER NOT NULL DEFAULT 127',
    );
    await db.execute('ALTER TABLE reminders ADD COLUMN times TEXT');
    await db.execute(
      'ALTER TABLE settings ADD COLUMN uses_insulin INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medication_log (
        id TEXT PRIMARY KEY,
        reminder_id TEXT NOT NULL,
        taken_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_medication_log_taken ON medication_log(taken_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_medication_log_reminder ON medication_log(reminder_id)',
    );
  }

  /// v4 → v5 migration — additive only: structured dose fields on reminders
  /// (form + amount + optional RxNorm id) and the offline medication cache.
  @visibleForTesting
  /// v5 → v6 — the medication cache gains a source column (composite PK).
  /// The table holds disposable lookup data only, so it is recreated.
  @visibleForTesting
  static Future<void> migrateToV6(Database db) async {
    await db.execute('DROP TABLE IF EXISTS medication_cache');
    await _createMedicationCache(db);
  }

  /// v6 → v7 — additive columns for the enriched details page.
  @visibleForTesting
  static Future<void> migrateToV7(Database db) async {
    await db.execute(
      'ALTER TABLE medication_cache ADD COLUMN indications TEXT',
    );
    await db.execute(
      'ALTER TABLE medication_cache ADD COLUMN ingredients TEXT',
    );
    await db.execute('ALTER TABLE medication_cache ADD COLUMN otc INTEGER');
  }

  /// v7 → v8 — additive: recommended-dosage and method-of-use columns.
  @visibleForTesting
  static Future<void> migrateToV8(Database db) async {
    await db.execute('ALTER TABLE medication_cache ADD COLUMN dosage TEXT');
    await db.execute('ALTER TABLE medication_cache ADD COLUMN method TEXT');
  }

  static Future<void> migrateToV5(Database db) async {
    await db.execute('ALTER TABLE reminders ADD COLUMN dose_form TEXT');
    await db.execute('ALTER TABLE reminders ADD COLUMN dose_amount REAL');
    await db.execute('ALTER TABLE reminders ADD COLUMN rxcui TEXT');
    await _createMedicationCache(db);
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

  static Future<void> _createMedicationCache(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medication_cache (
        source TEXT NOT NULL DEFAULT 'rxnorm',
        rxcui TEXT NOT NULL,
        name TEXT NOT NULL,
        synonym TEXT,
        dose_form TEXT,
        strength TEXT,
        tty TEXT,
        indications TEXT,
        ingredients TEXT,
        dosage TEXT,
        method TEXT,
        otc INTEGER,
        fetched_at INTEGER NOT NULL,
        PRIMARY KEY (source, rxcui)
      )
    ''');
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

  // ===== Medication log =====
  Future<List<MedicationLogEntry>> getMedicationLog({
    String? reminderId,
  }) async {
    final db = await this.db;
    final rows = await db.query(
      'medication_log',
      where: reminderId != null ? 'reminder_id = ?' : null,
      whereArgs: reminderId != null ? [reminderId] : null,
      orderBy: 'taken_at DESC',
    );
    return rows.map(MedicationLogEntry.fromDb).toList();
  }

  Future<MedicationLogEntry> insertMedicationLog(MedicationLogEntry e) async {
    final db = await this.db;
    await db.insert(
      'medication_log',
      e.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return e;
  }

  Future<void> deleteMedicationLog(String id) async {
    final db = await this.db;
    await db.delete('medication_log', where: 'id = ?', whereArgs: [id]);
  }

  /// Removes the whole log trail of a deleted reminder (keeps the table tidy
  /// without orphan rows).
  Future<void> deleteMedicationLogForReminder(String reminderId) async {
    final db = await this.db;
    await db.delete(
      'medication_log',
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
    );
  }

  // ===== Medication cache (multi-source offline data) =====
  Future<MedicationInfo?> getMedicationFromCache(
    String source,
    String rxcui,
  ) async {
    final db = await this.db;
    final rows = await db.query(
      'medication_cache',
      where: 'source = ? AND rxcui = ?',
      whereArgs: [source, rxcui],
      limit: 1,
    );
    return rows.isEmpty ? null : MedicationInfo.fromDb(rows.first);
  }

  Future<List<MedicationInfo>> searchMedicationCache(
    String source,
    String query,
  ) async {
    final db = await this.db;
    final q = '%${query.trim()}%';
    final rows = await db.query(
      'medication_cache',
      where: 'source = ? AND (name LIKE ? OR synonym LIKE ?)',
      whereArgs: [source, q, q],
      orderBy: 'name ASC',
      limit: 10,
    );
    return rows.map(MedicationInfo.fromDb).toList();
  }

  /// All cached entries regardless of source (used by the Medications tab
  /// browse view).
  Future<List<MedicationInfo>> allCachedMedications({int limit = 20}) async {
    final db = await this.db;
    final rows = await db.query(
      'medication_cache',
      orderBy: 'fetched_at DESC',
      limit: limit,
    );
    return rows.map(MedicationInfo.fromDb).toList();
  }

  Future<void> upsertMedicationCache(MedicationInfo info) async {
    final db = await this.db;
    await db.insert(
      'medication_cache',
      info.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
