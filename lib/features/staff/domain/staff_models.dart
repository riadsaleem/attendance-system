enum StaffCategory {
  employee,
  worker;

  static StaffCategory fromDb(String? value) => value == 'worker'
      ? StaffCategory.worker
      : StaffCategory.employee;
}

extension StaffCategoryX on StaffCategory {
  String get labelAr => switch (this) {
        StaffCategory.employee => 'موظف',
        StaffCategory.worker => 'عامل',
      };

  String get pluralAr => switch (this) {
        StaffCategory.employee => 'الموظفون',
        StaffCategory.worker => 'العمال',
      };
}

enum AttendanceMark {
  present,
  late,
  absent;

  static AttendanceMark fromDb(String? value) =>
      AttendanceMark.values.firstWhere(
        (s) => s.name == value,
        orElse: () => AttendanceMark.absent,
      );
}

extension AttendanceMarkX on AttendanceMark {
  String get labelAr => switch (this) {
        AttendanceMark.present => 'حاضر',
        AttendanceMark.late => 'متأخر',
        AttendanceMark.absent => 'غائب',
      };

  String get dbValue => name;
  int get colorValue => switch (this) {
        AttendanceMark.present => 0xFF16A34A,
        AttendanceMark.late => 0xFFF59E0B,
        AttendanceMark.absent => 0xFFDC2626,
      };
}

class Staff {
  const Staff({
    required this.id,
    required this.fullName,
    required this.category,
    this.jobTitle,
    this.phone,
    this.fingerprintId,
    this.branchId,
    this.isActive = true,
  });

  final int id;
  final String fullName;
  final StaffCategory category;
  final String? jobTitle;
  final String? phone;
  final String? fingerprintId;
  final int? branchId;
  final bool isActive;

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        category: StaffCategory.fromDb(json['category'] as String?),
        jobTitle: json['job_title'] as String?,
        phone: json['phone'] as String?,
        fingerprintId: json['fingerprint_id'] as String?,
        branchId: json['branch_id'] as int?,
        isActive: (json['is_active'] ?? true) as bool,
      );

  Map<String, dynamic> toDbJson() => {
        'full_name': fullName,
        'category': category.name,
        'job_title': jobTitle,
        'phone': phone,
        'fingerprint_id': fingerprintId,
        'branch_id': branchId,
        'is_active': isActive,
      };
}

class StaffAttendanceEntry {
  StaffAttendanceEntry({
    required this.staff,
    this.status,
    this.checkIn,
    this.checkOut,
  });

  final Staff staff;
  AttendanceMark? status;
  DateTime? checkIn;
  DateTime? checkOut;

  bool get isMarked => status != null;
}
