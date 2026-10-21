import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/stat_card.dart';
import '../../l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  final AuthService authService;
  final ReportService reportService;
  final LocaleProvider localeProvider;

  const ReportsScreen({
    super.key,
    required this.authService,
    required this.reportService,
    required this.localeProvider,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedMonth;
  int _selectedYear = DateTime.now().year;

  MonthlyFinancialReport? _monthlyReport;
  YearlyFinancialReport? _yearlyReport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      if (_tabController.index == 0) {
        final rep = await widget.reportService.getMonthlyReport(_selectedMonth);
        if (mounted) setState(() => _monthlyReport = rep);
      } else {
        final rep = await widget.reportService.getYearlyReport(_selectedYear);
        if (mounted) setState(() => _yearlyReport = rep);
      }
    } catch (e) {
      debugPrint('Error loading reports: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.financialReports),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          onTap: (_) => _loadReport(),
          tabs: [
            Tab(text: l10n.monthlyReport),
            Tab(text: l10n.yearlyReport),
          ],
        ),
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/admin/reports',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyView(l10n, locale),
                _buildYearlyView(l10n, locale),
              ],
            ),
    );
  }

  Widget _buildMonthlyView(AppLocalizations l10n, String locale) {
    if (_monthlyReport == null) return const SizedBox.shrink();
    final rep = _monthlyReport!;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1));
                  _loadReport();
                },
              ),
              Text(
                Formatters.formatMonthYear(_selectedMonth, locale: locale),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1));
                  _loadReport();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                title: l10n.collectedAmount,
                value: Formatters.formatCurrency(rep.collectedAmount, locale: locale),
                icon: Icons.payments,
                accentColor: AppColors.primary,
              ),
              StatCard(
                title: l10n.outstandingAmount,
                value: Formatters.formatCurrency(rep.outstandingAmount, locale: locale),
                icon: Icons.pending_actions,
                accentColor: AppColors.statusDue,
              ),
              StatCard(
                title: l10n.collectionRate,
                value: '${rep.collectionRate.toStringAsFixed(1)}%',
                icon: Icons.donut_large,
                accentColor: AppColors.transfer,
              ),
              StatCard(
                title: l10n.fullyPaidMembers,
                value: '${rep.fullyPaidCount} / ${rep.totalMembersCount}',
                icon: Icons.how_to_reg,
                accentColor: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pie Chart of Collection Status
          if (rep.totalMembersCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Status Breakdown',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.statusPaid,
                            value: rep.fullyPaidCount.toDouble(),
                            title: '${rep.fullyPaidCount}',
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          PieChartSectionData(
                            color: AppColors.statusPartial,
                            value: rep.partialPaidCount.toDouble(),
                            title: '${rep.partialPaidCount}',
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          PieChartSectionData(
                            color: AppColors.statusDue,
                            value: rep.dueCount.toDouble(),
                            title: '${rep.dueCount}',
                            titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _legend(AppColors.statusPaid, 'Paid (${rep.fullyPaidCount})'),
                      _legend(AppColors.statusPartial, 'Partial (${rep.partialPaidCount})'),
                      _legend(AppColors.statusDue, 'Due (${rep.dueCount})'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearlyView(AppLocalizations l10n, String locale) {
    if (_yearlyReport == null) return const SizedBox.shrink();
    final rep = _yearlyReport!;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                onPressed: () {
                  setState(() => _selectedYear--);
                  _loadReport();
                },
              ),
              Text(
                '$_selectedYear',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                onPressed: () {
                  setState(() => _selectedYear++);
                  _loadReport();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Expected ($_selectedYear)', style: const TextStyle(color: AppColors.textSecondary)),
                    Text(Formatters.formatCurrency(rep.totalExpected, locale: locale), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Collected ($_selectedYear)', style: const TextStyle(color: AppColors.textSecondary)),
                    Text(Formatters.formatCurrency(rep.totalCollected, locale: locale), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Outstanding ($_selectedYear)', style: const TextStyle(color: AppColors.textSecondary)),
                    Text(Formatters.formatCurrency(rep.totalOutstanding, locale: locale), style: const TextStyle(color: AppColors.statusDue, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Monthly breakdown table
          Text('Monthly Breakdown', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          ...rep.monthlyBreakdown.map((m) {
            final monthName = Formatters.formatMonthYear(m.periodMonth, locale: locale);
            return Card(
              child: ListTile(
                title: Text(monthName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                subtitle: Text('Collected: ${Formatters.formatCurrency(m.collectedAmount, locale: locale)} / Due: ${Formatters.formatCurrency(m.expectedInstallments, locale: locale)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                trailing: Text('${m.collectionRate.toStringAsFixed(0)}%', style: TextStyle(color: m.collectionRate >= 80 ? AppColors.primary : AppColors.statusPartial, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
