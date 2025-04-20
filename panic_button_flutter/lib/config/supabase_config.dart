import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://mfqqfarcfnskvbvyqvze.supabase.co',
      );

  static String get supabaseAnonKey => const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mcXFmYXJjZm5za3ZidnlxdnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2Nzk5NDksImV4cCI6MjA2MDI1NTk0OX0.3iUAyLCRF_qO_dSbrVNlMuMhZxe2cvLPXBbAiLRw6Lw',
      );

  // For development only - these will be overridden in production
  static void initializeForDev() {
    // These values are only used during development
    const String devUrl = 'https://mfqqfarcfnskvbvyqvze.supabase.co';
    const String devAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1mcXFmYXJjZm5za3ZidnlxdnplIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ2Nzk5NDksImV4cCI6MjA2MDI1NTk0OX0.3iUAyLCRF_qO_dSbrVNlMuMhZxe2cvLPXBbAiLRw6Lw';
  }
} 