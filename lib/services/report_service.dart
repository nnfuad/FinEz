import 'package:supabase_flutter/supabase_flutter.dart';

class MonthlyFinancialReport {
  final DateTime periodMonth;
  final double expectedInstallments;
  final double collectedAmount;
  final double outstandingAmount;
  final int totalMembersCount;
  final int fullyPaidCount;
  final int partialPaidCount;
  final int dueCount;
  final double collectionRate;
  final double totalIncome;
  final double totalExpenses;

  MonthlyFinancialReport({
    required this.periodMonth,
    required this.expectedInstallments,
    required this.collectedAmount,
    required this.outstandingAmount,
    required this.totalMembersCount,
    required this.fullyPaidCount,
    required this.partialPaidCount,
    required this.dueCount,
    required this.collectionRate,
    required this.totalIncome,
    required this.totalExpenses,
  });
}

class YearlyFinancialReport {
  final int year;
  final double totalExpected;
  final double totalCollected;
  final double totalOutstanding;
  final double totalExpenses;
  final List<MonthlyFinancialReport> monthlyBreakdown;

  YearlyFinancialReport({
    required this.year,
    required this.totalExpected,
    required this.totalCollected,
    required this.totalOutstanding,
    required this.totalExpenses,
    required this.monthlyBreakdown,
  });
}

class ReportService {
  final SupabaseClient _supabase;

  ReportService(this._supabase);

  /// Fetch monthly financial report from database records
  Future<MonthlyFinancialReport> getMonthlyReport(DateTime targetMonth) async {
    final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
    final dateStr = firstDay.toIso8601String().substring(0, 10);
    final nextMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);
    final nextMonthStr = nextMonth.toIso8601String().substring(0, 10);

    // 1. Fetch Installments for this period
    final instRes = await _supabase
        .from('installments')
        .select('amount_due, status, id')
        .eq('period_month', dateStr);

    double expected = 0.0;
    int fullyPaid = 0;
    int partialPaid = 0;
    int due = 0;

    final installmentList = instRes as List;
    for (var item in installmentList) {
      final amount = (item['amount_due'] as num).toDouble();
      expected += amount;
      final status = item['status'] as String?;
      if (status == 'paid') {
        fullyPaid++;
      } else if (status == 'partial') {
        partialPaid++;
      } else if (status == 'due') {
        due++;
      }
    }

    // 2. Fetch Payments made for this installment period
    final paymentsRes = await _supabase
        .from('payments')
        .select('amount')
        .eq('is_corrected', false)
        .gte('payment_date', dateStr)
        .lt('payment_date', nextMonthStr);

    double collected = 0.0;
    for (var item in paymentsRes as List) {
      collected += (item['amount'] as num).toDouble();
    }

    // 3. Outstanding calculation
    final outstanding = (expected - collected).clamp(0.0, double.infinity);
    final collectionRate = expected > 0 ? ((collected / expected) * 100).clamp(0.0, 100.0) : 0.0;

    // 4. Other transactions (Income & Expense)
    final txRes = await _supabase
        .from('financial_transactions')
        .select('amount, tx_type')
        .gte('transaction_date', dateStr)
        .lt('transaction_date', nextMonthStr);

    double income = 0.0;
    double expenses = 0.0;
    for (var item in txRes as List) {
      final type = item['tx_type'] as String;
      final amount = (item['amount'] as num).toDouble();
      if (type == 'income') {
        income += amount;
      } else if (type == 'expense') {
        expenses += amount;
      }
    }

    return MonthlyFinancialReport(
      periodMonth: firstDay,
      expectedInstallments: expected,
      collectedAmount: collected,
      outstandingAmount: outstanding,
      totalMembersCount: installmentList.length,
      fullyPaidCount: fullyPaid,
      partialPaidCount: partialPaid,
      dueCount: due,
      collectionRate: collectionRate,
      totalIncome: income,
      totalExpenses: expenses,
    );
  }

  /// Fetch yearly aggregation
  Future<YearlyFinancialReport> getYearlyReport(int year) async {
    final List<MonthlyFinancialReport> breakdown = [];
    double totalExp = 0.0;
    double totalCol = 0.0;
    double totalOut = 0.0;
    double totalExpns = 0.0;

    for (int month = 1; month <= 12; month++) {
      final monthly = await getMonthlyReport(DateTime(year, month, 1));
      breakdown.add(monthly);
      totalExp += monthly.expectedInstallments;
      totalCol += monthly.collectedAmount;
      totalOut += monthly.outstandingAmount;
      totalExpns += monthly.totalExpenses;
    }

    return YearlyFinancialReport(
      year: year,
      totalExpected: totalExp,
      totalCollected: totalCol,
      totalOutstanding: totalOut,
      totalExpenses: totalExpns,
      monthlyBreakdown: breakdown,
    );
  }
}
