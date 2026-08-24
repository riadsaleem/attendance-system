class DayStat {
  const DayStat({
    required this.day,
    this.present = 0,
    this.late = 0,
    this.absent = 0,
  });

  final DateTime day;
  final int present;
  final int late;
  final int absent;

  int get marked => present + late + absent;
  double get rate => marked == 0 ? 0 : (present + late) / marked * 100;
}

enum RiskLevel {
  low,
  medium,
  high;

  static RiskLevel fromAbsenceRate(double rate) {
    if (rate > 0.30) return RiskLevel.high;
    if (rate > 0.15) return RiskLevel.medium;
    return RiskLevel.low;
  }
}

extension RiskLevelX on RiskLevel {
  String get labelAr => switch (this) {
        RiskLevel.low => 'منتظم',
        RiskLevel.medium => 'يحتاج متابعة',
        RiskLevel.high => 'خطر عالي',
      };

  int get colorValue => switch (this) {
        RiskLevel.low => 0xFF16A34A,
        RiskLevel.medium => 0xFFF59E0B,
        RiskLevel.high => 0xFFDC2626,
      };
}

class StudentRisk {
  const StudentRisk({
    required this.studentName,
    required this.absentDays,
    required this.totalDays,
  });

  final String studentName;
  final int absentDays;
  final int totalDays;

  double get absenceRate => totalDays == 0 ? 0 : absentDays / totalDays;
  RiskLevel get level => RiskLevel.fromAbsenceRate(absenceRate);
}

class AttendanceSummaryLite {
  const AttendanceSummaryLite({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
  });

  final int present;
  final int late;
  final int absent;

  int get total => present + late + absent;
  double get rate => total == 0 ? 0 : (present + late) / total * 100;
}

class DashboardData {
  const DashboardData({
    required this.today,
    required this.week,
    required this.risks,
  });

  final AttendanceSummaryLite today;
  final List<DayStat> week;
  final List<StudentRisk> risks;
}
