class College {
  const College({required this.id, required this.name});

  final int id;
  final String name;

  factory College.fromJson(Map<String, dynamic> json) => College(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}

class Major {
  const Major({
    required this.id,
    required this.name,
    required this.collegeId,
    this.yearsCount = 4,
  });

  final int id;
  final String name;
  final int collegeId;
  final int yearsCount;

  factory Major.fromJson(Map<String, dynamic> json) => Major(
        id: json['id'] as int,
        name: json['name'] as String,
        collegeId: json['college_id'] as int,
        yearsCount: (json['years_count'] ?? 4) as int,
      );
}
