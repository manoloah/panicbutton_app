import 'package:flutter/material.dart';
import 'package:panic_button_flutter/models/breathwork_models.dart' as db;
import 'package:panic_button_flutter/services/exercise_service.dart';

class GoalSelector extends StatefulWidget {
  final Function(db.Goal goal) onGoalSelected;

  const GoalSelector({
    super.key,
    required this.onGoalSelected,
  });

  @override
  State<GoalSelector> createState() => _GoalSelectorState();
}

class _GoalSelectorState extends State<GoalSelector> {
  final ExerciseService _exerciseService = ExerciseService();
  List<db.Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final goals = await _exerciseService.getGoals();
      setState(() {
        _goals = goals;
      });
    } catch (e) {
      debugPrint('Error loading goals: $e');
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

    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No se encontraron objetivos',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGoals,
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
          Text(
            'Selecciona un objetivo',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return GoalTile(
                  goal: goal,
                  onTap: () => widget.onGoalSelected(goal),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GoalTile extends StatelessWidget {
  final db.Goal goal;
  final VoidCallback onTap;

  const GoalTile({
    super.key,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Map goals to appropriate colors and icons
    IconData getIconForGoal() {
      switch (goal.slug) {
        case 'calming':
          return Icons.spa;
        case 'energizing':
          return Icons.flash_on;
        case 'focusing':
          return Icons.center_focus_strong;
        case 'grounding':
          return Icons.balance;
        default:
          return Icons.air;
      }
    }

    Color getColorForGoal() {
      switch (goal.slug) {
        case 'calming':
          return Colors.blue;
        case 'energizing':
          return Colors.orange;
        case 'focusing':
          return Colors.purple;
        case 'grounding':
          return Colors.green;
        default:
          return theme.colorScheme.primary;
      }
    }

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
                backgroundColor: getColorForGoal().withOpacity(0.2),
                child: Icon(
                  getIconForGoal(),
                  color: getColorForGoal(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.displayName,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (goal.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        goal.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
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
