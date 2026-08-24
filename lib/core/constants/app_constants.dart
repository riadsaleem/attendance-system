enum UserRole { admin, teacher, viewer;

  static UserRole fromName(String? name) => UserRole.values.firstWhere(
        (r) => r.name == name,
        orElse: () => UserRole.viewer,
      );
}

extension UserRoleX on UserRole {
  String get labelAr => switch (this) {
        UserRole.admin => 'مدير',
        UserRole.teacher => 'معلم',
        UserRole.viewer => 'مشاهد',
      };

  bool get canManageStudents => this == UserRole.admin;
  bool get canEditAttendance =>
      this == UserRole.admin || this == UserRole.teacher;
}

enum AttendanceStatus { present, late, absent;

  static AttendanceStatus fromDb(String? value) =>
      AttendanceStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => AttendanceStatus.absent,
      );
}

extension AttendanceStatusX on AttendanceStatus {
  String get labelAr => switch (this) {
        AttendanceStatus.present => 'حاضر',
        AttendanceStatus.late => 'متأخر',
        AttendanceStatus.absent => 'غائب',
      };

  String get dbValue => name;
  int get colorValue => switch (this) {
        AttendanceStatus.present => 0xFF16A34A,
        AttendanceStatus.late => 0xFFF59E0B,
        AttendanceStatus.absent => 0xFFDC2626,
      };
}
