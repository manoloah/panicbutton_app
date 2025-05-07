// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go('/auth');
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cerrar sesión',
              style: TextStyle(color: cs.onError),
            ),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      // backgroundColor omitted → uses scaffoldBackgroundColor
      appBar: AppBar(
        // uses appBarTheme.backgroundColor & titleTextStyle
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () => _handleLogout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                elevation: 4,
                shadowColor: cs.shadow.withOpacity(0.5),
                side: BorderSide(
                  color: cs.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Text('Cerrar Sesión'),
            ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: tt.headlineMedium,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: tt.bodyLarge,
          ),
          trailing: Icon(Icons.chevron_right, color: cs.onBackground),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            color: cs.onSurface.withOpacity(0.1),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
