// SQLite database helper for GlucoTrack.
//
// Schema mirrors the Next.js Prisma schema so data can be exchanged
// between the web and Flutter apps via the JSON backup format.
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
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
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'glucotrack.db');
    final key = await KeystoreService().getDbKey();

    return openDatabase(
      path,
      password: key,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode=WAL');
        await db.execute('PRAGMA foreign_keys=ON');
      },
      onCreate: (db, _) async {
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
        await db.execute('CREATE INDEX idx_readings_timestamp ON readings(timestamp)');
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
        // NOTE: sync_state table removed (SEC-015) — was dead schema that would
        // have stored plaintext tokens. Re-add with encryption when cloud sync
        // is actually implemented.
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2: encrypted DB migration
        // For new installs, onCreate already ran at v2.
        // For upgrades from v1 (plaintext DB), the user must export their data,
        // uninstall, reinstall, and re-import. Document this in release notes.
        // No schema changes between v1 and v2 — only the storage format changed.
        if (oldVersion < 2) {
          // No-op: schema is identical; the password parameter handles encryption
        }
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ===== Readings =====
  Future<List<Reading>> getReadings() async {
    final db = await this.db;
    final rows = await db.query(
      'readings',
      orderBy: 'timestamp DESC',
    );
    return rows.map(Reading.fromDb).toList();
  }

  Future<Reading> insertReading(Reading r) async {
    final db = await this.db;
    await db.insert('readings', r.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    final rows = await db.query(
      'reminders',
      orderBy: 'time ASC',
    );
    return rows.map(Reminder.fromDb).toList();
  }

  Future<Reminder> insertReminder(Reminder r) async {
    final db = await this.db;
    await db.insert('reminders', r.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
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
}
