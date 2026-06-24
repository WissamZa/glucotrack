import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../providers/providers.dart';
import '../utils/export_import.dart';
import '../utils/pdf_report_service.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.exportData)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionIcon(
            icon: Icons.upload,
            title: strings.exportData,
            subtitle: strings.isRtl
                ? 'احفظ بياناتك أو شاركها كملف JSON أو CSV'
                : 'Save or share your data as JSON or CSV',
          ),
          const SizedBox(height: 16),
          _ExportCard(
            icon: Icons.picture_as_pdf,
            title: 'PDF Report',
            subtitle: strings.isRtl
                ? 'تقرير مفصل للطبيب — ملف PDF'
                : 'Detailed report for doctor — PDF',
            color: const Color(0xFFEF4444),
            onTap: () => _exportPdf(context),
          ),
          const SizedBox(height: 16),
          _ExportCard(
            icon: Icons.code,
            title: 'JSON',
            subtitle: strings.isRtl
                ? 'نسخة احتياطية كاملة — قراءات وتذكيرات'
                : 'Full backup — readings & reminders',
            color: const Color(0xFF3B82F6),
            onTap: () => _exportJson(context),
          ),
          _ExportCard(
            icon: Icons.table_chart,
            title: 'CSV',
            subtitle: strings.isRtl
                ? 'جدول القراءات فقط — يفتح في Excel'
                : 'Readings table only — opens in Excel',
            color: const Color(0xFF10B981),
            onTap: () => _exportCsv(context),
          ),
          const SizedBox(height: 32),
          _SectionIcon(
            icon: Icons.download,
            title: strings.importData,
            subtitle: strings.isRtl
                ? 'استرجع بياناتك من ملف نسخة احتياطية'
                : 'Restore your data from a backup file',
          ),
          const SizedBox(height: 16),
          _ExportCard(
            icon: Icons.restore,
            title: 'JSON',
            subtitle: strings.isRtl
                ? 'استيراد من ملف نسخة احتياطية'
                : 'Import from backup file',
            color: const Color(0xFFF59E0B),
            onTap: () => _importJson(context),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final strings = AppStrings.of(context);

    try {
      final DateTimeRange? range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: strings.isRtl ? 'اختر الفترة' : 'Select Range',
      );

      if (range == null) return;

      final rProv = context.read<ReadingsProvider>();
      final sProv = context.read<SettingsProviderState>();

      final readings = rProv.rawReadings.where((r) {
        return r.timestamp.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
               r.timestamp.isBefore(range.end.add(const Duration(days: 1)));
      }).toList();

      if (readings.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.isRtl ? 'لا توجد بيانات لهذه الفترة' : 'No data for this period')),
          );
        }
        return;
      }

      await PdfReportService.generateAndShareReport(
        readings: readings,
        settings: sProv.settings,
        startDate: range.start,
        endDate: range.end,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.exportSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, strings.importError); // Reuse generic error
      }
    }
  }

  Future<void> _exportJson(BuildContext context) async {
    final rProv = context.read<ReadingsProvider>();
    final remProv = context.read<RemindersProvider>();
    final strings = AppStrings.of(context);

    final data = ExportData(
      readings: rProv.rawReadings,
      reminders: remProv.reminders.toList(),
      exportedAt: DateTime.now(),
    );

    await DataExporter.shareJson(data);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.exportSuccess)),
      );
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final rProv = context.read<ReadingsProvider>();
    final strings = AppStrings.of(context);

    await DataExporter.shareCsv(rProv.rawReadings);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.exportSuccess)),
      );
    }
  }

  Future<void> _importJson(BuildContext context) async {
    final strings = AppStrings.of(context);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        _showError(context, strings.importError);
        return;
      }

      final jsonStr = String.fromCharCodes(file.bytes!);
      final imported = DataExporter.importFromJson(jsonStr);

      if (imported == null) {
        _showError(context, strings.importError);
        return;
      }

      final rProv = context.read<ReadingsProvider>();
      final remProv = context.read<RemindersProvider>();

      // Merge imported readings (skip duplicates by ID)
      final existingIds = rProv.rawReadings.map((r) => r.id).toSet();
      int importedCount = 0;
      for (final reading in imported.readings) {
        if (!existingIds.contains(reading.id)) {
          await rProv.add(reading);
          importedCount++;
        }
      }

      // Merge imported reminders
      for (final reminder in imported.reminders) {
        await remProv.add(reminder);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.importSuccess(importedCount))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, strings.importError);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionIcon({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(16),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
