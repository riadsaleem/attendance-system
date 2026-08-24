enum ReportType { daily, weekly, monthly }

extension ReportTypeX on ReportType {
  String get labelAr => switch (this) {
        ReportType.daily => 'يومي',
        ReportType.weekly => 'أسبوعي',
        ReportType.monthly => 'شهري',
      };
}

class ReportSummary {
  const ReportSummary({
    required this.present,
    required this.late,
    required this.absent,
  });

  final int present;
  final int late;
  final int absent;

  int get total => present + late + absent;
  double get rate => total == 0 ? 0 : (present + late) / total * 100;
}

class StudentReportRow {
  const StudentReportRow({
    required this.studentName,
    required this.present,
    required this.late,
    required this.absent,
  });

  final String studentName;
  final int present;
  final int late;
  final int absent;

  int get totalDays => present + late + absent;
  double get rate => totalDays == 0 ? 0 : (present + late) / totalDays * 100;
}

class ReportData {
  const ReportData({
    required this.type,
    required this.className,
    required this.periodLabel,
    required this.summary,
    required this.rows,
  });

  final ReportType type;
  final String className;
  final String periodLabel;
  final ReportSummary summary;
  final List<StudentReportRow> rows;

  String get titleAr => switch (type) {
        ReportType.daily => 'تقرير الحضور اليومي',
        ReportType.weekly => 'تقرير الحضور الأسبوعي',
        ReportType.monthly => 'تقرير الحضور الشهري',
      };

  String get textSummary {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(titleAr);
    buffer.writeln('الصف: $className');
    buffer.writeln('الفترة: $periodLabel');
    buffer.writeln('──────────────────');
    buffer.writeln('إجمالي السجلات: ${summary.total}');
    buffer.writeln('حاضر: ${summary.present} | متأخر: ${summary.late} | غائب: ${summary.absent}');
    buffer.writeln('نسبة الحضور: ${summary.rate.toStringAsFixed(1)}%');
    if (rows.isNotEmpty) {
      buffer.writeln('──────────────────');
      for (final StudentReportRow row in rows) {
        buffer.writeln(
            '${row.studentName}: حاضر ${row.present} | متأخر ${row.late} | غائب ${row.absent}');
      }
    }
    return buffer.toString();
  }
}
