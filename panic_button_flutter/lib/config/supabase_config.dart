import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // These environment variables will be injected at build time
  // The values come from --dart-define arguments
  static const String _envSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _envSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static String get supabaseUrl {
    // First check build-time environment variables (production approach)
    if (_envSupabaseUrl.isNotEmpty) {
      return _envSupabaseUrl;
    }

    // Then try to get from .env file (development approach)
    final envValue = dotenv.env['SUPABASE_URL'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    // If we get here, no valid configuration was found
    if (kDebugMode) {
      debugPrint(
          'WARNING: No Supabase URL found in either build-time variables or .env');
    }

    return '';
  }

  static String get supabaseAnonKey {
    // First check build-time environment variables (production approach)
    if (_envSupabaseAnonKey.isNotEmpty) {
      return _envSupabaseAnonKey;
    }

    // Then try to get from .env file (development approach)
    final envValue = dotenv.env['SUPABASE_ANON_KEY'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    // If we get here, no valid configuration was found
    if (kDebugMode) {
      debugPrint(
          'WARNING: No Supabase Anon Key found in either build-time variables or .env');
    }

    return '';
  }
}
