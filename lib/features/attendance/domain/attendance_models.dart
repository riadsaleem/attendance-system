import '../../../core/constants/app_constants.dart';
import '../../students/domain/models.dart';

class AttendanceLog {
  const AttendanceLog({
    required this.id,
    required this.studentId,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.note,
    this.studentName = '',
  });

  final int id;
  final int studentId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? note;
  final String studentName;

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    final student = json['students'] as Map<String, dynamic>?;
    return AttendanceLog(
      id: json['id'] as int,
      studentId: json['student_id'] as int,
      date: DateTime.parse(json['attendance_date'] as String),
      status: AttendanceStatus.fromDb(json['status'] as String?),
      checkInTime: json['check_in_time'] == null
          ? null
          : DateTime.parse(json['check_in_time'] as String),
      checkOutTime: json['check_out_time'] == null
          ? null
          : DateTime.parse(json['check_out_time'] as String),
      note: json['note'] as String?,
      studentName: student?['full_name'] as String? ?? '',
    );
  }
}

class AttendanceEntry {
  AttendanceEntry({required this.student, this.status});

  final Student student;
  AttendanceStatus? status;

  bool get isMarked => status != null;
}

class AttendanceSummary {
  const AttendanceSummary({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
    this.unmarked = 0,
  });

  final int present;
  final int late;
  final int absent;
  final int unmarked;

  int get total => present + late + absent + unmarked;
  int get marked => present + late + absent;
  double get rate =>
      marked == 0 ? 0 : (present + late) / marked * 100;

  factory AttendanceSummary.fromEntries(
      List<AttendanceEntry> entries) {
    int present = 0, late = 0, absent = 0, unmarked = 0;
    for (final e in entries) {
      switch (e.status) {
        case AttendanceStatus.present:
          present++;
        case AttendanceStatus.late:
          late++;
        case AttendanceStatus.absent:
          absent++;
        case null:
          unmarked++;
      }
    }
    return AttendanceSummary(
        present: present, late: late, absent: absent, unmarked: unmarked);
  }
}
