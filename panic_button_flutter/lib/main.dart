import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:panic_button_flutter/screens/home_screen.dart';
import 'package:panic_button_flutter/screens/breath_screen.dart';
import 'package:panic_button_flutter/screens/settings_screen.dart';
import 'package:panic_button_flutter/screens/profile_settings_screen.dart';
import 'package:panic_button_flutter/screens/notifications_settings_screen.dart';
import 'package:panic_button_flutter/screens/preferences_settings_screen.dart';
import 'package:panic_button_flutter/screens/journey_screen.dart';
import 'package:panic_button_flutter/screens/auth_screen.dart';
import 'package:panic_button_flutter/screens/bolt_screen.dart';
import 'package:panic_button_flutter/theme/app_theme.dart';
import 'package:panic_button_flutter/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables in development
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      await dotenv.load(fileName: '.env');
      SupabaseConfig.initializeForDev();
      debugPrint('Environment variables loaded:');
      debugPrint('SUPABASE_URL: ${SupabaseConfig.supabaseUrl}');
      // Print only the first few characters of the key for security
      debugPrint(
          'SUPABASE_ANON_KEY: ${SupabaseConfig.supabaseAnonKey.substring(0, 10)}...');
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: !const bool.fromEnvironment('dart.vm.product'),
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tu botón de pánico',
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isAuth = Supabase.instance.client.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/auth';

    if (!isAuth && !isAuthRoute) {
      return '/auth';
    }
    if (isAuth && isAuthRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/breathwork',
      builder: (context, state) => const BreathScreen(),
    ),
    GoRoute(
      path: '/breath',
      builder: (context, state) => const BreathScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/profile',
      builder: (context, state) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/preferences',
      builder: (context, state) => const PreferencesSettingsScreen(),
    ),
    GoRoute(
      path: '/journey',
      builder: (context, state) => const JourneyScreen(),
    ),
    GoRoute(
      path: '/bolt',
      builder: (context, state) => const BoltScreen(),
    ),
  ],
);
