import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF132737),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notificaciones'),
      ),
      body: const Center(
        child: Text(
          'TODO: Implement notifications settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
} 