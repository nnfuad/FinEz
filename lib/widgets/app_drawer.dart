import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/locale_provider.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class AppDrawer extends StatelessWidget {
  final AuthService authService;
  final LocaleProvider localeProvider;
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.authService,
    required this.localeProvider,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = authService.isAdmin;
    final email = authService.currentUser?.email ?? 'user@somiti.org';

    return Drawer(
      backgroundColor: AppColors.navigationSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      isAdmin ? 'A' : 'M',
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? l10n.roleAdmin : l10n.roleMember,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _drawerItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: l10n.dashboard,
                    route: isAdmin ? '/admin/dashboard' : '/member/dashboard',
                  ),
                  if (isAdmin) ...[
                    _drawerItem(
                      context,
                      icon: Icons.people_outline,
                      title: l10n.members,
                      route: '/admin/members',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.calendar_month_outlined,
                      title: l10n.installments,
                      route: '/admin/installments',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.payments_outlined,
                      title: l10n.payments,
                      route: '/admin/payments',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.account_balance_outlined,
                      title: l10n.bankAccounts,
                      route: '/admin/bank_accounts',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.bar_chart_outlined,
                      title: l10n.financialReports,
                      route: '/admin/reports',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.upload_file_outlined,
                      title: l10n.importExcel,
                      route: '/admin/import',
                    ),
                  ] else ...[
                    _drawerItem(
                      context,
                      icon: Icons.history_outlined,
                      title: l10n.paymentHistory,
                      route: '/member/history',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.contacts_outlined,
                      title: l10n.publicMemberList,
                      route: '/member/directory',
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Controls (Language toggle & Sign out)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Column(
                children: [
                  // Language Switcher
                  InkWell(
                    onTap: () => localeProvider.toggleLocale(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.language, size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(
                            localeProvider.locale.languageCode == 'bn' ? 'বাংলা (Bangla)' : 'English',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            localeProvider.locale.languageCode == 'bn' ? 'Switch to EN' : 'বাংলায় দেখুন',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sign out Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 18, color: AppColors.statusDue),
                      label: Text(
                        l10n.signOut,
                        style: const TextStyle(color: AppColors.statusDue),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (!isSelected) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
    );
  }
}
