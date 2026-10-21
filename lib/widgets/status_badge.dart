import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/installment.dart';

class StatusBadge extends StatelessWidget {
  final InstallmentStatus status;
  final String? customLabel;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case InstallmentStatus.paid:
        bg = AppColors.statusPaid.withValues(alpha: 0.15);
        fg = AppColors.statusPaid;
        label = customLabel ?? 'Paid';
        break;
      case InstallmentStatus.due:
        bg = AppColors.statusDue.withValues(alpha: 0.15);
        fg = AppColors.statusDue;
        label = customLabel ?? 'Due';
        break;
      case InstallmentStatus.partial:
        bg = AppColors.statusPartial.withValues(alpha: 0.15);
        fg = AppColors.statusPartial;
        label = customLabel ?? 'Partial';
        break;
      case InstallmentStatus.waived:
        bg = AppColors.statusWaived.withValues(alpha: 0.15);
        fg = AppColors.statusWaived;
        label = customLabel ?? 'Waived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
