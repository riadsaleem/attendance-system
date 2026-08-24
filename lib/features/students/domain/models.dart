class Grade {
  const Grade({required this.id, required this.name});

  final int id;
  final String name;

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.name,
    required this.gradeId,
    this.gradeName = '',
  });

  final int id;
  final String name;
  final int gradeId;
  final String gradeName;

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        id: json['id'] as int,
        name: json['name'] as String,
        gradeId: json['grade_id'] as int,
        gradeName:
            (json['grades'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      );

  String get displayName =>
      gradeName.isEmpty ? name : '$gradeName - $name';
}

class Student {
  const Student({
    required this.id,
    required this.fullName,
    required this.classId,
    this.className = '',
    this.gradeName = '',
    this.guardianName,
    this.guardianPhone,
    this.fingerprintId,
    this.isActive = true,
  });

  final int id;
  final String fullName;
  final int classId;
  final String className;
  final String gradeName;
  final String? guardianName;
  final String? guardianPhone;
  final String? fingerprintId;
  final bool isActive;

  factory Student.fromJson(Map<String, dynamic> json) {
    final klass = json['classes'] as Map<String, dynamic>?;
    final grade = klass?['grades'] as Map<String, dynamic>?;
    return Student(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      classId: json['class_id'] as int,
      className: klass?['name'] as String? ?? '',
      gradeName: grade?['name'] as String? ?? '',
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      fingerprintId: json['fingerprint_id'] as String?,
      isActive: (json['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toDbJson() => {
        'full_name': fullName,
        'class_id': classId,
        'guardian_name': guardianName,
        'guardian_phone': guardianPhone,
        'fingerprint_id': fingerprintId,
        'is_active': isActive,
      };
}
