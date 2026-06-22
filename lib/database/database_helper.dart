// SQLite database helper for GlucoTrack.
//
// Schema mirrors the Next.js Prisma schema so data can be exchanged
// between the web and Flutter apps via the JSON backup format.
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/reading.dart';
import '../models/reminder.dart';

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
    return openDatabase(
      path,
      version: 1,
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
        await db.execute(
          'CREATE INDEX idx_readings_timestamp ON readings(timestamp)',
        );
        await db.execute(
          'CREATE INDEX idx_readings_type ON readings(type)',
        );

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

        await db.execute('''
          CREATE TABLE sync_state (
            id INTEGER PRIMARY KEY DEFAULT 1,
            provider TEXT NOT NULL DEFAULT '',
            connected INTEGER NOT NULL DEFAULT 0,
            account_email TEXT,
            access_token TEXT,
            refresh_token TEXT,
            expires_at INTEGER,
            last_sync_at INTEGER,
            last_sync_status TEXT,
            last_sync_error TEXT,
            drive_file_id TEXT
          )
        ''');
      },
    );
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
