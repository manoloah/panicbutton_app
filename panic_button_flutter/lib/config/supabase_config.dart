import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // For development only - these will be overridden in production
  static void initializeForDev() {
    // No longer needed as we're using dotenv for all environments
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
          'Supabase configuration not found. Make sure your .env file is properly set up.');
    }
  }
}
