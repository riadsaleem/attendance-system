import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/supabase_retry.dart';
import '../domain/report_models.dart';

class ReportsRepository {
  ReportsRepository(this._client);

  final SupabaseClient _client;

  static const String _select =
      '*, students(full_name, classes(name))';

  Future<ReportData> buildReport({
    required ReportType type,
    required DateTime anchor,
    int? classId,
    required String className,
  }) {
    final (DateTime from, DateTime to, String periodLabel) =
        _resolvePeriod(type, anchor);
    return buildReportForRange(
      type: type,
      from: from,
      to: to,
      periodLabel: periodLabel,
      classId: classId,
      className: className,
    );
  }

  Future<ReportData> buildReportForRange({
    required ReportType type,
    required DateTime from,
    required DateTime to,
    required String periodLabel,
    int? classId,
    required String className,
  }) =>
      supabaseRetry(() async {
        var query = _client
            .from('attendance_logs')
            .select(_select)
            .gte('attendance_date', DateFormat('yyyy-MM-dd').format(from))
            .lte('attendance_date', DateFormat('yyyy-MM-dd').format(to));
        if (classId != null) {
          query = query.eq('students.class_id', classId);
        }
        final rows = await query.order('attendance_date');

        var rosterQuery = _client
            .from('students')
            .select('full_name')
            .eq('is_active', true);
        if (classId != null) {
          rosterQuery = rosterQuery.eq('class_id', classId);
        }
        final roster = await rosterQuery.order('full_name');

        return _aggregate(
          rows: rows,
          rosterNames: roster
              .map<String>((r) => (r['full_name'] ?? '') as String)
              .where((n) => n.isNotEmpty)
              .toList(),
          type: type,
          className: className,
          periodLabel: periodLabel,
        );
      });

  Future<List<ReportData>> buildPerClassReports({
    required ReportType type,
    required DateTime from,
    required DateTime to,
    required String periodLabel,
  }) async {
    final classes = await supabaseRetry(() => _client
        .from('classes')
        .select('id, name, grades(name)')
        .order('grade_id')
        .order('name'));

    final List<ReportData> reports = [];
    for (final Map<String, dynamic> c in classes) {
      final String gradeName =
          ((c['grades'] as Map<String, dynamic>?)?['name'] ?? '') as String;
      final String className = gradeName.isEmpty
          ? c['name'] as String
          : '$gradeName - ${c['name']}';
      final ReportData report = await buildReportForRange(
        type: type,
        from: from,
        to: to,
        periodLabel: periodLabel,
        classId: c['id'] as int,
        className: className,
      );
      if (report.rows.isNotEmpty) reports.add(report);
    }
    return reports;
  }

  ReportData _aggregate({
    required List<Map<String, dynamic>> rows,
    required List<String> rosterNames,
    required ReportType type,
    required String className,
    required String periodLabel,
  }) {
    final Map<String, List<int>> perStudent = {};
    for (final String name in rosterNames) {
      perStudent.putIfAbsent(name, () => [0, 0, 0]);
    }
    for (final Map<String, dynamic> row in rows) {
      final String status = (row['status'] ?? 'absent') as String;
      final String name =
          ((row['students'] as Map<String, dynamic>?)?['full_name'] ?? '؟')
              as String;
      if (name == '؟') continue;
      perStudent.putIfAbsent(name, () => [0, 0, 0]);
      if (status == 'present') {
        perStudent[name]![0]++;
      } else if (status == 'late') {
        perStudent[name]![1]++;
      } else {
        perStudent[name]![2]++;
      }
    }

    int present = 0, late = 0, absent = 0;
    final List<StudentReportRow> studentRows = perStudent.entries.map((e) {
      present += e.value[0];
      late += e.value[1];
      absent += e.value[2];
      return StudentReportRow(
        studentName: e.key,
        present: e.value[0],
        late: e.value[1],
        absent: e.value[2],
      );
    }).toList()
      ..sort((a, b) => b.rate.compareTo(a.rate));

    return ReportData(
      type: type,
      className: className,
      periodLabel: periodLabel,
      summary: ReportSummary(present: present, late: late, absent: absent),
      rows: studentRows,
    );
  }

  (DateTime, DateTime, String) _resolvePeriod(
      ReportType type, DateTime anchor) {
    final DateFormat dayFormat = DateFormat('d MMMM yyyy', 'ar');
    final DateFormat monthFormat = DateFormat('MMMM yyyy', 'ar');

    switch (type) {
      case ReportType.daily:
        return (anchor, anchor, dayFormat.format(anchor));
      case ReportType.weekly:
        final int daysFromSaturday = (anchor.weekday + 1) % 7;
        final DateTime from =
            anchor.subtract(Duration(days: daysFromSaturday));
        final DateTime to = from.add(const Duration(days: 6));
        return (
          from,
          to,
          '${DateFormat('d MMM', 'ar').format(from)} - ${dayFormat.format(to)}'
        );
      case ReportType.monthly:
        final DateTime from = DateTime(anchor.year, anchor.month, 1);
        final DateTime to = DateTime(anchor.year, anchor.month + 1, 0);
        return (from, to, monthFormat.format(anchor));
      case ReportType.custom:
        return (anchor, anchor, dayFormat.format(anchor));
    }
  }
}
