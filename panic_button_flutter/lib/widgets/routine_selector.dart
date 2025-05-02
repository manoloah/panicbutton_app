import 'package:flutter/material.dart';
import 'package:panic_button_flutter/models/breathwork_models.dart' as db;
import 'package:panic_button_flutter/services/exercise_service.dart';

class RoutineSelector extends StatefulWidget {
  final db.Goal goal;
  final Function(db.Routine routine) onRoutineSelected;

  const RoutineSelector({
    super.key,
    required this.goal,
    required this.onRoutineSelected,
  });

  @override
  State<RoutineSelector> createState() => _RoutineSelectorState();
}

class _RoutineSelectorState extends State<RoutineSelector> {
  final ExerciseService _exerciseService = ExerciseService();
  List<db.Routine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routines = await _exerciseService.getRoutinesByGoal(widget.goal.id);
      setState(() {
        _routines = routines;
      });
    } catch (e) {
      debugPrint('Error loading routines: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se encontraron rutinas para ${widget.goal.displayName}',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRoutines,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                widget.goal.displayName,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _routines.length,
              itemBuilder: (context, index) {
                final routine = _routines[index];
                return RoutineTile(
                  routine: routine,
                  onTap: () => widget.onRoutineSelected(routine),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RoutineTile extends StatelessWidget {
  final db.Routine routine;
  final VoidCallback onTap;

  const RoutineTile({
    super.key,
    required this.routine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  '${routine.totalMinutes ?? "?"}m',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name ?? 'Rutina de respiración',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
