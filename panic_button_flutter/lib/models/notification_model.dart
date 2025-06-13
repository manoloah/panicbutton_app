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
  final String? customTitle;

  ReminderNotification({
    String? id,
    required this.time,
    required this.days,
    required this.exerciseSlug,
    this.enabled = true,
    this.customTitle,
  }) : id = id ?? const Uuid().v4();

  ReminderNotification copyWith({
    TimeOfDay? time,
    Set<Day>? days,
    String? exerciseSlug,
    bool? enabled,
    String? customTitle,
  }) {
    return ReminderNotification(
      id: id,
      time: time ?? this.time,
      days: days ?? this.days,
      exerciseSlug: exerciseSlug ?? this.exerciseSlug,
      enabled: enabled ?? this.enabled,
      customTitle: customTitle ?? this.customTitle,
    );
  }

  /// Get Spanish display name for the time of day
  String get timeDisplayName {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) {
      return 'Mañana';
    } else if (hour >= 12 && hour < 18) {
      return 'Medio Día';
    } else {
      return 'Noche';
    }
  }

  /// Get formatted time string
  String formatTime(BuildContext context) {
    return time.format(context);
  }

  /// Get days display string in Spanish
  String get daysDisplayString {
    if (days.length == 7) {
      return 'Todos los días';
    } else if (days.length == 5 &&
        days.containsAll([
          Day.monday,
          Day.tuesday,
          Day.wednesday,
          Day.thursday,
          Day.friday
        ])) {
      return 'Días de semana';
    } else if (days.length == 2 &&
        days.containsAll([Day.saturday, Day.sunday])) {
      return 'Fines de semana';
    } else {
      final dayNames = days.map((d) => _getDaySpanishName(d)).join(', ');
      return dayNames;
    }
  }

  String _getDaySpanishName(Day day) {
    switch (day) {
      case Day.monday:
        return 'Lun';
      case Day.tuesday:
        return 'Mar';
      case Day.wednesday:
        return 'Mié';
      case Day.thursday:
        return 'Jue';
      case Day.friday:
        return 'Vie';
      case Day.saturday:
        return 'Sáb';
      case Day.sunday:
        return 'Dom';
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      'days': days.map((d) => d.index).toList(),
      'exerciseSlug': exerciseSlug,
      'enabled': enabled,
      'customTitle': customTitle,
    };
  }

  /// Create from JSON
  factory ReminderNotification.fromJson(Map<String, dynamic> json) {
    return ReminderNotification(
      id: json['id'] as String,
      time: TimeOfDay(
        hour: json['time']['hour'] as int,
        minute: json['time']['minute'] as int,
      ),
      days: (json['days'] as List<dynamic>)
          .map((index) => Day.values[index as int])
          .toSet(),
      exerciseSlug: json['exerciseSlug'] as String,
      enabled: json['enabled'] as bool? ?? true,
      customTitle: json['customTitle'] as String?,
    );
  }
}
