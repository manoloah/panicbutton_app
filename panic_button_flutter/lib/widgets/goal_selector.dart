import 'package:flutter/material.dart';
import 'package:panic_button_flutter/models/breath_types.dart';
import 'package:panic_button_flutter/services/breath_queries.dart';

/// A widget that allows users to select a breathing goal
class GoalSelector extends StatefulWidget {
  final String? initialGoal;
  final Function(String) onGoalSelected;

  const GoalSelector({
    Key? key,
    this.initialGoal,
    required this.onGoalSelected,
  }) : super(key: key);

  @override
  State<GoalSelector> createState() => _GoalSelectorState();
}

class _GoalSelectorState extends State<GoalSelector> {
  String? _selectedGoal;
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal ?? 'calming';
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    try {
      // Get all goals from Supabase
      final response = await supabase.from('goals').select();

      final List<Goal> goals =
          response.map<Goal>((data) => Goal.fromJson(data)).toList();

      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to default goals if database isn't available
      setState(() {
        _goals = [
          const Goal(id: '1', slug: 'calming', displayName: 'Calma'),
          const Goal(id: '2', slug: 'focusing', displayName: 'Enfoque'),
          const Goal(id: '3', slug: 'energizing', displayName: 'Energía'),
          const Goal(id: '4', slug: 'grounding', displayName: 'Equilibrio'),
        ];
        _isLoading = false;
      });
    }
  }

  Widget _getIconForGoal(String slug) {
    // Since we don't have actual icon assets yet, we'll use placeholder icons
    IconData iconData;
    switch (slug) {
      case 'calming':
        iconData = Icons.air;
        break;
      case 'focusing':
        iconData = Icons.center_focus_strong;
        break;
      case 'energizing':
        iconData = Icons.bolt;
        break;
      case 'grounding':
        iconData = Icons.spa;
        break;
      default:
        iconData = Icons.air;
    }

    return Icon(
      iconData,
      size: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _goals.length,
        itemBuilder: (context, index) {
          final goal = _goals[index];
          final bool isSelected = goal.slug == _selectedGoal;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedGoal = goal.slug);
                widget.onGoalSelected(goal.slug);
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _getIconForGoal(goal.slug),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goal.displayName,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
