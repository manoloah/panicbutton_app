// lib/screens/preferences_settings_screen.dart
import 'package:flutter/material.dart';

class PreferencesSettingsScreen extends StatelessWidget {
  const PreferencesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      // backgroundColor omitted → uses scaffoldBackgroundColor from AppTheme.dark()
      appBar: AppBar(
        // uses appBarTheme.backgroundColor & titleTextStyle
        title: const Text('Preferencias'),
      ),
      body: Center(
        child: Text(
          'TODO: Implement preferences settings',
          style: tt.bodyLarge, // inherits font & color from your theme
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
