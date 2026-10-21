enum InstallmentStatus {
  due,
  partial,
  paid,
  waived;

  static InstallmentStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'paid':
        return InstallmentStatus.paid;
      case 'partial':
        return InstallmentStatus.partial;
      case 'waived':
        return InstallmentStatus.waived;
      case 'due':
      default:
        return InstallmentStatus.due;
    }
  }

  String toDbString() => name;
}

class Installment {
  final String id;
  final String memberId;
  final DateTime periodMonth;
  final double amountDue;
  final InstallmentStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields (when populated by queries)
  final String? memberName;
  final String? memberCode;
  final double? amountPaid;

  Installment({
    required this.id,
    required this.memberId,
    required this.periodMonth,
    required this.amountDue,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.memberName,
    this.memberCode,
    this.amountPaid,
  });

  double get outstanding => (amountDue - (amountPaid ?? (status == InstallmentStatus.paid ? amountDue : 0.0))).clamp(0.0, double.infinity);

  factory Installment.fromJson(Map<String, dynamic> json) {
    final memberData = json['members'] as Map<String, dynamic>?;
    return Installment(
      id: json['id'] as String,
      memberId: json['member_id'] as String,
      periodMonth: DateTime.parse(json['period_month'] as String),
      amountDue: (json['amount_due'] is num)
          ? (json['amount_due'] as num).toDouble()
          : double.tryParse(json['amount_due']?.toString() ?? '0') ?? 0.0,
      status: InstallmentStatus.fromString(json['status'] as String?),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      memberName: memberData?['full_name'] as String?,
      memberCode: memberData?['member_code'] as String?,
      amountPaid: json['amount_paid'] != null ? (json['amount_paid'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'period_month': periodMonth.toIso8601String().substring(0, 10),
      'amount_due': amountDue,
      'status': status.toDbString(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
