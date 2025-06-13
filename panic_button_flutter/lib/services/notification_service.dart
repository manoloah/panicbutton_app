import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    tz.initializeTimeZones();
  }

  Future<void> schedule(ReminderNotification n) async {
    final details = NotificationDetails(
      android: const AndroidNotificationDetails('reminders', 'Reminders'),
      iOS: const DarwinNotificationDetails(),
    );
    for (final day in n.days) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        n.time.hour,
        n.time.minute,
      );
      while (scheduled.weekday != day.value) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }
      await _plugin.zonedSchedule(
        n.id.hashCode,
        'Hora de respirar',
        'Abre la app para tu ejercicio',
        scheduled,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: n.exerciseSlug,
      );
    }
  }

  Future<void> cancel(String id) async {
    await _plugin.cancel(id.hashCode);
  }
}
