abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get hasSupabaseConfiguration {
    return supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  }
}
