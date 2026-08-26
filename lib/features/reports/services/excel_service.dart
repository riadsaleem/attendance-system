import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../../features/staff/domain/staff_hours.dart';
import '../domain/report_models.dart';

class ExcelService {
  static Uint8List generate(List<ReportData> reports) {
    final Excel excel = Excel.createExcel();
    String currentSheet = excel.getDefaultSheet() ?? 'Sheet1';

    for (final ReportData report in reports) {
      final String sheetName = _safeSheetName(
        reports.length == 1 ? report.titleAr : report.className,
      );
      if (sheetName != currentSheet) {
        excel.rename(currentSheet, sheetName);
        currentSheet = sheetName;
      }
      final Sheet sheet = excel[currentSheet];

      List<TextCellValue> row1 = [TextCellValue('')];
      sheet.appendRow(row1);

      sheet.appendRow([
        TextCellValue(reports.length == 1 ? report.titleAr : report.className),
      ]);
      sheet.appendRow([TextCellValue('الفترة: ${report.periodLabel}')]);
      sheet.appendRow([TextCellValue('')]);

      sheet.appendRow([
        TextCellValue('حاضر'),
        TextCellValue('متأخر'),
        TextCellValue('غائب'),
        TextCellValue('نسبة الحضور'),
      ]);
      sheet.appendRow([
        TextCellValue('${report.summary.present}'),
        TextCellValue('${report.summary.late}'),
        TextCellValue('${report.summary.absent}'),
        TextCellValue('${report.summary.rate.toStringAsFixed(1)}%'),
      ]);
      sheet.appendRow([TextCellValue('')]);

      sheet.appendRow([
        TextCellValue('#'),
        TextCellValue('اسم الطالب'),
        TextCellValue('حاضر'),
        TextCellValue('متأخر'),
        TextCellValue('غائب'),
        TextCellValue('النسبة'),
      ]);

      var index = 1;
      for (final StudentReportRow row in report.rows) {
        sheet.appendRow([
          TextCellValue('$index'),
          TextCellValue(row.studentName),
          TextCellValue('${row.present}'),
          TextCellValue('${row.late}'),
          TextCellValue('${row.absent}'),
          TextCellValue('${row.rate.toStringAsFixed(0)}%'),
        ]);
        index++;
      }

      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([
        TextCellValue(
            'تم إنشاء هذا التقرير بواسطة تطبيق نظام الحضور — تطوير: رياض سليم'),
      ]);
    }

    final List<int>? bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  static String _safeSheetName(String name) {
    String clean = name
        .replaceAll(RegExp(r'[\\/*?:\[\]]'), '-')
        .trim();
    if (clean.isEmpty) clean = 'تقرير';
    if (clean.length > 28) {
      clean = clean.substring(0, 28);
      final int lastSpace = clean.lastIndexOf(' ');
      if (lastSpace > 10) clean = clean.substring(0, lastSpace);
    }
    return clean;
  }

  static String fileNameStamp() =>
      DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  static Uint8List generateStaffHours({
    required String title,
    required List<StaffHoursRow> rows,
    List<StaffHoursDetail> details = const [],
    List<String> summaryLines = const [],
  }) {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    sheet.appendRow([TextCellValue(title)]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('الاسم'),
      TextCellValue('أيام الدوام'),
      TextCellValue('إجمالي الساعات'),
      TextCellValue('ساعات التأخير'),
      TextCellValue('ساعات إضافية'),
      TextCellValue('تعادل أيام إضافية'),
    ]);
    for (final StaffHoursRow row in rows) {
      sheet.appendRow([
        TextCellValue(row.name),
        TextCellValue('${row.presentDays}'),
        TextCellValue(row.totalHours.toStringAsFixed(1)),
        TextCellValue(row.lateHours.toStringAsFixed(1)),
        TextCellValue(row.overtimeHours.toStringAsFixed(1)),
        TextCellValue(row.extraDays.toStringAsFixed(2)),
      ]);
    }

    if (details.isNotEmpty) {
      sheet.appendRow([TextCellValue('')]);
      sheet.appendRow([TextCellValue('التفاصيل اليومية')]);
      sheet.appendRow([
        TextCellValue('التاريخ'),
        TextCellValue('الحالة'),
        TextCellValue('دخول'),
        TextCellValue('انصراف'),
        TextCellValue('ساعات'),
        TextCellValue('تأخير'),
        TextCellValue('إضافي'),
      ]);
      for (final StaffHoursDetail d in details) {
        sheet.appendRow([
          TextCellValue(d.dateLabel),
          TextCellValue(d.statusLabel),
          TextCellValue(d.inLabel),
          TextCellValue(d.outLabel),
          TextCellValue(d.hoursLabel),
          TextCellValue(d.lateLabel),
          TextCellValue(d.extraLabel),
        ]);
      }
    }

    if (summaryLines.isNotEmpty) {
      sheet.appendRow([TextCellValue('')]);
      for (final String line in summaryLines) {
        sheet.appendRow([TextCellValue(line)]);
      }
    }

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('يتم إنشاء هذا التقرير بواسطة تطبيق نظام متتبع البصمة — تطوير: رياض سليم'),
    ]);

    final List<int>? bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }
}
