/// Public connection settings for the online component library.
///
/// The URL and the *publishable* (anon) key are designed to ship inside apps;
/// what protects the data is Row Level Security in Supabase (see
/// `supabase/schema.sql`). NEVER put a `secret` / `service_role` key here.
///
/// They can be overridden at build time with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
class SupabaseConfig {
  SupabaseConfig._();

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://khuxfcikhugzylckqfny.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_sOG-7fbHdU6AipliJh6WDg_4D_hq486',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
