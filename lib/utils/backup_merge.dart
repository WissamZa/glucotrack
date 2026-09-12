// Shared backup-merge logic — used by JSON import (Export screen) and by
// Google Drive restore (Settings), so both paths behave identically.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/providers.dart';
import 'export_import.dart';

/// Merges [imported] backup data into the live providers, skipping
/// duplicates: readings/metrics/reminders by ID, water by the higher
/// cups-per-day. Returns the number of newly imported readings.
Future<int> mergeImportedData(BuildContext context, ExportData imported) async {
  final rProv = context.read<ReadingsProvider>();
  final remProv = context.read<RemindersProvider>();
  final healthProv = context.read<HealthMetricsProvider>();

  final existingIds = rProv.rawReadings.map((r) => r.id).toSet();
  var importedCount = 0;
  for (final reading in imported.readings) {
    if (!existingIds.contains(reading.id)) {
      await rProv.add(reading);
      importedCount++;
    }
  }

  final existingReminderIds = remProv.reminders.map((r) => r.id).toSet();
  for (final reminder in imported.reminders) {
    if (!existingReminderIds.contains(reminder.id)) {
      await remProv.add(reminder);
    }
  }

  final existingMetricIds = healthProv.metrics.map((m) => m.id).toSet();
  for (final metric in imported.healthMetrics) {
    if (!existingMetricIds.contains(metric.id)) {
      await healthProv.addMetric(metric);
    }
  }

  for (final water in imported.waterLog) {
    if (water.cups > healthProv.cupsForDate(water.date)) {
      await healthProv.setWater(water.date, water.cups);
    }
  }

  return importedCount;
}

/// Builds the full-backup payload from the current providers.
Future<ExportData> collectExportData(BuildContext context) async {
  final rProv = context.read<ReadingsProvider>();
  final remProv = context.read<RemindersProvider>();
  final healthProv = context.read<HealthMetricsProvider>();
  return ExportData(
    readings: rProv.rawReadings,
    reminders: remProv.reminders.toList(),
    healthMetrics: healthProv.metrics,
    waterLog: healthProv.waterLog,
    exportedAt: DateTime.now(),
  );
}
