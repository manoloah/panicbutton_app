import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationsNotifier extends StateNotifier<List<ReminderNotification>> {
  final NotificationService _notificationService;

  NotificationsNotifier(this._notificationService) : super([]) {
    _loadNotifications();
  }

  static final _defaultReminders = <ReminderNotification>[
    ReminderNotification(
      time: const TimeOfDay(hour: 9, minute: 0),
      days: Day.values.toSet(),
      exerciseSlug: 'calming',
      enabled: false,
      customTitle: 'Mañana',
    ),
    ReminderNotification(
      time: const TimeOfDay(hour: 12, minute: 0),
      days: Day.values.toSet(),
      exerciseSlug: 'calming',
      enabled: false,
      customTitle: 'Medio Día',
    ),
    ReminderNotification(
      time: const TimeOfDay(hour: 20, minute: 0),
      days: Day.values.toSet(),
      exerciseSlug: 'calming',
      enabled: false,
      customTitle: 'Noche',
    ),
  ];

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];

      if (notificationsJson.isEmpty) {
        // First time, use default reminders
        state = _defaultReminders;
        await _saveNotifications();
      } else {
        // Load from storage
        final notifications = notificationsJson
            .map((json) => ReminderNotification.fromJson(jsonDecode(json)))
            .toList();
        state = notifications;
      }
      debugPrint('✅ Loaded ${state.length} notifications from storage');
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      state = _defaultReminders;
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = state
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      await prefs.setStringList('notifications', notificationsJson);
      debugPrint('✅ Saved ${state.length} notifications to storage');
    } catch (e) {
      debugPrint('❌ Error saving notifications: $e');
    }
  }

  Future<void> add(ReminderNotification notification) async {
    state = [...state, notification];
    await _saveNotifications();

    if (notification.enabled) {
      await _notificationService.schedule(notification);
    }
  }

  Future<void> remove(String id) async {
    await _notificationService.cancel(id);
    state = state.where((n) => n.id != id).toList();
    await _saveNotifications();
  }

  Future<void> update(ReminderNotification notification) async {
    // Cancel old notification first
    await _notificationService.cancel(notification.id);

    // Update state
    state = [
      for (final n in state)
        if (n.id == notification.id) notification else n,
    ];

    // Save to storage
    await _saveNotifications();

    // Schedule new notification if enabled
    if (notification.enabled) {
      await _notificationService.schedule(notification);
    }
  }

  Future<void> initializeNotificationService() async {
    await _notificationService.init();

    // Request permissions
    final permissionsGranted = await _notificationService.requestPermissions();
    if (!permissionsGranted) {
      debugPrint('⚠️ Notification permissions not granted');
    }

    // Reschedule all enabled notifications
    for (final notification in state.where((n) => n.enabled)) {
      await _notificationService.schedule(notification);
    }
  }

  Future<void> clearAllNotifications() async {
    await _notificationService.cancelAll();
    state = [];
    await _saveNotifications();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<ReminderNotification>>(
        (ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationsNotifier(notificationService);
});
