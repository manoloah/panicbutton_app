// lib/screens/notifications_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final n = ReminderNotification(
                time: TimeOfDay.now(),
                days: {Day.monday},
                exerciseSlug: 'calming',
              );
              notifier.add(n);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.startToEnd,
            onDismissed: (_) => notifier.remove(n.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(n.time.format(context)),
              subtitle: Text(n.exerciseSlug),
              trailing: Switch(
                value: n.enabled,
                onChanged: (v) =>
                    notifier.update(n.copyWith(enabled: v)),
              ),
              onTap: () => context.push('/settings/notifications/${n.id}'),
            ),
          );
        },
      ),
    );
  }
}
