import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/member.dart';
import '../../services/member_service.dart';
import '../../l10n/app_localizations.dart';

class MemberFormScreen extends StatefulWidget {
  final MemberService memberService;
  final Member? existingMember;

  const MemberFormScreen({
    super.key,
    required this.memberService,
    this.existingMember,
  });

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;
  late final TextEditingController _installmentController;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.existingMember;
    _codeController = TextEditingController(text: m?.memberCode ?? '');
    _nameController = TextEditingController(text: m?.fullName ?? '');
    _mobileController = TextEditingController(text: m?.mobile ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _installmentController = TextEditingController(
      text: m != null ? m.monthlyInstallment.toStringAsFixed(0) : '2000',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _installmentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final monthly = double.parse(_installmentController.text.trim());

      if (widget.existingMember == null) {
        await widget.memberService.createMember(
          memberCode: _codeController.text,
          fullName: _nameController.text,
          mobile: _mobileController.text,
          address: _addressController.text,
          monthlyInstallment: monthly,
        );
      } else {
        final updated = widget.existingMember!.copyWith(
          memberCode: _codeController.text,
          fullName: _nameController.text,
          mobile: _mobileController.text,
          address: _addressController.text,
          monthlyInstallment: monthly,
        );
        await widget.memberService.updateMember(updated);
      }

      if (mounted) {
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
    final isEdit = widget.existingMember != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? l10n.editMember : l10n.addMember),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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

                // Member Code
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.memberCode,
                    hintText: 'e.g. FM-0001',
                    prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Member code is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    hintText: 'e.g. Md. Abdul Karim',
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mobile Number
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.mobileNumber,
                    hintText: 'e.g. 01711000000',
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Mobile number is required';
                    }
                    if (val.trim().length < 11) {
                      return 'Enter a valid 11-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.address,
                    hintText: 'e.g. Uttara, Dhaka',
                    prefixIcon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly Installment
                TextFormField(
                  controller: _installmentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.standardMonthlyInstallment,
                    prefixText: '৳ ',
                    prefixStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    prefixIcon: const Icon(Icons.attach_money, color: AppColors.textSecondary),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Monthly installment is required';
                    }
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal < 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
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
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
