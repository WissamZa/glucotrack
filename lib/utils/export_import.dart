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

/// Result of an import operation — either success with data, or failure with error.
class ImportResult {
  final bool success;
  final ExportData? data;
  final String? error;
  final String? errorDetail;

  ImportResult.success(this.data)
      : success = true, error = null, errorDetail = null;
  ImportResult.failure(this.error, {this.errorDetail})
      : success = false, data = null;
}

class DataExporter {
  /// Export readings and reminders as JSON
  static Future<String> exportToJson(ExportData data) async {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data.toJson());
  }

  /// Export readings as CSV (RFC 4180 compliant with formula injection defense)
  static String exportReadingsToCsv(List<Reading> readings) {
    final buffer = StringBuffer();
    // Header - quote fields per RFC 4180
    buffer.writeln(
        '"ID","Value (mg/dL)","Type","DateTime","Notes","Carbs (g)","Insulin (units)"');
    // Rows
    for (final r in readings) {
      final dt = r.timestamp.toIso8601String();
      buffer.writeln([
        _csvEscape(r.id),
        r.value.toString(),
        _csvEscape(r.type.dbValue),
        _csvEscape(dt),
        _csvEscape(r.notes),
        _csvEscape(r.carbs?.toString()),
        _csvEscape(r.insulin?.toString()),
      ].join(','));
    }
    return buffer.toString();
  }

  /// RFC 4180 + CSV formula injection defense.
  /// - Wraps value in double quotes
  /// - Doubles any embedded double quotes
  /// - Prefixes with single quote if value starts with =,+,-,@,tab,CR
  static String _csvEscape(String? value) {
    if (value == null || value.isEmpty) return '""';
    var v = value.replaceAll('"', '""');
    // CSV formula injection defense
    if (RegExp(r'^[=+\-@\t\r]').hasMatch(v)) {
      v = "'$v";
    }
    return '"$v"';
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

  /// Import from JSON string with schema validation.
  /// Returns a structured result — check [ImportResult.success] and
  /// [ImportResult.error] for details.
  static ImportResult importFromJson(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr);
      if (json is! Map<String, dynamic>) {
        return ImportResult.failure('Invalid format: not a JSON object');
      }
      // Version check
      final version = json['version'] as String?;
      if (version == null) {
        return ImportResult.failure('Missing version field');
      }
      if (!version.startsWith('1.')) {
        return ImportResult.failure(
          'Unsupported version: $version. This app supports v1.x exports.',
        );
      }
      // Required fields check
      if (json['readings'] is! List) {
        return ImportResult.failure('Invalid readings field: expected array');
      }
      if (json['reminders'] is! List) {
        return ImportResult.failure('Invalid reminders field: expected array');
      }
      final data = ExportData.fromJson(json);
      return ImportResult.success(data);
    } on FormatException catch (e) {
      return ImportResult.failure('Invalid JSON: ${e.message}');
    } on TypeError catch (e) {
      return ImportResult.failure('Schema mismatch: $e');
    } catch (e) {
      return ImportResult.failure('Import failed', errorDetail: e.toString());
    }
  }

  static String _fileTimestamp() {
    final now = DateTime.now();
    return '${now.year}${_two(now.month)}${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
