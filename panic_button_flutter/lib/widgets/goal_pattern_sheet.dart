import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/models/breath_models.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';

class GoalPatternSheet extends ConsumerStatefulWidget {
  const GoalPatternSheet({super.key});

  @override
  ConsumerState<GoalPatternSheet> createState() => _GoalPatternSheetState();
}

class _GoalPatternSheetState extends ConsumerState<GoalPatternSheet> {
  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    final selectedGoalSlug = ref.watch(selectedGoalProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              height: 5,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Establece el ritmo',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),

          // Goals Row
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: goals.when(
              data: (goalsList) {
                if (goalsList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.sports_gymnastics,
                            size: 48,
                            color: cs.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay metas disponibles',
                            style: tt.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _buildGoalChips(goalsList, selectedGoalSlug);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 32,
                        color: cs.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error cargando metas',
                        style: tt.bodyLarge?.copyWith(color: cs.error),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.toString(),
                        style: tt.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
            child: Text(
              'Patrones de respiración',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
          ),

          // Patterns List
          Expanded(
            child: _buildPatternsList(),
          ),

          // Bottom padding for safety
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildGoalChips(List<GoalModel> goals, String selectedGoalSlug) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: goals.map((goal) {
          final isSelected = goal.slug == selectedGoalSlug;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getGoalIcon(goal.slug, isSelected),
                  const SizedBox(width: 6),
                  Text(goal.displayName),
                ],
              ),
              selected: isSelected,
              selectedColor: cs.primary,
              backgroundColor: cs.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              onSelected: (selected) {
                if (selected) {
                  ref.read(selectedGoalProvider.notifier).state = goal.slug;
                }
              },
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _getGoalIcon(String goalSlug, bool isSelected) {
    final cs = Theme.of(context).colorScheme;
    final color = isSelected ? cs.onPrimary : cs.onSurfaceVariant;

    switch (goalSlug) {
      case 'calming':
        return Icon(Icons.spa, size: 18, color: color);
      case 'focusing':
        return Icon(Icons.psychology, size: 18, color: color);
      case 'energizing':
        return Icon(Icons.bolt, size: 18, color: color);
      case 'grounding':
        return Icon(Icons.balance, size: 18, color: color);
      default:
        return Icon(Icons.circle, size: 18, color: color);
    }
  }

  Widget _buildPatternsList() {
    final patterns = ref.watch(patternsForGoalProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return patterns.when(
      data: (patternsList) {
        if (patternsList.isEmpty) {
          final selectedGoal = ref.read(selectedGoalProvider);

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.air_rounded,
                    size: 48,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay patrones disponibles para esta meta',
                    textAlign: TextAlign.center,
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Reset to calming goal which should have patterns
                      ref.read(selectedGoalProvider.notifier).state = 'calming';
                    },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Probar con otra meta'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Meta actual: $selectedGoal',
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          shrinkWrap: true,
          itemCount: patternsList.length,
          itemBuilder: (context, index) {
            final pattern = patternsList[index];
            return _buildPatternListTile(pattern);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando patrones...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: cs.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error cargando patrones',
                style: tt.titleMedium?.copyWith(color: cs.error),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(patternsForGoalProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternListTile(PatternModel pattern) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.surfaceVariant,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Set selected pattern and duration
          ref.read(selectedPatternProvider.notifier).state = pattern;
          ref.read(selectedDurationProvider.notifier).state =
              pattern.recommendedMinutes;

          // Close the sheet
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Pattern icon
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPatternIcon(pattern.name),
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Pattern info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.name,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (pattern.description != null)
                      Text(
                        pattern.description!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPatternIcon(String patternName) {
    final name = patternName.toLowerCase();

    if (name.contains('box')) {
      return Icons.check_box_outline_blank;
    } else if (name.contains('energi') || name.contains('energ')) {
      return Icons.bolt;
    } else if (name.contains('equilibrio') || name.contains('ground')) {
      return Icons.balance;
    } else if (name.contains('calma') || name.contains('calm')) {
      return Icons.spa;
    } else {
      return Icons.air;
    }
  }
}

void showGoalPatternSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return const GoalPatternSheet();
      },
    ),
  );
}
