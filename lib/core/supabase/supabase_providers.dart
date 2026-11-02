import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_config.dart';
import 'supabase_rest.dart';

/// Null when online features are switched off (for example in tests).
final supabaseProvider = Provider<SupabaseRest?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return SupabaseRest(
    baseUrl: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
});
