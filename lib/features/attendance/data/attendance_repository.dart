import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/supabase_retry.dart';
import '../domain/attendance_models.dart';

class AttendanceRepository {
  AttendanceRepository(this._client);

  final SupabaseClient _client;

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<List<AttendanceLog>> fetchForDate(
    DateTime date, {
    int? classId,
  }) =>
      supabaseRetry(() async {
        var query = _client
            .from('attendance_logs')
            .select('*, students(id, full_name, class_id)')
            .eq('attendance_date', _fmt(date));
        if (classId != null) {
          query = query.eq('students.class_id', classId);
        }
        final rows = await query;
        return rows.map(AttendanceLog.fromJson).toList();
      });

  Future<List<AttendanceLog>> fetchRange(
    DateTime from,
    DateTime to, {
    int? classId,
  }) =>
      supabaseRetry(() async {
        var query = _client
            .from('attendance_logs')
            .select('*, students(id, full_name, class_id)')
            .gte('attendance_date', _fmt(from))
            .lte('attendance_date', _fmt(to));
        if (classId != null) {
          query = query.eq('students.class_id', classId);
        }
        final rows = await query;
        return rows.map(AttendanceLog.fromJson).toList();
      });

  Future<void> upsertEntries({
    required List<AttendanceEntry> entries,
    required DateTime date,
    required String recordedBy,
  }) async {
    final String dateStr = _fmt(date);
    final rows = entries.where((e) => e.isMarked).map((e) {
      final bool absent = e.status == AttendanceStatus.absent;
      return {
        'student_id': e.student.id,
        'attendance_date': dateStr,
        'status': e.status!.dbValue,
        'check_in_time':
            absent ? null : DateTime.now().toIso8601String(),
        'recorded_by': recordedBy,
      };
    }).toList();

    if (rows.isEmpty) return;

    await _client
        .from('attendance_logs')
        .upsert(rows, onConflict: 'student_id,attendance_date');
  }
}
