import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Central access point for Supabase.
/// Call [SupabaseService.init()] once in main() before runApp.
class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConfig.projectUrl,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Quick access to the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;
}
