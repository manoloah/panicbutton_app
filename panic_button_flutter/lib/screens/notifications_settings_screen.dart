// lib/screens/notifications_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../constants/spacing.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recordatorios',
          style: theme.textTheme.headlineMedium,
        ),
        centerTitle: false,
        actions: [
          // Add notification button (+ icon)
          Container(
            margin: const EdgeInsets.only(right: Spacing.m),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.add,
                size: ComponentSpacing.iconMedium,
                color: colorScheme.onSurface,
              ),
              onPressed: () => _addNewReminder(context, notifier),
            ),
          ),
          // Test notification button (debug mode only)
          if (kDebugMode)
            Container(
              margin: const EdgeInsets.only(right: Spacing.s),
              child: IconButton(
                icon: Icon(
                  Icons.bug_report,
                  size: ComponentSpacing.iconMedium,
                  color: colorScheme.onSurface,
                ),
                onPressed: () => _testNotification(context),
                tooltip: 'Test notification',
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context, notifier)
          : _buildNotificationsList(context, notifications, notifier),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, NotificationsNotifier notifier) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: Spacing.l),
            Text(
              'Sin recordatorios',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s),
            Text(
              'Agrega recordatorios para mantener tu rutina de respiración',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            ElevatedButton(
              onPressed: () => _addNewReminder(context, notifier),
              child: const Text('Agregar Recordatorio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    List<ReminderNotification> notifications,
    NotificationsNotifier notifier,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.m),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: Spacing.s),
      itemBuilder: (context, index) => _buildNotificationCard(
        context,
        notifications[index],
        notifier,
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    ReminderNotification notification,
    NotificationsNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Spacing.m),
        side: BorderSide(
          color: colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.m),
        onTap: () => context.push('/settings/notifications/${notification.id}'),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.m),
          child: Row(
            children: [
              // Time period icon
              Container(
                width: ComponentSpacing.iconLarge + Spacing.s,
                height: ComponentSpacing.iconLarge + Spacing.s,
                decoration: BoxDecoration(
                  color: _getTimeIconColor(notification.time.hour, colorScheme),
                  borderRadius: BorderRadius.circular(Spacing.s),
                ),
                child: Icon(
                  _getTimeIcon(notification.time.hour),
                  color: Colors.white,
                  size: ComponentSpacing.iconMedium,
                ),
              ),
              const SizedBox(width: Spacing.m),

              // Notification details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          notification.customTitle ??
                              notification.timeDisplayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.formatTime(context),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      notification.daysDisplayString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: Spacing.m),

              // Toggle switch
              Switch.adaptive(
                value: notification.enabled,
                onChanged: (value) {
                  notifier.update(notification.copyWith(enabled: value));
                },
                activeColor: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTimeIcon(int hour) {
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny; // Morning sun
    } else if (hour >= 12 && hour < 18) {
      return Icons.wb_sunny_outlined; // Afternoon sun
    } else {
      return Icons.nights_stay; // Night moon
    }
  }

  Color _getTimeIconColor(int hour, ColorScheme colorScheme) {
    if (hour >= 5 && hour < 12) {
      return const Color(0xFFFFB74D); // Morning orange
    } else if (hour >= 12 && hour < 18) {
      return const Color(0xFF42A5F5); // Afternoon blue
    } else {
      return const Color(0xFF7E57C2); // Night purple
    }
  }

  void _addNewReminder(BuildContext context, NotificationsNotifier notifier) {
    final newNotification = ReminderNotification(
      time: TimeOfDay.now(),
      days: Day.values.toSet(),
      exerciseSlug: 'calming',
      enabled: true,
    );

    notifier.add(newNotification);

    // Navigate to edit the new notification
    context.push('/settings/notifications/${newNotification.id}');
  }

  Future<void> _testNotification(BuildContext context) async {
    final notificationService = NotificationService();

    // Create a test notification that triggers in 5 seconds
    final testNotification = ReminderNotification(
      time: TimeOfDay.now(),
      days: {Day.values[DateTime.now().weekday - 1]},
      exerciseSlug: 'calming',
      enabled: true,
      customTitle: 'Prueba de Notificación',
    );

    await notificationService.init();

    // Schedule a notification for 5 seconds from now
    final plugin = FlutterLocalNotificationsPlugin();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Notificaciones de Prueba',
        channelDescription: 'Canal para probar notificaciones',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await plugin.show(
      999999,
      '🧪 Prueba de Notificación',
      'Esta es una notificación de prueba inmediata',
      details,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación de prueba enviada!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
