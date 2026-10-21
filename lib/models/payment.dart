class Payment {
  final String id;
  final String installmentId;
  final String memberId;
  final String? bankAccountId;
  final double amount;
  final DateTime paymentDate;
  final String? recordedBy;
  final String? reference;
  final String? correctionReason;
  final bool isCorrected;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields for rich display
  final String? memberName;
  final String? memberCode;
  final String? bankName;
  final DateTime? periodMonth;

  Payment({
    required this.id,
    required this.installmentId,
    required this.memberId,
    this.bankAccountId,
    required this.amount,
    required this.paymentDate,
    this.recordedBy,
    this.reference,
    this.correctionReason,
    this.isCorrected = false,
    this.createdAt,
    this.updatedAt,
    this.memberName,
    this.memberCode,
    this.bankName,
    this.periodMonth,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final memberData = json['members'] as Map<String, dynamic>?;
    final bankData = json['bank_accounts'] as Map<String, dynamic>?;
    final instData = json['installments'] as Map<String, dynamic>?;

    return Payment(
      id: json['id'] as String,
      installmentId: json['installment_id'] as String,
      memberId: json['member_id'] as String,
      bankAccountId: json['bank_account_id'] as String?,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentDate: DateTime.parse(json['payment_date'] as String),
      recordedBy: json['recorded_by'] as String?,
      reference: json['reference'] as String?,
      correctionReason: json['correction_reason'] as String?,
      isCorrected: json['is_corrected'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      memberName: memberData?['full_name'] as String?,
      memberCode: memberData?['member_code'] as String?,
      bankName: bankData?['bank_name'] as String?,
      periodMonth: instData?['period_month'] != null
          ? DateTime.tryParse(instData!['period_month'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'installment_id': installmentId,
      'member_id': memberId,
      'bank_account_id': bankAccountId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().substring(0, 10),
      'recorded_by': recordedBy,
      'reference': reference,
      'correction_reason': correctionReason,
      'is_corrected': isCorrected,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
