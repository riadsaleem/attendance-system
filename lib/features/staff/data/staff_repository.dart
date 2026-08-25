import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/staff_models.dart';

class StaffRepository {
  StaffRepository(this._client);

  final SupabaseClient _client;

  static String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<List<Staff>> fetchAll({StaffCategory? category}) async {
    var query = _client.from('staff').select().eq('is_active', true);
    if (category != null) {
      query = query.eq('category', category.name);
    }
    final rows = await query.order('full_name');
    return rows.map(Staff.fromJson).toList();
  }

  Future<void> insert(Staff staff) =>
      _client.from('staff').insert(staff.toDbJson());

  Future<void> update(Staff staff) =>
      _client.from('staff').update(staff.toDbJson()).eq('id', staff.id);

  Future<void> delete(int id) => _client.from('staff').delete().eq('id', id);

  Future<Map<int, Map<String, dynamic>>> fetchMarksForDate(DateTime date) async {
    final rows = await _client
        .from('staff_attendance')
        .select('staff_id, status, check_in_time, check_out_time')
        .eq('attendance_date', _fmt(date));
    return {
      for (final Map<String, dynamic> row in rows)
        row['staff_id'] as int: {
          'status': (row['status'] ?? 'absent') as String,
          'check_in_time': row['check_in_time'] as String?,
          'check_out_time': row['check_out_time'] as String?,
        },
    };
  }

  Future<List<Map<String, dynamic>>> fetchStaffLogsInRange(
    int staffId,
    DateTime from,
    DateTime to,
  ) async {
    return await _client
        .from('staff_attendance')
        .select()
        .eq('staff_id', staffId)
        .gte('attendance_date', _fmt(from))
        .lte('attendance_date', _fmt(to))
        .order('attendance_date');
  }

  Future<List<Map<String, dynamic>>> fetchAllLogsInRange(
    DateTime from,
    DateTime to,
  ) async {
    return await _client
        .from('staff_attendance')
        .select()
        .gte('attendance_date', _fmt(from))
        .lte('attendance_date', _fmt(to))
        .order('attendance_date');
  }

  Future<void> upsertAttendance({
    required List<StaffAttendanceEntry> entries,
    required DateTime date,
    required String recordedBy,
  }) async {
    final String dateStr = _fmt(date);
    final rows = entries.where((e) => e.isMarked).map((e) {
      final bool absent = e.status == AttendanceMark.absent;
      return {
        'staff_id': e.staff.id,
        'attendance_date': dateStr,
        'status': e.status!.dbValue,
        'check_in_time':
            absent || e.checkIn == null ? null : e.checkIn!.toIso8601String(),
        'check_out_time':
            absent || e.checkOut == null ? null : e.checkOut!.toIso8601String(),
        'recorded_by': recordedBy,
      };
    }).toList();

    if (rows.isEmpty) return;

    await _client
        .from('staff_attendance')
        .upsert(rows, onConflict: 'staff_id,attendance_date');
  }
}
