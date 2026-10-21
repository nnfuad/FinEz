import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'models/member.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/bank_accounts_screen.dart';
import 'screens/admin/excel_import_screen.dart';
import 'screens/admin/installment_management_screen.dart';
import 'screens/admin/member_form_screen.dart';
import 'screens/admin/member_list_screen.dart';
import 'screens/admin/payment_history_screen.dart';
import 'screens/admin/payment_record_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/member/member_dashboard_screen.dart';
import 'screens/member/public_directory_screen.dart';
import 'services/auth_service.dart';
import 'services/bank_account_service.dart';
import 'services/import_service.dart';
import 'services/installment_service.dart';
import 'services/member_service.dart';
import 'services/payment_service.dart';
import 'services/report_service.dart';
import 'l10n/app_localizations.dart';

class FinEzApp extends StatefulWidget {
  final SupabaseClient supabase;

  const FinEzApp({super.key, required this.supabase});

  @override
  State<FinEzApp> createState() => _FinEzAppState();
}

class _FinEzAppState extends State<FinEzApp> {
  late final LocaleProvider _localeProvider;
  late final AuthService _authService;
  late final MemberService _memberService;
  late final InstallmentService _installmentService;
  late final PaymentService _paymentService;
  late final BankAccountService _bankAccountService;
  late final ReportService _reportService;
  late final ImportService _importService;

  @override
  void initState() {
    super.initState();
    _localeProvider = LocaleProvider();
    _authService = AuthService(widget.supabase);
    _memberService = MemberService(widget.supabase);
    _installmentService = InstallmentService(widget.supabase);
    _paymentService = PaymentService(widget.supabase);
    _bankAccountService = BankAccountService(widget.supabase);
    _reportService = ReportService(widget.supabase);
    _importService = ImportService(widget.supabase);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_localeProvider, _authService]),
      builder: (context, _) {
        return MaterialApp(
          title: 'FinEz',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          locale: _localeProvider.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: _getInitialRoute(),
          onGenerateRoute: (settings) => _generateRoute(settings),
        );
      },
    );
  }

  String _getInitialRoute() {
    if (!_authService.isAuthenticated) {
      return '/login';
    }
    if (_authService.isAdmin) {
      return '/admin/dashboard';
    }
    return '/member/dashboard';
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => LoginScreen(
            authService: _authService,
            localeProvider: _localeProvider,
          ),
        );

      case '/reset-password':
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(authService: _authService),
        );

      // Admin Routes
      case '/admin/dashboard':
        return _adminRoute(
          AdminDashboardScreen(
            authService: _authService,
            memberService: _memberService,
            installmentService: _installmentService,
            paymentService: _paymentService,
            bankAccountService: _bankAccountService,
            reportService: _reportService,
            localeProvider: _localeProvider,
          ),
        );

      case '/admin/members':
        return _adminRoute(
          MemberListScreen(
            authService: _authService,
            memberService: _memberService,
            localeProvider: _localeProvider,
          ),
        );

      case '/admin/member-form':
        final member = settings.arguments as Member?;
        return _adminRoute(
          MemberFormScreen(
            memberService: _memberService,
            existingMember: member,
          ),
        );

      case '/admin/installments':
        return _adminRoute(
          InstallmentManagementScreen(
            authService: _authService,
            installmentService: _installmentService,
            localeProvider: _localeProvider,
          ),
        );

      case '/admin/record-payment':
        return _adminRoute(
          PaymentRecordScreen(
            memberService: _memberService,
            installmentService: _installmentService,
            bankAccountService: _bankAccountService,
            paymentService: _paymentService,
            localeProvider: _localeProvider,
          ),
        );

      case '/admin/payments':
        return _adminRoute(
          PaymentHistoryScreen(
            authService: _authService,
            paymentService: _paymentService,
            bankAccountService: _bankAccountService,
            localeProvider: _localeProvider,
          ),
        );

      case '/admin/bank_accounts':
        return _adminRoute(
          BankAccountsScreen(
            authService: _authService,
            bankAccountService: _bankAccountService,
            localeProvider: _localeProvider,
          ),
        );

      case '/admin/reports':
        return _adminRoute(
          ReportsScreen(
            authService: _authService,
            reportService: _reportService,
            localeProvider: _localeProvider,
          ),
        );

      case '/admin/import':
        return _adminRoute(
          ExcelImportScreen(
            authService: _authService,
            importService: _importService,
            localeProvider: _localeProvider,
          ),
        );

      // Member Routes
      case '/member/dashboard':
        return MaterialPageRoute(
          builder: (_) => MemberDashboardScreen(
            authService: _authService,
            memberService: _memberService,
            installmentService: _installmentService,
            paymentService: _paymentService,
            localeProvider: _localeProvider,
          ),
        );

      case '/member/directory':
        return MaterialPageRoute(
          builder: (_) => PublicDirectoryScreen(
            authService: _authService,
            memberService: _memberService,
            localeProvider: _localeProvider,
          ),
        );

      case '/member/history':
        return MaterialPageRoute(
          builder: (_) => MemberDashboardScreen(
            authService: _authService,
            memberService: _memberService,
            installmentService: _installmentService,
            paymentService: _paymentService,
            localeProvider: _localeProvider,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: Text('Route not found', style: TextStyle(color: AppColors.textPrimary))),
          ),
        );
    }
  }

  /// Route guard that redirects non-admins away from administrative routes
  Route<dynamic> _adminRoute(Widget screen) {
    if (!_authService.isAuthenticated) {
      return MaterialPageRoute(
        builder: (_) => LoginScreen(authService: _authService, localeProvider: _localeProvider),
      );
    }
    if (!_authService.isAdmin) {
      return MaterialPageRoute(
        builder: (_) => MemberDashboardScreen(
          authService: _authService,
          memberService: _memberService,
          installmentService: _installmentService,
          paymentService: _paymentService,
          localeProvider: _localeProvider,
        ),
      );
    }
    return MaterialPageRoute(builder: (_) => screen);
  }
}
