import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:panic_button_flutter/main.dart';
import 'package:panic_button_flutter/screens/breath_screen.dart';

// If 'isInitialized' is from main.dart, import it explicitly if not already
// import 'package:panic_button_flutter/main.dart' show isInitialized;

void main() {
  setUpAll(() async {
    // Make sure bindings are initialized before anything else
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock SharedPreferences (required for plugin calls in tests)
    SharedPreferences.setMockInitialValues({});

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
    // Use ProviderScope to wrap MyApp for Riverpod support
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify the start button is shown on the home screen
    final startFinder = find.text('EMPEZAR');
    expect(startFinder, findsOneWidget);

    // Tap the panic button and allow navigation to complete
    await tester.tap(startFinder);
    await tester.pumpAndSettle();

    // The breathing screen should be displayed after navigation
    expect(find.byType(BreathScreen), findsOneWidget);
  });
}
