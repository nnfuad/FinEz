enum UserRole {
  admin,
  member,
  unknown;

  static UserRole fromString(String? val) {
    if (val == null) return UserRole.unknown;
    switch (val.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'MEMBER':
        return UserRole.member;
      default:
        return UserRole.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.member:
        return 'MEMBER';
      case UserRole.unknown:
        return 'MEMBER';
    }
  }
}

class UserProfile {
  final String id;
  final String? memberId;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    this.memberId,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isMember => role == UserRole.member;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      memberId: json['member_id'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'role': role.toDbString(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
