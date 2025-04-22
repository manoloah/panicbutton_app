// lib/screens/notifications_settings_screen.dart
import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: Center(
        child: Text(
          'TODO: Implement notifications settings',
          style: tt.bodyLarge, // inherits font & color from your theme
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
