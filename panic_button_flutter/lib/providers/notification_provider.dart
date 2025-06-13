import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

class NotificationsNotifier extends StateNotifier<List<ReminderNotification>> {
  NotificationsNotifier() : super(_defaultReminders);

  static final _defaultReminders = <ReminderNotification>[
    ReminderNotification(
      time: const TimeOfDay(hour: 9, minute: 0),
      days: Day.values.toSet(),
      exerciseSlug: 'calming',
      enabled: false,
    ),
    ReminderNotification(
      time: const TimeOfDay(hour: 12, minute: 0),
      days: Day.values.toSet(),
      exerciseSlug: 'calming',
      enabled: false,
    ),
    ReminderNotification(
      time: const TimeOfDay(hour: 20, minute: 0),
      days: Day.values.toSet(),
      exerciseSlug: 'calming',
      enabled: false,
    ),
  ];

  void add(ReminderNotification notification) {
    state = [...state, notification];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void update(ReminderNotification notification) {
    state = [
      for (final n in state)
        if (n.id == notification.id) notification else n,
    ];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<ReminderNotification>>(
        (ref) => NotificationsNotifier());
