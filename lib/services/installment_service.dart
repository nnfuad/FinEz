import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installment.dart';

class InstallmentService {
  final SupabaseClient _supabase;

  InstallmentService(this._supabase);

  /// Get installments for a given month/year (first day of month)
  Future<List<Installment>> getInstallmentsForPeriod(DateTime monthYear) async {
    final firstDay = DateTime(monthYear.year, monthYear.month, 1);
    final dateString = firstDay.toIso8601String().substring(0, 10);

    final response = await _supabase
        .from('installments')
        .select('*, members(full_name, member_code)')
        .eq('period_month', dateString)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Installment.fromJson(json)).toList();
  }

  /// Get all installments for a specific member (sorted newest first)
  Future<List<Installment>> getInstallmentsForMember(String memberId) async {
    final response = await _supabase
        .from('installments')
        .select('*, members(full_name, member_code)')
        .eq('member_id', memberId)
        .order('period_month', ascending: false);

    return (response as List).map((json) => Installment.fromJson(json)).toList();
  }

  /// Trigger safe RPC to generate installments for all active members
  Future<Map<String, dynamic>> generateMonthlyInstallments(DateTime monthYear) async {
    final firstDay = DateTime(monthYear.year, monthYear.month, 1);
    final dateString = firstDay.toIso8601String().substring(0, 10);

    final response = await _supabase.rpc(
      'generate_monthly_installments',
      params: {'p_target_month': dateString},
    );

    return Map<String, dynamic>.from(response as Map);
  }
}
