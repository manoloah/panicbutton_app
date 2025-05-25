import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:panic_button_flutter/screens/home_screen.dart';
import 'package:panic_button_flutter/screens/breath_screen.dart';
import 'package:panic_button_flutter/screens/settings_screen.dart';
import 'package:panic_button_flutter/screens/profile_settings_screen.dart';
import 'package:panic_button_flutter/screens/notifications_settings_screen.dart';
import 'package:panic_button_flutter/screens/preferences_settings_screen.dart';
import 'package:panic_button_flutter/screens/journey_screen.dart';
import 'package:panic_button_flutter/screens/auth_screen.dart';
import 'package:panic_button_flutter/screens/bolt_screen.dart';
import 'package:panic_button_flutter/screens/mbt_screen.dart';
import 'package:panic_button_flutter/screens/measurement_menu_screen.dart';
import 'package:panic_button_flutter/theme/app_theme.dart';
import 'package:panic_button_flutter/providers/journey_provider.dart';
import 'package:panic_button_flutter/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:panic_button_flutter/config/env_config.dart';

// Global variables to track initialization
bool isInitialized = false;
bool isAuthenticated = false;

// Router key for refreshing navigation state
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize app_links to fix debug mode crash
    final appLinks = AppLinks();
    // Safely initialize app_links without causing debug crashes
    try {
      // Use a timeout to prevent hanging if there's an issue
      await Future.microtask(() async {
        try {
          await appLinks.getInitialAppLink();
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'App links initial link error (safe to ignore in debug): $e',
            );
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'App links initialization error (safe to ignore in debug): $e',
        );
      }
    }

    // Load environment configuration
    await EnvConfig.load();

    // Verify required environment variables
    final hasAllKeys = EnvConfig.verifyRequiredKeys([
      'SUPABASE_URL',
      'SUPABASE_ANON_KEY',
    ]);

    if (!hasAllKeys && kReleaseMode) {
      throw Exception(
          'Missing Supabase configuration in production build. Make sure to include --dart-define arguments.');
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      debug: kDebugMode,
    );

    isInitialized = true;

    // Setup auth state listener to track authentication changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      // Update authentication status
      isAuthenticated = Supabase.instance.client.auth.currentUser != null;

      if (kDebugMode) {
        debugPrint('Auth state changed: $event');
        debugPrint(
            'User is now: ${isAuthenticated ? 'logged in' : 'logged out'}');
      }

      // Force router to reconsider navigation
      if (_rootNavigatorKey.currentState != null) {
        // Refresh navigation (will trigger redirect)
        _router.refresh();
      }
    });

    // Initial auth check
    isAuthenticated = Supabase.instance.client.auth.currentUser != null;

    if (kDebugMode) {
      debugPrint('Supabase initialized successfully');
      debugPrint(
          'Auth status: ${isAuthenticated ? 'Logged in' : 'Not logged in'}');
    }
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // In production, show a user-friendly error message
    if (kReleaseMode) {
      // This could be improved with a proper error UI, but for now
      // we'll let the app crash in a controlled way to help diagnose the issue
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Ocurrió un error al iniciar la aplicación. '
                  'Por favor, intenta de nuevo más tarde.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
  }

  runApp(
    provider_pkg.ChangeNotifierProvider(
      create: (_) => JourneyProvider(),
      child: const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '${AppConfig.appName} - ${AppConfig.appDescription}',
      theme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    // First check if Supabase is initialized
    if (!isInitialized) {
      // Return to home and let error handling take care of it
      return '/';
    }

    // Always check current auth state directly - don't rely on cached value
    final isAuth = Supabase.instance.client.auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/auth';

    if (kDebugMode) {
      debugPrint(
          'Router redirect check - auth: $isAuth, route: ${state.matchedLocation}');
    }

    if (!isAuth && !isAuthRoute) {
      return '/auth';
    }
    if (isAuth && isAuthRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/breathwork',
      builder: (context, state) => const BreathScreen(),
    ),
    GoRoute(path: '/breath', builder: (context, state) => const BreathScreen()),
    GoRoute(
      path: '/breath/:patternSlug',
      builder: (context, state) {
        final patternSlug = state.pathParameters['patternSlug'];
        // Get the previous route to determine if we came from the home screen
        final fromHomePage =
            state.extra is Map && (state.extra as Map)['fromHome'] == true;
        return BreathScreen(patternSlug: patternSlug, autoStart: fromHomePage);
      },
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
    // Measurement menu - this is now the main "Mídete" destination
    GoRoute(
      path: '/measurements',
      builder: (context, state) => const MeasurementMenuScreen(),
    ),
    // Individual measurement screens
    GoRoute(path: '/bolt', builder: (context, state) => const BoltScreen()),
    GoRoute(path: '/mbt', builder: (context, state) => const MbtScreen()),
  ],
);
