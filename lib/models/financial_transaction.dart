class FinancialTransaction {
  final String id;
  final String bankAccountId;
  final String txType;
  final double amount;
  final DateTime transactionDate;
  final String? description;
  final String? relatedPaymentId;
  final String? relatedTransferId;
  final String? createdBy;
  final DateTime? createdAt;
  final String? bankName;

  FinancialTransaction({
    required this.id,
    required this.bankAccountId,
    required this.txType,
    required this.amount,
    required this.transactionDate,
    this.description,
    this.relatedPaymentId,
    this.relatedTransferId,
    this.createdBy,
    this.createdAt,
    this.bankName,
  });

  bool get isInflow => txType == 'installment_receipt' || txType == 'income' || txType == 'transfer_in';

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    final bankData = json['bank_accounts'] as Map<String, dynamic>?;
    return FinancialTransaction(
      id: json['id'] as String,
      bankAccountId: json['bank_account_id'] as String,
      txType: json['tx_type'] as String,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      description: json['description'] as String?,
      relatedPaymentId: json['related_payment_id'] as String?,
      relatedTransferId: json['related_transfer_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      bankName: bankData?['bank_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_account_id': bankAccountId,
      'tx_type': txType,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'description': description,
      'related_payment_id': relatedPaymentId,
      'related_transfer_id': relatedTransferId,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
