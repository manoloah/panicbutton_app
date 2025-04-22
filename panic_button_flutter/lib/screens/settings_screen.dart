import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/auth');
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar sesión'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF132737),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          _SettingsGroup(
            title: 'Cuenta',
            children: [
              _SettingsItem(
                title: 'Perfil',
                onTap: () => context.push('/settings/profile'),
                showDivider: true,
              ),
              _SettingsItem(
                title: 'Preferencias',
                onTap: () => context.push('/settings/preferences'),
                showDivider: true,
              ),
              _SettingsItem(
                title: 'Notificaciones',
                onTap: () => context.push('/settings/notifications'),
                showDivider: false,
              ),
            ],
          ),
          _SettingsGroup(
            title: 'Suscripción',
            children: [
              _SettingsItem(
                title: 'Escoge un plan',
                onTap: () => context.push('/subscribe'),
                showDivider: false,
              ),
            ],
          ),
          _SettingsGroup(
            title: 'Soporte',
            children: [
              _SettingsItem(
                title: 'Centro de ayuda',
                onTap: () {
                  // TODO: Open external URL
                },
                showDivider: false,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 3),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsItem({
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            color: Colors.white.withOpacity(0.1),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
} 