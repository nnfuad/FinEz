import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/bank_account.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/bank_account_service.dart';
import '../../services/payment_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../l10n/app_localizations.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final AuthService authService;
  final PaymentService paymentService;
  final BankAccountService bankAccountService;
  final LocaleProvider localeProvider;

  const PaymentHistoryScreen({
    super.key,
    required this.authService,
    required this.paymentService,
    required this.bankAccountService,
    required this.localeProvider,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<Payment> _payments = [];
  List<BankAccount> _bankAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final payments = await widget.paymentService.getRecentPayments(limit: 100);
      final banks = await widget.bankAccountService.getBankAccounts();
      if (mounted) {
        setState(() {
          _payments = payments;
          _bankAccounts = banks;
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

  void _showCorrectionDialog(Payment payment) {
    final l10n = AppLocalizations.of(context)!;
    final amountController = TextEditingController(text: payment.amount.toStringAsFixed(0));
    final reasonController = TextEditingController();
    DateTime newDate = payment.paymentDate;
    String? selectedBankId = payment.bankAccountId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.correctPayment),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Member: ${payment.memberName} (${payment.memberCode})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Corrected Amount', prefixText: '৳ '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedBankId,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Bank Account'),
                  items: _bankAccounts.map((b) => DropdownMenuItem(value: b.id, child: Text(b.bankName))).toList(),
                  onChanged: (val) => setDialogState(() => selectedBankId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.correctionReason,
                    hintText: 'Mandatory reason for audit trail',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correction reason is mandatory')),
                  );
                  return;
                }
                final newAmount = double.tryParse(amountController.text.trim()) ?? payment.amount;
                try {
                  await widget.paymentService.correctPayment(
                    paymentId: payment.id,
                    newAmount: newAmount,
                    newPaymentDate: newDate,
                    newBankAccountId: selectedBankId,
                    correctionReason: reasonController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadHistory();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.paymentHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/admin/payments',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _payments.isEmpty
              ? Center(child: Text(l10n.noPaymentsFound, style: const TextStyle(color: AppColors.textMuted)))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = _payments[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.memberName ?? 'Member',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(p.amount, locale: locale),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${l10n.memberCode}: ${p.memberCode ?? '-'}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                  if (p.periodMonth != null)
                                    Text(
                                      'Period: ${Formatters.formatMonthYear(p.periodMonth!, locale: locale)}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${l10n.paymentDate}: ${Formatters.formatDate(p.paymentDate, locale: locale)}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  Text(
                                    '${l10n.recordedAt}: ${Formatters.formatDateTime(p.createdAt, locale: locale)}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (p.bankName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Deposited to: ${p.bankName}',
                                  style: const TextStyle(color: AppColors.transfer, fontSize: 12),
                                ),
                              ],
                              if (p.reference != null && p.reference!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Reference: ${p.reference}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                              if (p.isCorrected) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusPartial.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Corrected: ${p.correctionReason ?? "Amount adjusted"} (${Formatters.formatDateTime(p.updatedAt, locale: locale)})',
                                    style: const TextStyle(color: AppColors.statusPartial, fontSize: 11),
                                  ),
                                ),
                              ],
                              const Divider(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _showCorrectionDialog(p),
                                  icon: const Icon(Icons.edit_note, size: 18),
                                  label: Text(l10n.correctPayment),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
