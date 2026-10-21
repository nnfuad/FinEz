import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/bank_account_service.dart';
import '../../services/installment_service.dart';
import '../../services/member_service.dart';
import '../../services/payment_service.dart';
import '../../services/report_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';
import '../../l10n/app_localizations.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AuthService authService;
  final MemberService memberService;
  final InstallmentService installmentService;
  final PaymentService paymentService;
  final BankAccountService bankAccountService;
  final ReportService reportService;
  final LocaleProvider localeProvider;

  const AdminDashboardScreen({
    super.key,
    required this.authService,
    required this.memberService,
    required this.installmentService,
    required this.paymentService,
    required this.bankAccountService,
    required this.reportService,
    required this.localeProvider,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  int _activeMembersCount = 0;
  double _expectedInstallments = 0.0;
  double _collectedAmount = 0.0;
  double _outstandingAmount = 0.0;
  int _fullyPaidCount = 0;
  int _dueCount = 0;
  double _totalBankBalance = 0.0;
  List<Payment> _recentPayments = [];
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Members count
      final members = await widget.memberService.getMembers(activeOnly: true);
      _activeMembersCount = members.length;

      // 2. Monthly report
      final report = await widget.reportService.getMonthlyReport(_currentMonth);
      _expectedInstallments = report.expectedInstallments;
      _collectedAmount = report.collectedAmount;
      _outstandingAmount = report.outstandingAmount;
      _fullyPaidCount = report.fullyPaidCount;
      _dueCount = report.dueCount + report.partialPaidCount;

      // 3. Bank balances
      final bankAccounts = await widget.bankAccountService.getBankAccounts();
      _totalBankBalance = bankAccounts.fold(0.0, (sum, acc) => sum + acc.currentBalance);

      // 4. Recent payments
      _recentPayments = await widget.paymentService.getRecentPayments(limit: 6);
    } catch (e) {
      debugPrint('Error loading admin dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/admin/dashboard',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  // Month Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.formatMonthYear(_currentMonth, locale: locale),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.appSubtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/admin/record-payment').then((_) => _loadDashboardData());
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.recordPayment),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Metrics Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: isWide ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isWide ? 1.4 : 1.15,
                        children: [
                          StatCard(
                            title: l10n.collectedAmount,
                            value: Formatters.formatCurrency(_collectedAmount, locale: locale),
                            icon: Icons.payments,
                            accentColor: AppColors.primary,
                            subtitle: '${l10n.expectedInstallments}: ${Formatters.formatCurrency(_expectedInstallments, locale: locale, showDecimals: false)}',
                          ),
                          StatCard(
                            title: l10n.outstandingAmount,
                            value: Formatters.formatCurrency(_outstandingAmount, locale: locale),
                            icon: Icons.pending_actions,
                            accentColor: AppColors.statusDue,
                            subtitle: '$_dueCount ${l10n.dueMembers}',
                          ),
                          StatCard(
                            title: l10n.totalBankBalance,
                            value: Formatters.formatCurrency(_totalBankBalance, locale: locale),
                            icon: Icons.account_balance,
                            accentColor: AppColors.transfer,
                            onTap: () => Navigator.of(context).pushNamed('/admin/bank_accounts'),
                          ),
                          StatCard(
                            title: l10n.activeMembers,
                            value: '$_activeMembersCount',
                            icon: Icons.people,
                            accentColor: AppColors.textPrimary,
                            subtitle: '$_fullyPaidCount ${l10n.fullyPaidMembers}',
                            onTap: () => Navigator.of(context).pushNamed('/admin/members'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Quick Action Shortcuts
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _actionPill(
                        context,
                        icon: Icons.add_circle_outline,
                        label: l10n.addMember,
                        onTap: () => Navigator.of(context).pushNamed('/admin/member-form').then((_) => _loadDashboardData()),
                      ),
                      _actionPill(
                        context,
                        icon: Icons.event_repeat,
                        label: l10n.generateInstallments,
                        onTap: () => Navigator.of(context).pushNamed('/admin/installments').then((_) => _loadDashboardData()),
                      ),
                      _actionPill(
                        context,
                        icon: Icons.account_balance,
                        label: l10n.bankAccounts,
                        onTap: () => Navigator.of(context).pushNamed('/admin/bank_accounts').then((_) => _loadDashboardData()),
                      ),
                      _actionPill(
                        context,
                        icon: Icons.bar_chart,
                        label: l10n.financialReports,
                        onTap: () => Navigator.of(context).pushNamed('/admin/reports'),
                      ),
                      _actionPill(
                        context,
                        icon: Icons.upload_file,
                        label: l10n.importExcel,
                        onTap: () => Navigator.of(context).pushNamed('/admin/import').then((_) => _loadDashboardData()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Recent Payments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentPayments,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/admin/payments'),
                        child: Text(l10n.paymentHistory),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_recentPayments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        l10n.noPaymentsFound,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  else
                    ..._recentPayments.map((p) => _paymentTile(context, p, locale)),
                ],
              ),
            ),
    );
  }

  Widget _actionPill(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.card,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }

  Widget _paymentTile(BuildContext context, Payment p, String locale) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: AppColors.primary, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                p.memberName ?? 'Member',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              Formatters.formatCurrency(p.amount, locale: locale),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${p.memberCode ?? ''} • ${Formatters.formatDate(p.paymentDate, locale: locale)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (p.isCorrected)
                const Text(
                  'Corrected',
                  style: TextStyle(color: AppColors.statusPartial, fontSize: 11, fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
