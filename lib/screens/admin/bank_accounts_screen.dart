import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/bank_account.dart';
import '../../services/auth_service.dart';
import '../../services/bank_account_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_drawer.dart';
import '../../l10n/app_localizations.dart';

class BankAccountsScreen extends StatefulWidget {
  final AuthService authService;
  final BankAccountService bankAccountService;
  final LocaleProvider localeProvider;

  const BankAccountsScreen({
    super.key,
    required this.authService,
    required this.bankAccountService,
    required this.localeProvider,
  });

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  List<BankAccount> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.bankAccountService.getBankAccounts();
      if (mounted) {
        setState(() {
          _accounts = list;
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

  void _showAddAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final bankNameController = TextEditingController();
    final numberController = TextEditingController();
    final openingController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bank Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankNameController,
                decoration: InputDecoration(labelText: l10n.bankName, hintText: 'e.g. Sonali Bank PLC'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.accountName, hintText: 'e.g. General Fund'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                decoration: InputDecoration(labelText: l10n.accountNumber, hintText: 'e.g. 1002938471'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: openingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.openingBalance, prefixText: '৳ '),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (bankNameController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
              final opening = double.tryParse(openingController.text.trim()) ?? 0.0;
              try {
                await widget.bankAccountService.createBankAccount(
                  accountName: nameController.text,
                  bankName: bankNameController.text,
                  accountNumber: numberController.text,
                  openingBalance: opening,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _loadAccounts();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() {
    final l10n = AppLocalizations.of(context)!;
    if (_accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 bank accounts to perform a transfer.')),
      );
      return;
    }

    String sourceId = _accounts.first.id;
    String targetId = _accounts.last.id;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    DateTime transferDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.transferFunds),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: sourceId,
                  dropdownColor: AppColors.card,
                  decoration: InputDecoration(labelText: l10n.sourceAccount),
                  items: _accounts.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.bankName} (${b.accountName})'))).toList(),
                  onChanged: (val) => setDialogState(() => sourceId = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: targetId,
                  dropdownColor: AppColors.card,
                  decoration: InputDecoration(labelText: l10n.targetAccount),
                  items: _accounts.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.bankName} (${b.accountName})'))).toList(),
                  onChanged: (val) => setDialogState(() => targetId = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Amount', prefixText: '৳ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n.description, hintText: 'Reason for transfer'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (sourceId == targetId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Source and target accounts must be different')),
                  );
                  return;
                }
                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amt <= 0) return;
                try {
                  await widget.bankAccountService.transferFunds(
                    sourceAccountId: sourceId,
                    targetAccountId: targetId,
                    amount: amt,
                    transferDate: transferDate,
                    description: descController.text,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    _loadAccounts();
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
    final totalBalance = _accounts.fold(0.0, (sum, a) => sum + a.currentBalance);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.bankAccounts),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.transferFunds,
            onPressed: _showTransferDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Bank Account',
            onPressed: _showAddAccountDialog,
          ),
        ],
      ),
      drawer: AppDrawer(
        authService: widget.authService,
        localeProvider: widget.localeProvider,
        currentRoute: '/admin/bank_accounts',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadAccounts,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Total Balance Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.elevated,
                          AppColors.card,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalBankBalance,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.formatCurrency(totalBalance, locale: locale),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Accounts & Reconciliation',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ..._accounts.map((account) {
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.bankName,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${account.accountName} • A/C: ${account.accountNumber}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Formatters.formatCurrency(account.currentBalance, locale: locale),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Text('Current Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            // Reconciliation row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Opening: ${Formatters.formatCurrency(account.openingBalance, locale: locale, showDecimals: false)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                Text(
                                  'Inflow: +${Formatters.formatCurrency(account.totalInflow, locale: locale, showDecimals: false)}',
                                  style: const TextStyle(color: AppColors.inflow, fontSize: 12),
                                ),
                                Text(
                                  'Outflow: -${Formatters.formatCurrency(account.totalOutflow, locale: locale, showDecimals: false)}',
                                  style: const TextStyle(color: AppColors.outflow, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
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
