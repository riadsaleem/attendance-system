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
  const Major({required this.id, required this.name, required this.collegeId});

  final int id;
  final String name;
  final int collegeId;

  factory Major.fromJson(Map<String, dynamic> json) => Major(
        id: json['id'] as int,
        name: json['name'] as String,
        collegeId: json['college_id'] as int,
      );
}
