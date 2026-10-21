import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/installment.dart';
import '../../models/member.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/installment_service.dart';
import '../../services/member_service.dart';
import '../../services/payment_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../../l10n/app_localizations.dart';

class MemberDashboardScreen extends StatefulWidget {
  final AuthService authService;
  final MemberService memberService;
  final InstallmentService installmentService;
  final PaymentService paymentService;
  final LocaleProvider localeProvider;

  const MemberDashboardScreen({
    super.key,
    required this.authService,
    required this.memberService,
    required this.installmentService,
    required this.paymentService,
    required this.localeProvider,
  });

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  Member? _member;
  List<Installment> _installments = [];
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);
    try {
      final profile = widget.authService.currentProfile;
      final memberId = profile?.memberId;

      if (memberId == null) {
        setState(() {
          _error = 'Your user account is not linked to an official Somiti member record yet. Please contact an administrator.';
          _isLoading = false;
        });
        return;
      }

      final m = await widget.memberService.getMemberById(memberId);
      final insts = await widget.installmentService.getInstallmentsForMember(memberId);
      final pays = await widget.paymentService.getPaymentsForMember(memberId);

      if (mounted) {
        setState(() {
          _member = m;
          _installments = insts;
          _payments = pays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.localeProvider.locale.languageCode;

    // Calculate Personal Stats
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final currentInst = _installments.where((i) => i.periodMonth.year == currentMonth.year && i.periodMonth.month == currentMonth.month).firstOrNull;
    final totalPaid = _payments.fold(0.0, (sum, p) => sum + p.amount);
    final totalOutstanding = _installments.fold(0.0, (sum, i) => sum + i.outstanding);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.personalFinancialSummary),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMemberData),
        ],
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/member/dashboard',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.statusPartial, size: 54),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadMemberData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Member Identity Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.elevated, AppColors.card],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                _member?.fullName.isNotEmpty == true ? _member!.fullName[0].toUpperCase() : 'M',
                                style: const TextStyle(color: AppColors.onPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _member?.fullName ?? 'Member',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${l10n.memberCode}: ${_member?.memberCode ?? "-"}',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Standard Installment: ${Formatters.formatCurrency(_member?.monthlyInstallment ?? 0, locale: locale)} / month',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Personal Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          StatCard(
                            title: 'Total Paid to Date',
                            value: Formatters.formatCurrency(totalPaid, locale: locale),
                            icon: Icons.check_circle_outline,
                            accentColor: AppColors.primary,
                          ),
                          StatCard(
                            title: l10n.outstandingAmount,
                            value: Formatters.formatCurrency(totalOutstanding, locale: locale),
                            icon: Icons.pending_actions,
                            accentColor: totalOutstanding > 0 ? AppColors.statusDue : AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Current Month Status
                      if (currentInst != null) ...[
                        Text(
                          'Current Month: ${Formatters.formatMonthYear(currentInst.periodMonth, locale: locale)}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Amount Due: ${Formatters.formatCurrency(currentInst.amountDue, locale: locale)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('Remaining: ${Formatters.formatCurrency(currentInst.outstanding, locale: locale)}', style: TextStyle(color: currentInst.outstanding > 0 ? AppColors.statusDue : AppColors.textMuted)),
                                  ],
                                ),
                                StatusBadge(status: currentInst.status),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Personal Installment History
                      Text(
                        'Installment Schedule',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      if (_installments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No installment records available.', style: TextStyle(color: AppColors.textMuted)),
                        )
                      else
                        ..._installments.map((inst) {
                          return Card(
                            child: ListTile(
                              title: Text(
                                Formatters.formatMonthYear(inst.periodMonth, locale: locale),
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Due: ${Formatters.formatCurrency(inst.amountDue, locale: locale)}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              trailing: StatusBadge(status: inst.status),
                            ),
                          );
                        }),
                      const SizedBox(height: 24),

                      // Personal Payment History
                      Text(
                        l10n.paymentHistory,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      if (_payments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(l10n.noPaymentsFound, style: const TextStyle(color: AppColors.textMuted)),
                        )
                      else
                        ..._payments.map((p) {
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(p.amount, locale: locale),
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    Formatters.formatDate(p.paymentDate, locale: locale),
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Recorded at: ${Formatters.formatDateTime(p.createdAt, locale: locale)}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
