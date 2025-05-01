import 'package:flutter/material.dart';
import 'package:panic_button_flutter/models/breath_types.dart';
import 'package:panic_button_flutter/services/breath_queries.dart';

class PatternSelectorModal extends StatefulWidget {
  final String currentPattern;
  final Function(String) onPatternSelected;
  final Function(String) onGoalSelected;

  const PatternSelectorModal({
    Key? key,
    required this.currentPattern,
    required this.onPatternSelected,
    required this.onGoalSelected,
  }) : super(key: key);

  @override
  State<PatternSelectorModal> createState() => _PatternSelectorModalState();
}

class _PatternSelectorModalState extends State<PatternSelectorModal> {
  List<Goal> _goals = [];
  String? _selectedGoal;
  List<Routine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    try {
      // Get all goals from Supabase
      final response = await supabase.from('goals').select();
      final List<Goal> goals =
          response.map<Goal>((data) => Goal.fromJson(data)).toList();

      if (goals.isEmpty) {
        // Use fallback goals if no goals returned from database
        _setFallbackGoals();
      } else {
        setState(() {
          _goals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching goals: $e');
      // Fallback to default goals if database isn't available
      _setFallbackGoals();
    }
  }

  void _setFallbackGoals() {
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

  Future<void> _loadRoutinesForGoal(String goalSlug) async {
    setState(() {
      _selectedGoal = goalSlug;
      _isLoading = true;
    });

    try {
      // Get routines for the selected goal
      final response = await getRoutinesForGoal(goalSlug);

      setState(() {
        _routines = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching routines: $e');
      // Fallback to default routine if database isn't available
      setState(() {
        _routines = [
          Routine(
            id: 'default-routine',
            name: 'Respiración básica',
            goalId: _goals.firstWhere((g) => g.slug == goalSlug).id,
            totalMinutes: 4,
            isPublic: true,
          ),
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
        iconData = Icons.spa;
        break;
      case 'focusing':
        iconData = Icons.center_focus_strong;
        break;
      case 'energizing':
        iconData = Icons.bolt;
        break;
      case 'grounding':
        iconData = Icons.terrain;
        break;
      default:
        iconData = Icons.air;
    }

    return Icon(
      iconData,
      size: 24,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set the pace',
                    style: theme.textTheme.headlineMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content based on selection state
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_selectedGoal == null)
                _buildGoalsGrid()
              else
                _buildRoutinesGrid(),

              const SizedBox(height: 16),

              // Back/Cancel button
              TextButton(
                onPressed: () {
                  if (_selectedGoal != null) {
                    setState(() => _selectedGoal = null);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(_selectedGoal != null ? 'Back' : 'Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];

        return InkWell(
          onTap: () => _loadRoutinesForGoal(goal.slug),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getIconForGoal(goal.slug),
                const SizedBox(height: 12),
                Text(
                  goal.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoutinesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected goal header
        Text(
          _goals.firstWhere((g) => g.slug == _selectedGoal).displayName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // Routines list
        if (_routines.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No routines available for this goal',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _routines.length,
            itemBuilder: (context, index) {
              final routine = _routines[index];

              return ListTile(
                title: Text(routine.name ?? 'Unnamed Routine'),
                subtitle: Text('${routine.totalMinutes ?? 4} min'),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.timer, color: Colors.white),
                ),
                onTap: () {
                  // When a routine is selected
                  widget.onGoalSelected(_selectedGoal!);
                  widget
                      .onPatternSelected('${routine.id}:${routine.name ?? ""}');
                  Navigator.of(context).pop();
                },
              );
            },
          ),
      ],
    );
  }
}
