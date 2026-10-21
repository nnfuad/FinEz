import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/installment.dart';
import '../../services/auth_service.dart';
import '../../services/installment_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';
import '../../l10n/app_localizations.dart';

class InstallmentManagementScreen extends StatefulWidget {
  final AuthService authService;
  final InstallmentService installmentService;
  final LocaleProvider localeProvider;

  const InstallmentManagementScreen({
    super.key,
    required this.authService,
    required this.installmentService,
    required this.localeProvider,
  });

  @override
  State<InstallmentManagementScreen> createState() => _InstallmentManagementScreenState();
}

class _InstallmentManagementScreenState extends State<InstallmentManagementScreen> {
  late DateTime _selectedMonth;
  List<Installment> _installments = [];
  bool _isLoading = true;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadInstallments();
  }

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.installmentService.getInstallmentsForPeriod(_selectedMonth);
      if (mounted) {
        setState(() {
          _installments = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleGenerateInstallments() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.generateInstallments),
        content: Text(l10n.generatePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await widget.installmentService.generateMonthlyInstallments(_selectedMonth);
      final gen = result['generated_count'] ?? 0;
      final skip = result['skipped_count'] ?? 0;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated $gen new installments ($skip existing skipped).'),
            backgroundColor: AppColors.primary,
          ),
        );
        _loadInstallments();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating installments: $e'), backgroundColor: AppColors.statusDue),
        );
      }
    }
  }

  List<Installment> get _filteredInstallments {
    if (_statusFilter == 'all') return _installments;
    return _installments.where((i) => i.status.name == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.installments),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstallments,
          ),
        ],
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/admin/installments',
      ),
      body: Column(
        children: [
          // Period Selector & Generator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.navigationSurface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                            });
                            _loadInstallments();
                          },
                        ),
                        Text(
                          Formatters.formatMonthYear(_selectedMonth, locale: locale),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                          onPressed: () {
                            setState(() {
                              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                            });
                            _loadInstallments();
                          },
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _handleGenerateInstallments,
                      icon: const Icon(Icons.bolt, size: 18),
                      label: Text(l10n.generateInstallments),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _statusChip('all', l10n.filterAll),
                      const SizedBox(width: 8),
                      _statusChip('due', l10n.statusDue, color: AppColors.statusDue),
                      const SizedBox(width: 8),
                      _statusChip('partial', l10n.statusPartial, color: AppColors.statusPartial),
                      const SizedBox(width: 8),
                      _statusChip('paid', l10n.statusPaid, color: AppColors.statusPaid),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredInstallments.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noInstallmentsFound,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _loadInstallments,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredInstallments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final inst = _filteredInstallments[index];
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.elevated,
                                  child: Icon(
                                    inst.status == InstallmentStatus.paid
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    color: inst.status == InstallmentStatus.paid
                                        ? AppColors.primary
                                        : AppColors.statusDue,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        inst.memberName ?? 'Member',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    StatusBadge(status: inst.status),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        inst.memberCode ?? '',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                      Text(
                                        'Due: ${Formatters.formatCurrency(inst.amountDue, locale: locale)}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, String label, {Color? color}) {
    final isSelected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      selectedColor: color ?? AppColors.primary,
      backgroundColor: AppColors.elevated,
      side: const BorderSide(color: AppColors.border),
      onSelected: (_) => setState(() => _statusFilter = status),
    );
  }
}
