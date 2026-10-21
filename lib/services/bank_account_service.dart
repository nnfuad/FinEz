import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bank_account.dart';
import '../models/financial_transaction.dart';

class BankAccountService {
  final SupabaseClient _supabase;

  BankAccountService(this._supabase);

  /// Fetch all bank accounts with authoritative calculated ledger balances
  Future<List<BankAccount>> getBankAccounts() async {
    final response = await _supabase
        .from('bank_balances_view')
        .select()
        .order('account_name', ascending: true);

    return (response as List).map((json) => BankAccount.fromJson(json)).toList();
  }

  /// Add new bank account
  Future<BankAccount> createBankAccount({
    required String accountName,
    required String bankName,
    required String accountNumber,
    required double openingBalance,
  }) async {
    final data = {
      'account_name': accountName.trim(),
      'bank_name': bankName.trim(),
      'account_number': accountNumber.trim(),
      'opening_balance': openingBalance,
      'is_active': true,
    };

    final res = await _supabase.from('bank_accounts').insert(data).select().single();
    return BankAccount.fromJson(res);
  }

  /// Inter-account fund transfer via safe RPC (prevents double counting)
  Future<String> transferFunds({
    required String sourceAccountId,
    required String targetAccountId,
    required double amount,
    required DateTime transferDate,
    required String description,
  }) async {
    final dateStr = transferDate.toIso8601String().substring(0, 10);
    final res = await _supabase.rpc(
      'transfer_bank_funds',
      params: {
        'p_source_account_id': sourceAccountId,
        'p_target_account_id': targetAccountId,
        'p_amount': amount,
        'p_transfer_date': dateStr,
        'p_description': description.trim(),
      },
    );
    return res.toString();
  }

  /// Get ledger history for an account
  Future<List<FinancialTransaction>> getAccountTransactions(String bankAccountId) async {
    final response = await _supabase
        .from('financial_transactions')
        .select('*, bank_accounts(bank_name)')
        .eq('bank_account_id', bankAccountId)
        .order('transaction_date', ascending: false);

    return (response as List).map((json) => FinancialTransaction.fromJson(json)).toList();
  }
}
