import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

class PaymentService {
  final SupabaseClient _supabase;

  PaymentService(this._supabase);

  /// Atomic payment recording via database RPC
  Future<String> recordPayment({
    required String installmentId,
    required String memberId,
    String? bankAccountId,
    required double amount,
    required DateTime paymentDate,
    String? reference,
  }) async {
    final paymentDateStr = paymentDate.toIso8601String().substring(0, 10);

    final res = await _supabase.rpc(
      'record_payment_with_ledger',
      params: {
        'p_installment_id': installmentId,
        'p_member_id': memberId,
        'p_bank_account_id': bankAccountId,
        'p_amount': amount,
        'p_payment_date': paymentDateStr,
        'p_reference': reference,
      },
    );

    return res.toString();
  }

  /// Controlled payment correction via database RPC preserving audit history
  Future<void> correctPayment({
    required String paymentId,
    required double newAmount,
    required DateTime newPaymentDate,
    String? newBankAccountId,
    required String correctionReason,
  }) async {
    final paymentDateStr = newPaymentDate.toIso8601String().substring(0, 10);

    await _supabase.rpc(
      'correct_payment_with_audit',
      params: {
        'p_payment_id': paymentId,
        'p_new_amount': newAmount,
        'p_new_date': paymentDateStr,
        'p_new_bank_id': newBankAccountId,
        'p_reason': correctionReason.trim(),
      },
    );
  }

  /// Get payments for an installment
  Future<List<Payment>> getPaymentsForInstallment(String installmentId) async {
    final response = await _supabase
        .from('payments')
        .select('*, members(full_name, member_code), bank_accounts(bank_name)')
        .eq('installment_id', installmentId)
        .order('payment_date', ascending: false);

    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  /// Get personal payment history for a member (Member isolation enforced by RLS)
  Future<List<Payment>> getPaymentsForMember(String memberId) async {
    final response = await _supabase
        .from('payments')
        .select('*, members(full_name, member_code), bank_accounts(bank_name), installments(period_month)')
        .eq('member_id', memberId)
        .order('payment_date', ascending: false);

    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }

  /// Get recent organization-wide payments (Admin only)
  Future<List<Payment>> getRecentPayments({int limit = 50}) async {
    final response = await _supabase
        .from('payments')
        .select('*, members(full_name, member_code), bank_accounts(bank_name), installments(period_month)')
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Payment.fromJson(json)).toList();
  }
}
