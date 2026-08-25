class StaffHoursRow {
  const StaffHoursRow({
    required this.name,
    required this.presentDays,
    required this.totalHours,
    required this.lateHours,
    required this.overtimeHours,
    required this.extraDays,
  });

  final String name;
  final int presentDays;
  final double totalHours;
  final double lateHours;
  final double overtimeHours;
  final double extraDays;
}

class StaffHoursDetail {
  const StaffHoursDetail({
    required this.dateLabel,
    required this.statusLabel,
    required this.inLabel,
    required this.outLabel,
    required this.hoursLabel,
    required this.lateLabel,
    required this.extraLabel,
  });

  final String dateLabel;
  final String statusLabel;
  final String inLabel;
  final String outLabel;
  final String hoursLabel;
  final String lateLabel;
  final String extraLabel;
}
