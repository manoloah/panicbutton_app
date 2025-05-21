import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// General environment configuration manager for the app
/// Provides centralized access to environment variables with fallback logic
class EnvConfig {
  EnvConfig._(); // Private constructor to prevent instantiation

  // Retrieve values from Dart-define with empty defaults - must be const
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Load .env file in debug mode
  static Future<void> load() async {
    if (kDebugMode) {
      try {
        await dotenv.load(fileName: '.env');
        debugPrint('🔑 Environment loaded from .env file');
      } catch (e) {
        debugPrint('⚠️ No .env file found or error loading it: $e');
        debugPrint('This is expected in production builds');
      }
    }
  }

  /// Get Supabase URL with fallback logic
  static String get supabaseUrl {
    // First check build-time environment variables (production approach)
    if (_supabaseUrl.isNotEmpty) {
      return _supabaseUrl;
    }

    // Then try to get from .env file (development approach)
    final envValue = dotenv.env['SUPABASE_URL'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    // Log warning if value is missing
    if (kDebugMode) {
      debugPrint('⚠️ SUPABASE_URL missing. Use --dart-define or .env file');
    }

    return '';
  }

  /// Get Supabase anonymous key with fallback logic
  static String get supabaseAnonKey {
    // First check build-time environment variables (production approach)
    if (_supabaseAnonKey.isNotEmpty) {
      return _supabaseAnonKey;
    }

    // Then try to get from .env file (development approach)
    final envValue = dotenv.env['SUPABASE_ANON_KEY'];
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    // Log warning if value is missing
    if (kDebugMode) {
      debugPrint(
          '⚠️ SUPABASE_ANON_KEY missing. Use --dart-define or .env file');
    }

    return '';
  }

  /// Verifies that all required environment variables are available
  static bool verifyRequiredKeys(List<String> requiredKeys) {
    final missingKeys = <String>[];

    // Check for required keys
    if (requiredKeys.contains('SUPABASE_URL') && supabaseUrl.isEmpty) {
      missingKeys.add('SUPABASE_URL');
    }

    if (requiredKeys.contains('SUPABASE_ANON_KEY') && supabaseAnonKey.isEmpty) {
      missingKeys.add('SUPABASE_ANON_KEY');
    }

    if (missingKeys.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
            '❌ Missing required environment values: ${missingKeys.join(', ')}');
        debugPrint('App may not function correctly.');
      }
      return false;
    }

    return true;
  }
}
