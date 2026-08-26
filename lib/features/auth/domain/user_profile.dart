import '../../../core/constants/app_constants.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.orgName,
    this.orgType,
    this.systemType,
    this.trialEndsAt,
    this.licensedUntil,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final UserRole role;
  final String? email;
  final String? orgName;
  final String? orgType;
  final String? systemType;
  final DateTime? trialEndsAt;
  final DateTime? licensedUntil;
  final String? avatarUrl;

  bool get isAdmin => role == UserRole.admin;

  bool get isLicensed {
    if (isAdmin) return true;
    final DateTime? licensed = licensedUntil;
    if (licensed != null && licensed.isAfter(DateTime.now())) return true;
    final DateTime? trial = trialEndsAt;
    if (trial != null && trial.isAfter(DateTime.now())) return true;
    return false;
  }

  bool get isTrialActive {
    if (isAdmin) return false;
    if (licensedUntil != null && licensedUntil!.isAfter(DateTime.now())) {
      return false;
    }
    return trialEndsAt != null && trialEndsAt!.isAfter(DateTime.now());
  }

  DateTime? get activeUntil {
    if (isAdmin) return null;
    if (licensedUntil != null &&
        (trialEndsAt == null || licensedUntil!.isAfter(trialEndsAt!))) {
      return licensedUntil;
    }
    return trialEndsAt;
  }

  bool get needsOnboarding =>
      orgName == null || orgName!.isEmpty || orgType == null || orgType!.isEmpty;

  bool get isStaffOnly => orgType == 'staff_only' || orgType == 'company';
  bool get isUniversity => orgType == 'university';
  bool get isInstitute => orgType == 'institute';
  bool get usesCourses => systemType == 'courses';

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        fullName: (json['full_name'] ?? '') as String,
        role: UserRole.fromName(json['role'] as String?),
        email: json['email'] as String?,
        orgName: json['org_name'] as String?,
        orgType: json['org_type'] as String?,
        systemType: json['system_type'] as String?,
        trialEndsAt: json['trial_ends_at'] == null
            ? null
            : DateTime.parse(json['trial_ends_at'] as String),
        licensedUntil: json['licensed_until'] == null
            ? null
            : DateTime.parse(json['licensed_until'] as String),
        avatarUrl: json['avatar_url'] as String?,
      );
}
