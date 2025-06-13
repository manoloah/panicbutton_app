# Notifications Implementation

## Overview

This document outlines a cost‑effective approach to add reminder notifications to the Calme app. The goal is to let users schedule daily breathing reminders similar to the Breathwrk application while keeping the running costs minimal.

## Recommended Stack

1. **Local Scheduling with [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)**
   - Free and works on iOS, Android and web
   - Handles repeating notifications and time zone conversions
   - Ideal for user generated reminders ("Mañana 9am", "Medio Día 12pm", etc.)

2. **Optional Push Delivery via Firebase Cloud Messaging (FCM)**
   - FCM is free for standard usage and integrates well with `flutter_local_notifications`
   - Useful if the backend needs to trigger notifications remotely
   - Can be replaced with another provider if a third‑party push service is supplied

Local notifications cover the default reminders and any custom times the user adds. Push notifications are optional and can be integrated later if required by a marketing or engagement service.

## Data Model

```dart
class ReminderNotification {
  final String id; // uuid
  final TimeOfDay time;
  final Set<Day> days; // Day.monday, Day.tuesday, ...
  final String exerciseSlug; // breath pattern slug
  final bool enabled;

  const ReminderNotification({
    required this.id,
    required this.time,
    required this.days,
    required this.exerciseSlug,
    this.enabled = true,
  });
}
```

A `StateNotifier<List<ReminderNotification>>` provider will manage the list of reminders. Notifications can be stored locally using `SharedPreferences` and optionally synced to Supabase for backup.

## UI Behaviour

- **Notifications Settings Screen**
  - Displays the list of reminders as ListTiles
  - "+" FAB in the top‑right corner to add a reminder
  - "-" icon (or swipe action) to delete
  - Toggle switch to enable/disable each reminder

- **Edit Reminder Screen**
  - Opens when a ListTile is tapped
  - Lets the user choose:
    - Time of day (Time picker)
    - Days of the week (chips)
    - Breathing exercise (dropdown from available patterns)
  - Saves to the provider and schedules via `NotificationService`

### Default Reminders

When a user opens the screen for the first time three reminders are preloaded but disabled until the user opts in:

- Mañana – 9:00 AM
- Medio Día – 12:00 PM
- Noche – 8:00 PM

These can be enabled/disabled individually and edited like any other reminder.

## Scheduling Logic

`NotificationService` wraps `flutter_local_notifications` and exposes methods to:

- initialise the plugin with proper Android/iOS settings
- schedule or cancel reminders based on the provider state
- reschedule notifications when the time or days change

The service will use the reminder `id` as the notification `payload` so tapping it can navigate directly to the selected breathing exercise.

---

By relying primarily on local scheduling and optional FCM integration, the app gains a fully functional reminder system with zero recurring cost, while still leaving room for a third‑party push provider if one is later required.
