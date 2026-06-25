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

    // Load Arabic-capable fonts from Google Fonts
    final font = await PdfGoogleFonts.notoSansArabicRegular();
    final fontBold = await PdfGoogleFonts.notoSansArabicBold();
    final isArabic = settings.language == Language.ar;

    final userName = settings.userName.isEmpty ? 'Patient' : settings.userName;
    final unitLabel = UnitConverter.unitLabel(settings.unit);

    // Use MultiPage for auto-pagination
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              isArabic ? 'تقرير متابعة السكر' : 'Glucose Tracking Report',
              style: pw.TextStyle(font: fontBold, fontSize: 20),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${isArabic ? "المريض" : "Patient"}: $userName  |  '
              '${isArabic ? "الفترة" : "Period"}: '
              '${_formatDate(startDate)} - ${_formatDate(endDate)}',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.Divider(),
          ],
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'CONFIDENTIAL - Medical Record  |  Page ${ctx.pageNumber} of ${ctx.pagesCount}  |  Generated ${_formatDate(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey),
          ),
        ),
        build: (ctx) => [
          _buildSummarySection(readings, settings, font, fontBold, unitLabel, isArabic),
          pw.SizedBox(height: 16),
          pw.Text(
            isArabic ? 'القراءات التفصيلية' : 'Detailed Readings',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          _buildReadingsTable(readings, settings, font, fontBold, unitLabel),
        ],
      ),
    );

    final fileName =
        'Glucose_Report_${_formatDate(startDate)}_to_${_formatDate(endDate)}.pdf';
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  }

  static pw.Widget _buildSummarySection(
    List<Reading> readings, Settings settings,
    pw.Font font, pw.Font fontBold, String unitLabel, bool isArabic,
  ) {
    if (readings.isEmpty) {
      return pw.Text(
        isArabic ? 'لا توجد بيانات للفترة المحددة.' : 'No data available for the selected period.',
        style: pw.TextStyle(font: font),
      );
    }

    // Single-fold computation of avg/min/max (PERF-008 fix)
    var sum = 0, min = readings.first.value, max = readings.first.value;
    for (final r in readings) {
      sum += r.value;
      if (r.value < min) min = r.value;
      if (r.value > max) max = r.value;
    }
    final avg = (sum / readings.length).round();

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem(isArabic ? 'المتوسط' : 'Average', '$avg $unitLabel', font, fontBold),
          _summaryItem(isArabic ? 'الأدنى' : 'Minimum', '$min $unitLabel', font, fontBold),
          _summaryItem(isArabic ? 'الأعلى' : 'Maximum', '$max $unitLabel', font, fontBold),
        ],
      ),
    );
  }

  static pw.Widget _summaryItem(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 16)),
      ],
    );
  }

  static pw.Widget _buildReadingsTable(
    List<Reading> readings, Settings settings,
    pw.Font font, pw.Font fontBold, String unitLabel,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(100),
        1: const pw.FixedColumnWidth(80),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['Date & Time', 'Type', 'Value', 'Notes'].map((h) =>
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(h, style: pw.TextStyle(font: fontBold, fontSize: 9)),
            )).toList(),
        ),
        ...readings.map((r) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6),
              child: pw.Text(_formatDateTime(r.timestamp),
                style: pw.TextStyle(font: font, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(6),
              child: pw.Text(r.type.name,
                style: pw.TextStyle(font: font, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${r.value} $unitLabel',
                style: pw.TextStyle(font: fontBold, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(6),
              child: pw.Text(r.notes ?? '',
                style: pw.TextStyle(font: font, fontSize: 9))),
          ],
        )),
      ],
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _formatDateTime(DateTime d) =>
      '${_formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
