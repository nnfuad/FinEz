import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'FinEz'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Simple Financial Management'**
  String get appSubtitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @installments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installments;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @bankAccounts.
  ///
  /// In en, this message translates to:
  /// **'Bank Accounts'**
  String get bankAccounts;

  /// No description provided for @financialReports.
  ///
  /// In en, this message translates to:
  /// **'Financial Reports'**
  String get financialReports;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @yearlyReport.
  ///
  /// In en, this message translates to:
  /// **'Yearly Report'**
  String get yearlyReport;

  /// No description provided for @importExcel.
  ///
  /// In en, this message translates to:
  /// **'Import Excel'**
  String get importExcel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @loginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your FinEz account'**
  String get loginPrompt;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @roleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unassigned Role'**
  String get roleUnknown;

  /// No description provided for @statusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// No description provided for @statusDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get statusDue;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No description provided for @statusWaived.
  ///
  /// In en, this message translates to:
  /// **'Waived'**
  String get statusWaived;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'৳'**
  String get currencySymbol;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @activeMembers.
  ///
  /// In en, this message translates to:
  /// **'Active Members'**
  String get activeMembers;

  /// No description provided for @expectedInstallments.
  ///
  /// In en, this message translates to:
  /// **'Expected Installments'**
  String get expectedInstallments;

  /// No description provided for @collectedAmount.
  ///
  /// In en, this message translates to:
  /// **'Collected Amount'**
  String get collectedAmount;

  /// No description provided for @outstandingAmount.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Amount'**
  String get outstandingAmount;

  /// No description provided for @fullyPaidMembers.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid Members'**
  String get fullyPaidMembers;

  /// No description provided for @dueMembers.
  ///
  /// In en, this message translates to:
  /// **'Members with Dues'**
  String get dueMembers;

  /// No description provided for @totalBankBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Bank Balance'**
  String get totalBankBalance;

  /// No description provided for @collectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection Rate'**
  String get collectionRate;

  /// No description provided for @memberId.
  ///
  /// In en, this message translates to:
  /// **'Member ID'**
  String get memberId;

  /// No description provided for @memberCode.
  ///
  /// In en, this message translates to:
  /// **'Member Code'**
  String get memberCode;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @standardMonthlyInstallment.
  ///
  /// In en, this message translates to:
  /// **'Standard Monthly Installment'**
  String get standardMonthlyInstallment;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @editMember.
  ///
  /// In en, this message translates to:
  /// **'Edit Member'**
  String get editMember;

  /// No description provided for @searchMembers.
  ///
  /// In en, this message translates to:
  /// **'Search members...'**
  String get searchMembers;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get filterInactive;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount Due'**
  String get amountDue;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amountPaid;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @generateInstallments.
  ///
  /// In en, this message translates to:
  /// **'Generate Installments'**
  String get generateInstallments;

  /// No description provided for @generatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Generate installments for all active members for this month?'**
  String get generatePrompt;

  /// No description provided for @installmentsGenerated.
  ///
  /// In en, this message translates to:
  /// **'Installments generated successfully'**
  String get installmentsGenerated;

  /// No description provided for @noInstallmentsFound.
  ///
  /// In en, this message translates to:
  /// **'No installments found for this period'**
  String get noInstallmentsFound;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @recordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded At'**
  String get recordedAt;

  /// No description provided for @recordedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded By'**
  String get recordedBy;

  /// No description provided for @destinationBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Destination Bank Account'**
  String get destinationBankAccount;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference / Notes'**
  String get reference;

  /// No description provided for @correctionReason.
  ///
  /// In en, this message translates to:
  /// **'Correction Reason'**
  String get correctionReason;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @correctPayment.
  ///
  /// In en, this message translates to:
  /// **'Correct Payment'**
  String get correctPayment;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get openingBalance;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @transferFunds.
  ///
  /// In en, this message translates to:
  /// **'Transfer Funds'**
  String get transferFunds;

  /// No description provided for @sourceAccount.
  ///
  /// In en, this message translates to:
  /// **'Source Account'**
  String get sourceAccount;

  /// No description provided for @targetAccount.
  ///
  /// In en, this message translates to:
  /// **'Target Account'**
  String get targetAccount;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @inflow.
  ///
  /// In en, this message translates to:
  /// **'Inflow'**
  String get inflow;

  /// No description provided for @outflow.
  ///
  /// In en, this message translates to:
  /// **'Outflow'**
  String get outflow;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @selectExcelFile.
  ///
  /// In en, this message translates to:
  /// **'Select Excel File (.xlsx)'**
  String get selectExcelFile;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Template'**
  String get downloadTemplate;

  /// No description provided for @previewImport.
  ///
  /// In en, this message translates to:
  /// **'Preview Import'**
  String get previewImport;

  /// No description provided for @applyImport.
  ///
  /// In en, this message translates to:
  /// **'Apply Import'**
  String get applyImport;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'Import Summary'**
  String get importSummary;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get bangla;

  /// No description provided for @personalFinancialSummary.
  ///
  /// In en, this message translates to:
  /// **'My Financial Overview'**
  String get personalFinancialSummary;

  /// No description provided for @recentPayments.
  ///
  /// In en, this message translates to:
  /// **'Recent Payments'**
  String get recentPayments;

  /// No description provided for @noPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No payment records found'**
  String get noPaymentsFound;

  /// No description provided for @publicMemberList.
  ///
  /// In en, this message translates to:
  /// **'Member Directory'**
  String get publicMemberList;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn': return AppLocalizationsBn();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
