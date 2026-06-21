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

  // ===== Seed (idempotent — only runs if DB is empty) =====
  Future<void> seedIfEmpty() async {
    final db = await this.db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM readings'),
    );
    if ((count ?? 0) > 0) return;

    final now = DateTime.now();
    final dayMs = 24 * 60 * 60 * 1000;
    final patterns = <ReadingType, List<_SeedPattern>>{
      ReadingType.fasting: [
        _SeedPattern(7, 110, 25),
      ],
      ReadingType.afterMeal: [
        _SeedPattern(9, 165, 30),
        _SeedPattern(15, 175, 35),
      ],
      ReadingType.beforeMeal: [
        _SeedPattern(13, 105, 20),
      ],
      ReadingType.beforeSleep: [
        _SeedPattern(22, 130, 25),
      ],
    };

    final batch = db.batch();
    for (var d = 6; d >= 0; d--) {
      patterns.forEach((type, list) {
        for (final pat in list) {
          final ts = DateTime.fromMillisecondsSinceEpoch(
            now.millisecondsSinceEpoch - d * dayMs,
          ).copyWith(hour: pat.hour, minute: pat.minute);
          final value = (pat.base + (DateTime.now().millisecond % 2 == 0 ? 1 : -1) * pat.variance)
              .clamp(60, 280);
          batch.insert(
            'readings',
            Reading(
              id: 'seed-${d}-${type.name}-${pat.hour}',
              value: value,
              type: type,
              timestamp: ts,
            ).toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }

    // Default reminders
    batch.insert(
      'reminders',
      const Reminder(
        id: 'rem-1',
        time: '07:00',
        label: 'قياس الصائم',
        type: ReadingType.fasting,
        enabled: true,
      ).toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      'reminders',
      const Reminder(
        id: 'rem-2',
        time: '14:00',
        label: 'بعد الغداء',
        type: ReadingType.afterMeal,
        enabled: true,
      ).toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await batch.commit(noResult: true);
  }
}

class _SeedPattern {
  final int hour;
  final int minute;
  final int base;
  final int variance;
  _SeedPattern(this.hour, this.base, this.variance) : minute = 0;
}
