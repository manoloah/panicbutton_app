import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

/// Widget that initializes the notification service when the app starts
class NotificationInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationInitializer> createState() =>
      _NotificationInitializerState();
}

class _NotificationInitializerState
    extends ConsumerState<NotificationInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_isInitialized) return;

    try {
      final notifier = ref.read(notificationsProvider.notifier);
      await notifier.initializeNotificationService();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      debugPrint('✅ Notification service initialized in app');
    } catch (e) {
      debugPrint('❌ Error initializing notification service in app: $e');

      if (mounted) {
        setState(() {
          _isInitialized = true; // Still continue with app
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
