import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import 'unit_converter.dart';

class PdfReportService {
  static Future<void> generateAndShareReport({
    required List<Reading> readings,
    required Settings settings,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    // Use a font that supports Arabic.
    // PdfGoogleFonts provides access to Google Fonts.
    final font = pw.Font.helvetica();

    final userName = settings.userName.isEmpty ? 'Patient' : settings.userName;
    final unitLabel = UnitConverter.unitLabel(settings.unit);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header - using pw.Text instead of pw.Header as it doesn't support 'style'
              pw.Text(
                'Glucose Tracking Report',
                style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Patient: $userName', style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Text('Period: ${_formatDate(startDate)} to ${_formatDate(endDate)}',
                   style: pw.TextStyle(font: font, fontSize: 14)),
              pw.SizedBox(height: 20),

              // Summary Statistics
              _buildSummarySection(readings, settings, font),

              pw.SizedBox(height: 20),

              // Readings Table
              pw.Text('Detailed Readings', style: pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: _buildReadingsTable(readings, settings, font),
              ),

              pw.SizedBox(height: 30),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Generated on ${_formatDate(DateTime.now())}',
                             style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Glucose_Report.pdf');
  }

  static pw.Widget _buildSummarySection(List<Reading> readings, Settings settings, pw.Font font) {
    if (readings.isEmpty) {
      return pw.Text('No data available for the selected period.', style: pw.TextStyle(font: font));
    }

    final values = readings.map((r) => r.value).toList();
    final avg = (values.reduce((a, b) => a + b) / values.length).round();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final unitLabel = UnitConverter.unitLabel(settings.unit);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('Average', '$avg $unitLabel', font),
          _summaryItem('Minimum', '$min $unitLabel', font),
          _summaryItem('Maximum', '$max $unitLabel', font),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(font: font, fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static List<pw.TableRow> _buildReadingsTable(List<Reading> readings, Settings settings, pw.Font font) {
    final rows = <pw.TableRow>[];

    // Header Row
    rows.add(
      pw.TableRow(
        children: [
          pw.Text('Date & Time', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          pw.Text('Type', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
          pw.Text('Value', style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    for (var r in readings) {
      rows.add(
        pw.TableRow(
          children: [
            pw.Text(_formatDateTime(r.timestamp), style: pw.TextStyle(font: font)),
            pw.Text(r.type.name, style: pw.TextStyle(font: font)),
            pw.Text('${r.value} ${UnitConverter.unitLabel(settings.unit)}', style: pw.TextStyle(font: font)),
          ],
        ),
      );
    }

    return rows;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
