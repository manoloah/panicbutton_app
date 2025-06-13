import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panic_button_flutter/config/env_config.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/screens/home_screen.dart';
import 'package:panic_button_flutter/theme/app_theme.dart';

import 'package:panic_button_flutter/main.dart';

// If 'isInitialized' is from main.dart, import it explicitly if not already
// import 'package:panic_button_flutter/main.dart' show isInitialized;

void main() {
  setUpAll(() async {
    // Make sure bindings are initialized before anything else
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock SharedPreferences (required for plugin calls in tests)
    SharedPreferences.setMockInitialValues({});

    // Load environment variables from the local .env file
    await EnvConfig.load();

    // Initialize Supabase with dummy keys for router/auth
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-key',
    );

    // If your router relies on this flag, set it
    isInitialized = true; // Make sure this is accessible here
  });

  testWidgets('home screen panic button navigates to breath screen',
      (WidgetTester tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
    binding.window.physicalSizeTestValue = const Size(800, 1280);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });
    // Create a minimal router without auth redirection
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/breath/:patternSlug',
          builder: (context, state) => const Scaffold(body: Text('Breath Screen')),
        ),
      ],
    );

    // Pump the app wrapped with ProviderScope for Riverpod support
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.dark(),
        ),
      ),
    );

    // Verify the start button is shown on the home screen
    final startFinder = find.text('EMPEZAR');
    expect(startFinder, findsOneWidget);

    // Tap the panic button and allow navigation to complete
    await tester.tap(startFinder);
    // Allow navigation to occur
    // Let the navigation and any pending timers complete
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the router navigated to the breath screen
    expect(router.routeInformationProvider.value.uri.toString(), startsWith('/breath'));
  });
}
