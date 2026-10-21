import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finez/core/constants/app_colors.dart';
import 'package:finez/models/installment.dart';
import 'package:finez/models/member.dart';
import 'package:finez/models/profile.dart';
import 'package:finez/models/bank_account.dart';
import 'package:finez/models/financial_transaction.dart';
import 'package:finez/utils/formatters.dart';
import 'package:finez/widgets/stat_card.dart';
import 'package:finez/widgets/status_badge.dart';

void main() {
  group('1. Data Models and Calculations Integrity Tests', () {
    test('Installment outstanding calculation clamp test', () {
      final installment = Installment(
        id: 'inst-1',
        memberId: 'mem-1',
        periodMonth: DateTime(2026, 10, 1),
        amountDue: 2000.0,
        amountPaid: 800.0,
        status: InstallmentStatus.partial,
      );

      // Outstanding must be 2000 - 800 = 1200
      expect(installment.outstanding, 1200.0);

      // Overpayment or paid in full clamp test
      final paidInstallment = Installment(
        id: 'inst-2',
        memberId: 'mem-1',
        periodMonth: DateTime(2026, 10, 1),
        amountDue: 2000.0,
        amountPaid: 2500.0,
        status: InstallmentStatus.paid,
      );
      expect(paidInstallment.outstanding, 0.0);
    });

    test('Member model serialization and phone normalization', () {
      final json = {
        'id': 'mem-100',
        'member_code': 'FM-0100',
        'full_name': 'Test Somiti Member',
        'mobile': '01712345678',
        'address': 'Dhanmondi, Dhaka',
        'monthly_installment': 2500,
        'is_active': true,
      };

      final member = Member.fromJson(json);
      expect(member.id, 'mem-100');
      expect(member.memberCode, 'FM-0100');
      expect(member.monthlyInstallment, 2500.0);
      expect(member.isActive, true);

      // Phone normalization tests
      expect(Formatters.normalizeMobile('+8801712345678'), '01712345678');
      expect(Formatters.normalizeMobile('8801712345678'), '01712345678');
      expect(Formatters.normalizeMobile('01712-345-678'), '01712345678');
      expect(Formatters.normalizeMobile('01712 345 678'), '01712345678');
    });

    test('UserRole parsing and authorization flags', () {
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('MEMBER'), UserRole.member);
      expect(UserRole.fromString('random_role'), UserRole.unknown);

      final adminProfile = UserProfile(id: 'u1', role: UserRole.admin);
      expect(adminProfile.isAdmin, true);
      expect(adminProfile.isMember, false);

      final memberProfile = UserProfile(id: 'u2', role: UserRole.member);
      expect(memberProfile.isAdmin, false);
      expect(memberProfile.isMember, true);
    });

    test('Financial transaction inflow/outflow discrimination', () {
      final account = BankAccount(
        id: 'ba-1',
        accountName: 'General Fund',
        bankName: 'Sonali Bank',
        accountNumber: '1234567890',
        openingBalance: 100000.0,
        currentBalance: 145000.0,
      );
      expect(account.currentBalance, 145000.0);
      expect(account.bankName, 'Sonali Bank');

      final receipt = FinancialTransaction(
        id: 'tx-1',
        bankAccountId: 'ba-1',
        txType: 'installment_receipt',
        amount: 2000.0,
        transactionDate: DateTime(2026, 10, 10),
      );
      expect(receipt.isInflow, true);

      final expense = FinancialTransaction(
        id: 'tx-2',
        bankAccountId: 'ba-1',
        txType: 'expense',
        amount: 500.0,
        transactionDate: DateTime(2026, 10, 11),
      );
      expect(expense.isInflow, false);

      final transferOut = FinancialTransaction(
        id: 'tx-3',
        bankAccountId: 'ba-1',
        txType: 'transfer_out',
        amount: 5000.0,
        transactionDate: DateTime(2026, 10, 12),
      );
      expect(transferOut.isInflow, false);

      final transferIn = FinancialTransaction(
        id: 'tx-4',
        bankAccountId: 'ba-2',
        txType: 'transfer_in',
        amount: 5000.0,
        transactionDate: DateTime(2026, 10, 12),
      );
      expect(transferIn.isInflow, true);
    });

    test('Formatters currency display formatting', () {
      final formatted = Formatters.formatCurrency(2500.0, locale: 'en');
      expect(formatted.contains('2,500'), true);
      expect(formatted.contains('৳'), true);
    });
  });

  group('2. Widget Presentation Tests', () {
    testWidgets('StatusBadge renders correct labels and theme styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(status: InstallmentStatus.paid, customLabel: 'Paid'),
                StatusBadge(status: InstallmentStatus.due, customLabel: 'Due'),
                StatusBadge(status: InstallmentStatus.partial, customLabel: 'Partial'),
                StatusBadge(status: InstallmentStatus.waived, customLabel: 'Waived'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
      expect(find.text('Partial'), findsOneWidget);
      expect(find.text('Waived'), findsOneWidget);
    });

    testWidgets('StatCard renders title, value, and subtitle properly', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Collected Amount',
              value: '৳50,000',
              subtitle: 'Expected: ৳60,000',
              icon: Icons.payments,
              accentColor: AppColors.primary,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Collected Amount'), findsOneWidget);
      expect(find.text('৳50,000'), findsOneWidget);
      expect(find.text('Expected: ৳60,000'), findsOneWidget);
      expect(find.byIcon(Icons.payments), findsOneWidget);

      await tester.tap(find.byType(StatCard));
      expect(tapped, true);
    });
  });
}
