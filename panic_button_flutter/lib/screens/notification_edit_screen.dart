import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationEditScreen extends ConsumerStatefulWidget {
  final String id;
  const NotificationEditScreen({super.key, required this.id});

  @override
  ConsumerState<NotificationEditScreen> createState() => _NotificationEditState();
}

class _NotificationEditState extends ConsumerState<NotificationEditScreen> {
  TimeOfDay? _time;
  Set<Day> _days = {};
  String? _exercise;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(notificationsProvider).firstWhere((n) => n.id == widget.id);
    _time = existing.time;
    _days = Set.from(existing.days);
    _exercise = existing.exerciseSlug;
  }

  void _save() {
    final updated = ReminderNotification(
      id: widget.id,
      time: _time!,
      days: _days,
      exerciseSlug: _exercise!,
    );
    ref.read(notificationsProvider.notifier).update(updated);
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ['calming', 'energizing', 'focus'];
    return Scaffold(
      appBar: AppBar(title: const Text('Editar recordatorio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Hora'),
              subtitle: Text(_time?.format(context) ?? ''),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Day.values.map((d) {
                return FilterChip(
                  label: Text(d.name.substring(0, 3)),
                  selected: _days.contains(d),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _days.add(d);
                      } else {
                        _days.remove(d);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _exercise,
              items: exercises
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _exercise = v),
              decoration: const InputDecoration(labelText: 'Ejercicio'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _time == null || _exercise == null || _days.isEmpty ? null : _save,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
