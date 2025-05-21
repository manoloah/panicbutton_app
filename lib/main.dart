import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'package:panic_button_flutter/theme/app_theme.dart';
import 'package:panic_button_flutter/config/supabase_config.dart';
import 'package:panic_button_flutter/providers/journey_provider.dart';
import 'package:panic_button_flutter/config/app_config.dart';
import 'package:flutter/foundation.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _routerConfig());
  }

  GoRouter _routerConfig() {
    return GoRouter(
      routes: [
        GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/breathwork',
          builder: (context, state) => const BreathScreen(),
        ),
        GoRoute(
          path: '/breath',
          builder: (context, state) => const BreathScreen(),
        ),
        GoRoute(
          path: '/breath/:patternSlug',
          builder: (context, state) {
            final patternSlug = state.pathParameters['patternSlug'];
            // Get the previous route to determine if we came from the home screen
            final fromHomePage =
                state.extra is Map && (state.extra as Map)['fromHome'] == true;
            return BreathScreen(
              patternSlug: patternSlug,
              autoStart: fromHomePage,
            );
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
        GoRoute(path: '/bolt', builder: (context, state) => const BoltScreen()),
      ],
    );
  }
}

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of AuthScreen
    return Container();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of HomeScreen
    return Container();
  }
}

class BreathScreen extends StatefulWidget {
  final String? patternSlug;
  final bool autoStart;

  const BreathScreen({Key? key, this.patternSlug, this.autoStart = false})
    : super(key: key);

  @override
  State<BreathScreen> createState() => _BreathScreenState();
}

class _BreathScreenState extends State<BreathScreen> {
  @override
  Widget build(BuildContext context) {
    // Implementation of BreathScreen
    return Container();
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of SettingsScreen
    return Container();
  }
}

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of ProfileSettingsScreen
    return Container();
  }
}

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of NotificationsSettingsScreen
    return Container();
  }
}

class PreferencesSettingsScreen extends StatelessWidget {
  const PreferencesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of PreferencesSettingsScreen
    return Container();
  }
}

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of JourneyScreen
    return Container();
  }
}

class BoltScreen extends StatelessWidget {
  const BoltScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Implementation of BoltScreen
    return Container();
  }
}

void main() {
  runApp(const MyApp());
}
