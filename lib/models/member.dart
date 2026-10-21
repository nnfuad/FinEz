class Member {
  final String id;
  final String memberCode;
  final String fullName;
  final String mobile;
  final String? address;
  final double monthlyInstallment;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Member({
    required this.id,
    required this.memberCode,
    required this.fullName,
    required this.mobile,
    this.address,
    required this.monthlyInstallment,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      memberCode: json['member_code'] as String,
      fullName: json['full_name'] as String,
      mobile: (json['mobile'] ?? '') as String,
      address: json['address'] as String?,
      monthlyInstallment: (json['monthly_installment'] is num)
          ? (json['monthly_installment'] as num).toDouble()
          : double.tryParse(json['monthly_installment']?.toString() ?? '0') ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_code': memberCode,
      'full_name': fullName,
      'mobile': mobile,
      'address': address,
      'monthly_installment': monthlyInstallment,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Member copyWith({
    String? id,
    String? memberCode,
    String? fullName,
    String? mobile,
    String? address,
    double? monthlyInstallment,
    bool? isActive,
  }) {
    return Member(
      id: id ?? this.id,
      memberCode: memberCode ?? this.memberCode,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      monthlyInstallment: monthlyInstallment ?? this.monthlyInstallment,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Lightweight model for public directory view (names only)
class PublicMember {
  final String id;
  final String memberCode;
  final String fullName;
  final bool isActive;

  PublicMember({
    required this.id,
    required this.memberCode,
    required this.fullName,
    this.isActive = true,
  });

  factory PublicMember.fromJson(Map<String, dynamic> json) {
    return PublicMember(
      id: json['id'] as String,
      memberCode: json['member_code'] as String,
      fullName: json['full_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
