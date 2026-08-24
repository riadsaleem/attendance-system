import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/report_models.dart';

class PdfService {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _loadFonts() async {
    _regular ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    _bold ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
  }

  static Future<Uint8List> generate(ReportData data) {
    return generateMulti([data]);
  }

  static Future<Uint8List> generateMulti(List<ReportData> reports) async {
    await _loadFonts();
    final pw.Font regular = _regular!;
    final pw.Font bold = _bold!;

    final pw.Document doc = pw.Document();

    for (final ReportData data in reports) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _header(data, bold, regular),
            pw.SizedBox(height: 16),
            _summaryCards(data, bold, regular),
            pw.SizedBox(height: 16),
            _studentsTable(data, bold, regular),
            pw.SizedBox(height: 12),
            _footer(regular),
          ],
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _header(
      ReportData data, pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0E7C66'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                data.titleAr,
                style: pw.TextStyle(
                    font: bold, fontSize: 20, color: PdfColors.white),
              ),
              pw.Text(
                'نظام الحضور والغياب',
                style: pw.TextStyle(
                    font: regular, fontSize: 11, color: PdfColors.white),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'الصف: ${data.className}',
            style: pw.TextStyle(
                font: regular, fontSize: 12, color: PdfColors.white),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'الفترة: ${data.periodLabel}',
            style: pw.TextStyle(
                font: regular, fontSize: 12, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryCards(
      ReportData data, pw.Font bold, pw.Font regular) {
    pw.Widget card(String label, String value, String hexColor) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          margin: const pw.EdgeInsets.symmetric(horizontal: 3),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex(hexColor),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Column(
            children: [
              pw.Text(value,
                  style: pw.TextStyle(
                      font: bold, fontSize: 18, color: PdfColors.white)),
              pw.SizedBox(height: 2),
              pw.Text(label,
                  style: pw.TextStyle(
                      font: regular, fontSize: 10, color: PdfColors.white)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        card('حاضر', '${data.summary.present}', '#16A34A'),
        card('متأخر', '${data.summary.late}', '#F59E0B'),
        card('غائب', '${data.summary.absent}', '#DC2626'),
        card(
          'نسبة الحضور',
          '${data.summary.rate.toStringAsFixed(1)}%',
          '#0E7C66',
        ),
      ],
    );
  }

  static pw.Widget _studentsTable(
      ReportData data, pw.Font bold, pw.Font regular) {
    final List<List<String>> rows = data.rows
        .asMap()
        .entries
        .map(
          (e) => <String>[
            '${e.key + 1}',
            e.value.studentName,
            '${e.value.present}',
            '${e.value.late}',
            '${e.value.absent}',
            '${e.value.rate.toStringAsFixed(0)}%',
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: <String>['#', 'اسم الطالب', 'حاضر', 'متأخر', 'غائب', 'النسبة'],
      data: rows,
      border: pw.TableBorder.all(
          color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
          font: bold, fontSize: 11, color: PdfColors.white),
      headerDecoration:
          pw.BoxDecoration(color: PdfColor.fromHex('#0E7C66')),
      cellStyle: pw.TextStyle(font: regular, fontSize: 10),
      cellAlignment: pw.Alignment.center,
      headerAlignment: pw.Alignment.center,
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1.2),
      },
      oddRowDecoration:
          pw.BoxDecoration(color: PdfColor.fromHex('#F2F8F7')),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 5),
    );
  }

  static pw.Widget _footer(pw.Font regular) {
    final String now =
        '${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'تم إنشاء هذا التقرير بواسطة تطبيق نظام الحضور والغياب',
          style: pw.TextStyle(font: regular, fontSize: 9,
              color: PdfColors.grey600),
        ),
        pw.Text(
          now,
          style: pw.TextStyle(font: regular, fontSize: 9,
              color: PdfColors.grey600),
        ),
      ],
    );
  }
}
