import 'package:flutter/material.dart';

class PreferencesSettingsScreen extends StatelessWidget {
  const PreferencesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF132737),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Preferencias'),
      ),
      body: const Center(
        child: Text(
          'TODO: Implement preferences settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
} 