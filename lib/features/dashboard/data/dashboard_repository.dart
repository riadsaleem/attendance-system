import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/supabase_retry.dart';
import '../domain/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient _client;

  Future<DashboardData> fetch() => supabaseRetry(() async {
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));

    final rows = await _client
        .from('attendance_logs')
        .select('attendance_date, status, students(full_name)')
        .gte('attendance_date', DateFormat('yyyy-MM-dd').format(from));

    final Map<String, Map<String, int>> byDate = {};
    final Map<String, Map<String, int>> byStudent = {};

    for (final Map<String, dynamic> row in rows) {
      final String date = row['attendance_date'] as String;
      final String status = (row['status'] ?? 'absent') as String;
      final String name =
          ((row['students'] as Map<String, dynamic>?)?['full_name'] ?? '؟')
              as String;

      byDate.putIfAbsent(date, () => {'present': 0, 'late': 0, 'absent': 0});
      byDate[date]![status] = (byDate[date]![status] ?? 0) + 1;

      byStudent.putIfAbsent(
          name, () => {'present': 0, 'late': 0, 'absent': 0});
      byStudent[name]![status] = (byStudent[name]![status] ?? 0) + 1;
    }

    final String todayStr = DateFormat('yyyy-MM-dd').format(now);
    final Map<String, int> todayMap =
        byDate[todayStr] ?? {'present': 0, 'late': 0, 'absent': 0};
    final AttendanceSummaryLite today = AttendanceSummaryLite(
      present: todayMap['present']!,
      late: todayMap['late']!,
      absent: todayMap['absent']!,
    );

    final List<DayStat> week = List.generate(7, (i) {
      final DateTime day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final String key = DateFormat('yyyy-MM-dd').format(day);
      final Map<String, int>? m = byDate[key];
      return DayStat(
        day: day,
        present: m?['present'] ?? 0,
        late: m?['late'] ?? 0,
        absent: m?['absent'] ?? 0,
      );
    });

    final List<StudentRisk> risks = byStudent.entries.map((e) {
      final int absent = e.value['absent'] ?? 0;
      final int total =
          (e.value['present'] ?? 0) + (e.value['late'] ?? 0) + absent;
      return StudentRisk(
          studentName: e.key, absentDays: absent, totalDays: total);
    }).toList()
      ..sort((a, b) => b.absenceRate.compareTo(a.absenceRate));

    return DashboardData(
      today: today,
      week: week,
      risks: risks.take(5).toList(),
    );
  });
}
