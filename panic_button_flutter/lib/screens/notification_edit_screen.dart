import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../providers/breathing_providers.dart';
import '../constants/spacing.dart';
import '../widgets/custom_sliver_app_bar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationEditScreen extends ConsumerStatefulWidget {
  final String id;
  const NotificationEditScreen({super.key, required this.id});

  @override
  ConsumerState<NotificationEditScreen> createState() =>
      _NotificationEditState();
}

class _NotificationEditState extends ConsumerState<NotificationEditScreen> {
  TimeOfDay? _time;
  Set<Day> _days = {};
  String? _exerciseSlug;
  String? _customTitle;
  bool _isNewNotification = false;

  @override
  void initState() {
    super.initState();
    final notifications = ref.read(notificationsProvider);
    final existing = notifications.firstWhere(
      (n) => n.id == widget.id,
      orElse: () => ReminderNotification(
        time: TimeOfDay.now(),
        days: Day.values.toSet(),
        exerciseSlug: 'calming',
      ),
    );

    _time = existing.time;
    _days = Set.from(existing.days);
    _exerciseSlug = existing.exerciseSlug;
    _customTitle = existing.customTitle;
    _isNewNotification = !notifications.any((n) => n.id == widget.id);
  }

  void _save() {
    if (_time == null || _exerciseSlug == null || _days.isEmpty) return;

    final updated = ReminderNotification(
      id: widget.id,
      time: _time!,
      days: _days,
      exerciseSlug: _exerciseSlug!,
      customTitle: _customTitle,
      enabled: true,
    );

    ref.read(notificationsProvider.notifier).update(updated);
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar este recordatorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).remove(widget.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close edit screen
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patterns = ref.watch(patternsForGoalProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            CustomSliverAppBar(
              showBackButton: true,
              backRoute: '/settings/notifications',
              showSettings: false,
              title: Text(
                _isNewNotification ? 'Nuevo Recordatorio' : 'Editar',
                style: theme.textTheme.headlineMedium,
              ),
              additionalActions: [
                if (!_isNewNotification)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete,
                    tooltip: 'Eliminar recordatorio',
                  ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTimeSection(theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildDaysSection(theme, colorScheme),
                  const SizedBox(height: 24),
                  _buildExerciseSection(theme, colorScheme, patterns),
                  const SizedBox(height: 24),
                  _buildCustomTitleSection(theme, colorScheme),
                  const SizedBox(height: 100), // Space for save button
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(theme, colorScheme),
    );
  }

  Widget _buildTimeSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hora',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Icon(
              Icons.access_time,
              color: colorScheme.primary,
            ),
            title: Text(
              _time?.format(context) ?? 'Seleccionar hora',
              style: theme.textTheme.bodyLarge,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días de la semana',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Quick select buttons - more compact
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _days = Day.values.toSet();
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Todos', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _days = {
                      Day.monday,
                      Day.tuesday,
                      Day.wednesday,
                      Day.thursday,
                      Day.friday
                    };
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Semana', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _days = {Day.saturday, Day.sunday};
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child:
                    const Text('Fin de semana', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Individual day chips
        Wrap(
          spacing: Spacing.s,
          runSpacing: Spacing.s,
          children: Day.values.map((day) {
            final isSelected = _days.contains(day);
            return FilterChip(
              label: Text(_getDaySpanishName(day)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _days.add(day);
                  } else {
                    _days.remove(day);
                  }
                });
              },
              selectedColor: colorScheme.primary.withOpacity(0.2),
              checkmarkColor: colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExerciseSection(
      ThemeData theme, ColorScheme colorScheme, AsyncValue patterns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ejercicio de respiración',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s),
        patterns.when(
          data: (patternsList) {
            if (patternsList.isEmpty) {
              return Card(
                child: ListTile(
                  leading:
                      Icon(Icons.self_improvement, color: colorScheme.primary),
                  title: const Text('Respiración calmante'),
                  subtitle: const Text('Ejercicio por defecto'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _exerciseSlug = 'calming'),
                ),
              );
            }

            return Column(
              children: patternsList.take(5).map<Widget>((pattern) {
                final isSelected = _exerciseSlug == pattern.slug;
                return Card(
                  margin: const EdgeInsets.only(bottom: Spacing.s),
                  color:
                      isSelected ? colorScheme.primary.withOpacity(0.1) : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.self_improvement,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: Text(pattern.name),
                    subtitle:
                        Text('${pattern.recommendedMinutes} min recomendados'),
                    trailing: Icon(
                      isSelected ? Icons.check_circle : Icons.chevron_right,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                    onTap: () => setState(() => _exerciseSlug = pattern.slug),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Card(
            child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Cargando ejercicios...'),
            ),
          ),
          error: (error, _) => Card(
            child: ListTile(
              leading: Icon(Icons.error, color: colorScheme.error),
              title: const Text('Error al cargar ejercicios'),
              subtitle: Text(error.toString()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTitleSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Título personalizado (opcional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.s),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
            child: TextField(
              controller: TextEditingController(text: _customTitle),
              decoration: const InputDecoration(
                hintText: 'Ej: Respiración matutina',
                border: InputBorder.none,
                icon: Icon(Icons.edit_outlined),
              ),
              onChanged: (value) => _customTitle = value.isEmpty ? null : value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme, ColorScheme colorScheme) {
    final canSave = _time != null && _exerciseSlug != null && _days.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(Spacing.m),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSave ? _save : null,
          style: ElevatedButton.styleFrom(
            minimumSize:
                const Size(double.infinity, ComponentSpacing.buttonHeight),
          ),
          child: const Text('Guardar Recordatorio'),
        ),
      ),
    );
  }

  String _getDaySpanishName(Day day) {
    switch (day) {
      case Day.monday:
        return 'Lunes';
      case Day.tuesday:
        return 'Martes';
      case Day.wednesday:
        return 'Miércoles';
      case Day.thursday:
        return 'Jueves';
      case Day.friday:
        return 'Viernes';
      case Day.saturday:
        return 'Sábado';
      case Day.sunday:
        return 'Domingo';
    }
  }
}
