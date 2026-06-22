// Data Export/Import utility — JSON and CSV backup/restore
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/reading.dart';
import '../models/reminder.dart';

class ExportData {
  final List<Reading> readings;
  final List<Reminder> reminders;
  final DateTime exportedAt;
  final String version;

  ExportData({
    required this.readings,
    required this.reminders,
    required this.exportedAt,
    this.version = '1.1.0',
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt.toIso8601String(),
        'readings': readings.map((r) => r.toDb()).toList(),
        'reminders': reminders.map((r) => r.toDb()).toList(),
      };

  factory ExportData.fromJson(Map<String, dynamic> json) => ExportData(
        version: json['version'] as String? ?? '1.0.0',
        exportedAt: DateTime.parse(json['exportedAt'] as String),
        readings: (json['readings'] as List)
            .map((r) => Reading.fromDb(r as Map<String, dynamic>))
            .toList(),
        reminders: (json['reminders'] as List)
            .map((r) => Reminder.fromDb(r as Map<String, dynamic>))
            .toList(),
      );
}

class DataExporter {
  /// Export readings and reminders as JSON
  static Future<String> exportToJson(ExportData data) async {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data.toJson());
  }

  /// Export readings as CSV
  static String exportReadingsToCsv(List<Reading> readings) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(
        'ID,Value (mg/dL),Type,DateTime,Notes,Carbs (g),Insulin (units)');
    // Rows
    for (final r in readings) {
      final dt = r.timestamp.toIso8601String();
      final notes = r.notes?.replaceAll(',', ' ').replaceAll('\n', ' ') ?? '';
      buffer.writeln(
          '${r.id},${r.value},${r.type.dbValue},$dt,"$notes",${r.carbs ?? ''},${r.insulin ?? ''}');
    }
    return buffer.toString();
  }

  /// Share JSON file
  static Future<void> shareJson(ExportData data) async {
    final jsonStr = await exportToJson(data);
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/glucotrack_backup_${_fileTimestamp()}.json');
    await file.writeAsString(jsonStr);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'GlucoTrack Backup',
      ),
    );
  }

  /// Share CSV file
  static Future<void> shareCsv(List<Reading> readings) async {
    final csvStr = exportReadingsToCsv(readings);
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/glucotrack_readings_${_fileTimestamp()}.csv');
    await file.writeAsString(csvStr);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'GlucoTrack Readings',
      ),
    );
  }

  /// Save JSON to app's documents directory
  static Future<String> saveJsonToLocal(ExportData data) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/glucotrack_backup_${_fileTimestamp()}.json');
    final jsonStr = await exportToJson(data);
    await file.writeAsString(jsonStr);
    return file.path;
  }

  /// Import from JSON string
  static ExportData? importFromJson(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ExportData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static String _fileTimestamp() {
    final now = DateTime.now();
    return '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
