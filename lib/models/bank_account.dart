class BankAccount {
  final String id;
  final String accountName;
  final String bankName;
  final String accountNumber;
  final double openingBalance;
  final double currentBalance;
  final double totalInflow;
  final double totalOutflow;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BankAccount({
    required this.id,
    required this.accountName,
    required this.bankName,
    required this.accountNumber,
    required this.openingBalance,
    this.currentBalance = 0.0,
    this.totalInflow = 0.0,
    this.totalOutflow = 0.0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      accountName: json['account_name'] as String,
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      openingBalance: (json['opening_balance'] is num)
          ? (json['opening_balance'] as num).toDouble()
          : double.tryParse(json['opening_balance']?.toString() ?? '0') ?? 0.0,
      currentBalance: (json['current_balance'] is num)
          ? (json['current_balance'] as num).toDouble()
          : (json['opening_balance'] is num)
              ? (json['opening_balance'] as num).toDouble()
              : 0.0,
      totalInflow: (json['total_inflow'] is num) ? (json['total_inflow'] as num).toDouble() : 0.0,
      totalOutflow: (json['total_outflow'] is num) ? (json['total_outflow'] as num).toDouble() : 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_name': accountName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'opening_balance': openingBalance,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
