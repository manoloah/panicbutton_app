import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:panic_button_flutter/main.dart';
import 'package:panic_button_flutter/screens/breath_screen.dart';

void main() {
  setUpAll(() async {
    // Initialize Supabase with dummy values to satisfy router checks
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-key',
    );
    // Mark initialization complete so the router doesn't redirect to '/'
    isInitialized = true;
  });

  testWidgets('home screen panic button navigates to breath screen',
      (WidgetTester tester) async {
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
