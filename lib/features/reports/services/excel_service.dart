import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

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
    if (clean.length > 28) clean = clean.substring(0, 28);
    return clean;
  }

  static String fileNameStamp() =>
      DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
}
