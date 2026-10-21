/// Application configuration holding public client credentials.
///
/// Security Notice:
/// Only client-safe publishable keys and public endpoints are defined here.
/// Never store service_role or admin secret keys in Flutter client code.
class AppConfig {
  AppConfig._();

  static const String appName = 'FinEz';
  static const String appSubtitleBn = 'সহজ আর্থিক ব্যবস্থাপনা';
  static const String appVersion = '1.0.0';

  // Configured with fallback to the project owner's public client credentials,
  // or overridden at build time via --dart-define.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wrokcfqfcyinsftdisks.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_KS30PVbqGw_xaAYdzV_POw_F_Z-nIKh',
  );
}
