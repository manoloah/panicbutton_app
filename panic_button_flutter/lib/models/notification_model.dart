import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

/// Data model for a scheduled reminder notification
class ReminderNotification {
  final String id;
  final TimeOfDay time;
  final Set<Day> days;
  final String exerciseSlug;
  final bool enabled;

  ReminderNotification({
    String? id,
    required this.time,
    required this.days,
    required this.exerciseSlug,
    this.enabled = true,
  }) : id = id ?? const Uuid().v4();

  ReminderNotification copyWith({
    TimeOfDay? time,
    Set<Day>? days,
    String? exerciseSlug,
    bool? enabled,
  }) {
    return ReminderNotification(
      id: id,
      time: time ?? this.time,
      days: days ?? this.days,
      exerciseSlug: exerciseSlug ?? this.exerciseSlug,
      enabled: enabled ?? this.enabled,
    );
  }
}
