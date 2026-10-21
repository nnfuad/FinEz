import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'FinEz';

  @override
  String get appSubtitle => 'সহজ আর্থিক ব্যবস্থাপনা';

  @override
  String get dashboard => 'ড্যাশবোর্ড';

  @override
  String get members => 'সদস্য তালিকা';

  @override
  String get installments => 'কিস্তি';

  @override
  String get payments => 'জমা / পেমেন্ট';

  @override
  String get bankAccounts => 'ব্যাংক হিসাব';

  @override
  String get financialReports => 'আর্থিক বিবরণী';

  @override
  String get monthlyReport => 'মাসিক প্রতিবেদন';

  @override
  String get yearlyReport => 'বার্ষিক প্রতিবেদন';

  @override
  String get importExcel => 'এক্সেল ইমপোর্ট';

  @override
  String get settings => 'সেটিংস';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get email => 'ইমেইল';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get resetPassword => 'পাসওয়ার্ড রিসেট';

  @override
  String get welcomeBack => 'স্বাগতম';

  @override
  String get loginPrompt => 'আপনার FinEz অ্যাকাউন্টে লগইন করুন';

  @override
  String get roleAdmin => 'অ্যাডমিনিস্ট্রেটর';

  @override
  String get roleMember => 'সদস্য';

  @override
  String get roleUnknown => 'অনির্ধারিত রোল';

  @override
  String get statusPaid => 'পরিশোধিত';

  @override
  String get statusDue => 'বকেয়া';

  @override
  String get statusPartial => 'আংশিক জমা';

  @override
  String get statusWaived => 'মওকুফ';

  @override
  String get statusActive => 'সক্রিয়';

  @override
  String get statusInactive => 'নিষ্ক্রিয়';

  @override
  String get currencySymbol => '৳';

  @override
  String get totalMembers => 'মোট সদস্য';

  @override
  String get activeMembers => 'সক্রিয় সদস্য';

  @override
  String get expectedInstallments => 'প্রত্যাশিত কিস্তি';

  @override
  String get collectedAmount => 'আদায়কৃত অর্থ';

  @override
  String get outstandingAmount => 'বকেয়া অর্থ';

  @override
  String get fullyPaidMembers => 'পরিশোধকারী সদস্য';

  @override
  String get dueMembers => 'বকেয়া সদস্য সংখ্যা';

  @override
  String get totalBankBalance => 'মোট ব্যাংক ব্যালেন্স';

  @override
  String get collectionRate => 'আদায়ের হার';

  @override
  String get memberId => 'সদস্য আইডি';

  @override
  String get memberCode => 'সদস্য কোড';

  @override
  String get fullName => 'পূর্ণ নাম';

  @override
  String get mobileNumber => 'মোবাইল নম্বর';

  @override
  String get address => 'ঠিকানা';

  @override
  String get standardMonthlyInstallment => 'মাসিক নির্ধারিত কিস্তি';

  @override
  String get addMember => 'নতুন সদস্য যোগ করুন';

  @override
  String get editMember => 'সদস্য তথ্য সংশোধন';

  @override
  String get searchMembers => 'সদস্য খুঁজুন...';

  @override
  String get filterAll => 'সকল';

  @override
  String get filterActive => 'সক্রিয়';

  @override
  String get filterInactive => 'নিষ্ক্রিয়';

  @override
  String get month => 'মাস';

  @override
  String get year => 'বছর';

  @override
  String get amountDue => 'নির্ধারিত কিস্তি';

  @override
  String get amountPaid => 'পরিশোধিত টাকা';

  @override
  String get outstanding => 'বকেয়া';

  @override
  String get generateInstallments => 'কিস্তি প্রস্তুত করুন';

  @override
  String get generatePrompt => 'সকল সক্রিয় সদস্যের জন্য এই মাসের কিস্তি প্রস্তুত করতে চান?';

  @override
  String get installmentsGenerated => 'কিস্তি সফলভাবে প্রস্তুত করা হয়েছে';

  @override
  String get noInstallmentsFound => 'এই সময়ের কোনো কিস্তির তথ্য পাওয়া যায়নি';

  @override
  String get recordPayment => 'টাকা জমা রেকর্ড করুন';

  @override
  String get paymentDate => 'পরিশোধের তারিখ';

  @override
  String get recordedAt => 'নথিবদ্ধ হওয়ার সময়';

  @override
  String get recordedBy => 'সংগ্রহকারী অ্যাডমিন';

  @override
  String get destinationBankAccount => 'জমার ব্যাংক হিসাব';

  @override
  String get reference => 'রেফারেন্স / নোট';

  @override
  String get correctionReason => 'সংশোধনের কারণ';

  @override
  String get paymentHistory => 'পেমেন্ট ইতিহাস';

  @override
  String get correctPayment => 'পেমেন্ট সংশোধন';

  @override
  String get bankName => 'ব্যাংকের নাম';

  @override
  String get accountName => 'হিসাবের নাম';

  @override
  String get accountNumber => 'অ্যাকাউন্ট নম্বর';

  @override
  String get openingBalance => 'প্রারম্ভিক স্থিতি';

  @override
  String get currentBalance => 'বর্তমান ব্যালেন্স';

  @override
  String get transferFunds => 'হিসাব স্থানান্তর (ট্রান্সফার)';

  @override
  String get sourceAccount => 'উৎস হিসাব';

  @override
  String get targetAccount => 'গন্তব্য হিসাব';

  @override
  String get transactionType => 'লেনদেনের ধরন';

  @override
  String get inflow => 'জমা (ইনফ্লো)';

  @override
  String get outflow => 'খরচ (আউটফ্লো)';

  @override
  String get description => 'বিবরণ';

  @override
  String get selectExcelFile => 'এক্সেল ফাইল নির্বাচন করুন (.xlsx)';

  @override
  String get downloadTemplate => 'নমুনা টেমপ্লেট ডাউনলোড';

  @override
  String get previewImport => 'প্রিভিউ দেখুন';

  @override
  String get applyImport => 'ইমপোর্ট নিশ্চিত করুন';

  @override
  String get importSummary => 'ইমপোর্ট সারসংক্ষেপ';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get confirm => 'নিশ্চিত করুন';

  @override
  String get delete => 'মুছে ফেলুন';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get loading => 'অপেক্ষা করুন...';

  @override
  String get error => 'ত্রুটি';

  @override
  String get success => 'সফল';

  @override
  String get language => 'ভাষা';

  @override
  String get english => 'English';

  @override
  String get bangla => 'বাংলা';

  @override
  String get personalFinancialSummary => 'আমার আর্থিক চিত্র';

  @override
  String get recentPayments => 'সাম্প্রতিক জমা';

  @override
  String get noPaymentsFound => 'কোনো জমার তথ্য পাওয়া যায়নি';

  @override
  String get publicMemberList => 'সদস্য তালিকা ডিরেক্টরি';
}
