import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../features/staff/domain/staff_hours.dart';
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
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(child: _summaryCards(data, bold, regular)),
                pw.Container(
                  width: 110,
                  height: 110,
                  padding: const pw.EdgeInsets.all(4),
                  child: _pieChart(data, regular, bold),
                ),
              ],
            ),
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
  static pw.Widget _pieChart(ReportData data, pw.Font regular, pw.Font bold) {
    final int total =
        data.summary.present + data.summary.late + data.summary.absent;
    if (total == 0) return pw.Container();

    double pct(int v) => v / total * 100;

    final List<pw.PieDataSet> slices = [
      if (data.summary.present > 0)
        pw.PieDataSet(
          value: pct(data.summary.present),
          color: PdfColor.fromHex('#16A34A'),
          innerRadius: 5,
          legendPosition: pw.PieLegendPosition.inside,
          legendStyle: pw.TextStyle(
              font: bold, fontSize: 7, color: PdfColors.white),
        ),
      if (data.summary.late > 0)
        pw.PieDataSet(
          value: pct(data.summary.late),
          color: PdfColor.fromHex('#F59E0B'),
          innerRadius: 5,
          legendPosition: pw.PieLegendPosition.inside,
          legendStyle: pw.TextStyle(
              font: bold, fontSize: 7, color: PdfColors.white),
        ),
      if (data.summary.absent > 0)
        pw.PieDataSet(
          value: pct(data.summary.absent),
          color: PdfColor.fromHex('#DC2626'),
          innerRadius: 5,
          legendPosition: pw.PieLegendPosition.inside,
          legendStyle: pw.TextStyle(
              font: bold, fontSize: 7, color: PdfColors.white),
        ),
    ];

    return pw.Chart(
      grid: pw.PieGrid(),
      datasets: slices,
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
          'يتم إنشاء هذا التقرير بواسطة تطبيق نظام متتبع البصمة',
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

  static Future<Uint8List> generateStaffHours({
    required String title,
    required List<StaffHoursRow> rows,
    List<StaffHoursDetail> details = const [],
  }) async {
    await _loadFonts();
    final pw.Font regular = _regular!;
    final pw.Font bold = _bold!;

    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0E7C66'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                  font: bold, fontSize: 16, color: PdfColors.white),
            ),
          ),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'الاسم',
              'أيام الدوام',
              'إجمالي الساعات',
              'تأخير',
              'إضافي',
              'تعادل أيام',
            ],
            data: rows
                .map((r) => [
                      r.name,
                      '${r.presentDays}',
                      r.totalHours.toStringAsFixed(1),
                      r.lateHours.toStringAsFixed(1),
                      r.overtimeHours.toStringAsFixed(1),
                      r.extraDays.toStringAsFixed(2),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
                font: bold, fontSize: 10, color: PdfColors.white),
            headerDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#0E7C66')),
            cellStyle: pw.TextStyle(font: regular, fontSize: 9),
            cellAlignment: pw.Alignment.center,
            oddRowDecoration:
                pw.BoxDecoration(color: PdfColor.fromHex('#F2F8F7')),
          ),
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('التفاصيل اليومية',
                style: pw.TextStyle(font: bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const [
                'التاريخ',
                'الحالة',
                'دخول',
                'انصراف',
                'ساعات',
                'تأخير',
                'إضافي',
              ],
              data: details
                  .map((d) => [
                        d.dateLabel,
                        d.statusLabel,
                        d.inLabel,
                        d.outLabel,
                        d.hoursLabel,
                        d.lateLabel,
                        d.extraLabel,
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(
                  font: bold, fontSize: 9, color: PdfColors.white),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor.fromHex('#0E7C66')),
              cellStyle: pw.TextStyle(font: regular, fontSize: 8),
              cellAlignment: pw.Alignment.center,
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
            'تطبيق متتبع البصمة — تطوير: رياض سليم',
            style: pw.TextStyle(font: regular, fontSize: 8,
                color: PdfColors.grey600),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
