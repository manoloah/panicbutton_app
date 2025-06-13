import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../config/app_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Android settings
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings with proper permissions
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings = InitializationSettings(android: android, iOS: ios);

      // Initialize the plugin
      final initialized = await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        debugPrint('✅ Notification service initialized successfully');
      } else {
        debugPrint('❌ Failed to initialize notification service');
      }

      // Request permissions on iOS
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _requestIOSPermissions();
      }
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  Future<void> _requestIOSPermissions() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint('iOS notification permissions granted: $granted');
  }

  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        debugPrint('Android notification permissions granted: $granted');
        return granted ?? false;
      }
    }
    return true; // iOS permissions are requested during init
  }

  Future<void> schedule(ReminderNotification notification) async {
    if (!_isInitialized) {
      debugPrint(
          '⚠️ Notification service not initialized, initializing now...');
      await init();
    }

    if (!notification.enabled) {
      debugPrint('⚠️ Notification is disabled, skipping schedule');
      return;
    }

    try {
      // Cancel existing notifications for this reminder
      await cancel(notification.id);

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'breathing_reminders',
          'Recordatorios de Respiración',
          channelDescription:
              'Recordatorios para practicar ejercicios de respiración',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      );

      int notificationIdCounter = 0;

      for (final day in notification.days) {
        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          notification.time.hour,
          notification.time.minute,
        );

        // Find the next occurrence of this day
        while (scheduled.weekday != day.index + 1) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        // If the time has already passed today, schedule for next week
        if (scheduled.isBefore(now) ||
            (scheduled.day == now.day && scheduled.isBefore(now))) {
          scheduled = scheduled.add(const Duration(days: 7));
        }

        final notificationId = '${notification.id}_${day.name}'.hashCode;

        await _plugin.zonedSchedule(
          notificationId,
          _getNotificationTitle(notification),
          _getNotificationBody(notification),
          scheduled,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '${notification.exerciseSlug}:${notification.id}',
        );

        notificationIdCounter++;
        debugPrint(
            '📅 Scheduled notification for ${day.name} at ${notification.time.format}');
      }

      debugPrint(
          '✅ Successfully scheduled ${notificationIdCounter} notifications for ${notification.customTitle ?? notification.timeDisplayName}');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  Future<void> cancel(String notificationId) async {
    try {
      // Cancel all related notifications (one for each day)
      for (final day in Day.values) {
        final dayNotificationId = '${notificationId}_${day.name}'.hashCode;
        await _plugin.cancel(dayNotificationId);
      }
      debugPrint('✅ Cancelled notifications for ID: $notificationId');
    } catch (e) {
      debugPrint('❌ Error cancelling notification: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('✅ Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  String _getNotificationTitle(ReminderNotification notification) {
    final customTitle = notification.customTitle;
    if (customTitle != null && customTitle.isNotEmpty) {
      return customTitle;
    }

    final hour = notification.time.hour;
    if (hour >= 5 && hour < 12) {
      return '🌅 Respiración Matutina';
    } else if (hour >= 12 && hour < 18) {
      return '☀️ Momento de Respirar';
    } else {
      return '🌙 Respiración Nocturna';
    }
  }

  String _getNotificationBody(ReminderNotification notification) {
    return 'Es hora de tu ejercicio de respiración. Abre ${AppConfig.appName} para relajarte.';
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    debugPrint('📱 Notification tapped with payload: $payload');

    if (payload != null) {
      final parts = payload.split(':');
      if (parts.length >= 2) {
        final exerciseSlug = parts[0];
        final notificationId = parts[1];
        debugPrint(
            '🎯 Opening exercise: $exerciseSlug for notification: $notificationId');
        // TODO: Navigate to specific exercise
        // This could be handled through a stream or callback
      }
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
