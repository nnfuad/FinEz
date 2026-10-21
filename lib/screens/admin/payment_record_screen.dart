import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/locale_provider.dart';
import '../../models/bank_account.dart';
import '../../models/installment.dart';
import '../../models/member.dart';
import '../../services/bank_account_service.dart';
import '../../services/installment_service.dart';
import '../../services/member_service.dart';
import '../../services/payment_service.dart';
import '../../utils/formatters.dart';
import '../../l10n/app_localizations.dart';

class PaymentRecordScreen extends StatefulWidget {
  final MemberService memberService;
  final InstallmentService installmentService;
  final BankAccountService bankAccountService;
  final PaymentService paymentService;
  final LocaleProvider localeProvider;

  const PaymentRecordScreen({
    super.key,
    required this.memberService,
    required this.installmentService,
    required this.bankAccountService,
    required this.paymentService,
    required this.localeProvider,
  });

  @override
  State<PaymentRecordScreen> createState() => _PaymentRecordScreenState();
}

class _PaymentRecordScreenState extends State<PaymentRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  List<Member> _members = [];
  List<Installment> _memberInstallments = [];
  List<BankAccount> _bankAccounts = [];

  Member? _selectedMember;
  Installment? _selectedInstallment;
  BankAccount? _selectedBankAccount;
  DateTime _paymentDate = DateTime.now();

  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final members = await widget.memberService.getMembers(activeOnly: true);
      final banks = await widget.bankAccountService.getBankAccounts();
      if (mounted) {
        setState(() {
          _members = members;
          _bankAccounts = banks;
          if (banks.isNotEmpty) {
            _selectedBankAccount = banks.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onMemberChanged(Member? member) async {
    setState(() {
      _selectedMember = member;
      _selectedInstallment = null;
      _memberInstallments = [];
    });

    if (member == null) return;

    try {
      final insts = await widget.installmentService.getInstallmentsForMember(member.id);
      if (mounted) {
        setState(() {
          _memberInstallments = insts;
          // Pre-select first due or partial installment if available
          final firstUnpaid = insts.where((i) => i.status != InstallmentStatus.paid).toList();
          if (firstUnpaid.isNotEmpty) {
            _selectedInstallment = firstUnpaid.first;
            _amountController.text = _selectedInstallment!.amountDue.toStringAsFixed(0);
          } else if (insts.isNotEmpty) {
            _selectedInstallment = insts.first;
            _amountController.text = member.monthlyInstallment.toStringAsFixed(0);
          } else {
            _amountController.text = member.monthlyInstallment.toStringAsFixed(0);
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching installments for member: $e');
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMember == null || _selectedInstallment == null) {
      setState(() => _error = 'Please select a member and their installment period.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      await widget.paymentService.recordPayment(
        installmentId: _selectedInstallment!.id,
        memberId: _selectedMember!.id,
        bankAccountId: _selectedBankAccount?.id,
        amount: amount,
        paymentDate: _paymentDate,
        reference: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successfully recorded!'), backgroundColor: AppColors.primary),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = widget.localeProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.recordPayment),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusDue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.statusDue),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.statusDue)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Member Dropdown
                    DropdownButtonFormField<Member>(
                      value: _selectedMember,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.fullName,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                      ),
                      items: _members.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text('${m.fullName} (${m.memberCode})'),
                        );
                      }).toList(),
                      onChanged: _onMemberChanged,
                      validator: (val) => val == null ? 'Please select a member' : null,
                    ),
                    const SizedBox(height: 16),

                    // Installment Period Dropdown
                    DropdownButtonFormField<Installment>(
                      value: _selectedInstallment,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.month,
                        prefixIcon: const Icon(Icons.calendar_month, color: AppColors.textSecondary),
                      ),
                      items: _memberInstallments.map((inst) {
                        final monthStr = Formatters.formatMonthYear(inst.periodMonth, locale: locale);
                        return DropdownMenuItem(
                          value: inst,
                          child: Text('$monthStr — ${inst.status.name.toUpperCase()} (Due: ৳${inst.amountDue.toStringAsFixed(0)})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedInstallment = val;
                          if (val != null) {
                            _amountController.text = val.amountDue.toStringAsFixed(0);
                          }
                        });
                      },
                      validator: (val) => val == null ? 'Please select an installment period' : null,
                    ),
                    const SizedBox(height: 16),

                    // Payment Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.amountPaid,
                        prefixText: '৳ ',
                        prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.textSecondary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Payment amount is required';
                        }
                        final amount = double.tryParse(val.trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount greater than zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _paymentDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.primary,
                                  onPrimary: AppColors.onPrimary,
                                  surface: AppColors.card,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _paymentDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.paymentDate,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatDate(_paymentDate, locale: locale),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Destination Bank Account
                    DropdownButtonFormField<BankAccount>(
                      value: _selectedBankAccount,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.destinationBankAccount,
                        prefixIcon: const Icon(Icons.account_balance, color: AppColors.textSecondary),
                      ),
                      items: _bankAccounts.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text('${b.bankName} - ${b.accountName}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedBankAccount = val),
                    ),
                    const SizedBox(height: 16),

                    // Reference
                    TextFormField(
                      controller: _referenceController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.reference,
                        hintText: 'e.g. Deposit slip #1234, bKash TrxID',
                        prefixIcon: const Icon(Icons.notes, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                            )
                          : Text(l10n.recordPayment),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
