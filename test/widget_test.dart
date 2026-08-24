import 'package:attendance_system/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('fromName parses valid roles', () {
      expect(UserRole.fromName('admin'), UserRole.admin);
      expect(UserRole.fromName('teacher'), UserRole.teacher);
      expect(UserRole.fromName('viewer'), UserRole.viewer);
    });

    test('fromName falls back to viewer for unknown role', () {
      expect(UserRole.fromName('unknown'), UserRole.viewer);
      expect(UserRole.fromName(null), UserRole.viewer);
    });

    test('permissions follow role hierarchy', () {
      expect(UserRole.admin.canManageStudents, isTrue);
      expect(UserRole.teacher.canManageStudents, isFalse);
      expect(UserRole.viewer.canEditAttendance, isFalse);
      expect(UserRole.teacher.canEditAttendance, isTrue);
    });
  });

  group('AttendanceStatus', () {
    test('fromDb parses stored values', () {
      expect(AttendanceStatus.fromDb('present'), AttendanceStatus.present);
      expect(AttendanceStatus.fromDb('late'), AttendanceStatus.late);
      expect(AttendanceStatus.fromDb('absent'), AttendanceStatus.absent);
    });

    test('fromDb falls back to absent for invalid value', () {
      expect(AttendanceStatus.fromDb('invalid'), AttendanceStatus.absent);
    });

    test('Arabic labels are correct', () {
      expect(AttendanceStatus.present.labelAr, 'حاضر');
      expect(AttendanceStatus.late.labelAr, 'متأخر');
      expect(AttendanceStatus.absent.labelAr, 'غائب');
    });
  });
}
