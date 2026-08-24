import '../../../core/constants/app_constants.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
  });

  final String id;
  final String fullName;
  final UserRole role;
  final String? email;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        fullName: (json['full_name'] ?? '') as String,
        role: UserRole.fromName(json['role'] as String?),
        email: json['email'] as String?,
      );
}
