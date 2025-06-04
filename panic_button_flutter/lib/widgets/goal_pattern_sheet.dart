import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/models/breath_models.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';
import 'package:panic_button_flutter/widgets/delayed_loading_animation.dart';

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
                color: cs.onSurface.withAlpha(20),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Selecciona tu respiración',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),

          // Goals Grid
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
                            color: cs.onSurface.withAlpha(40),
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
                return _buildGoalGrid(goalsList, selectedGoalSlug);
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 150,
                    child: DelayedLoadingAnimation(
                      loadingText: 'Cargando metas...',
                      showQuote: false,
                      delayMilliseconds: 300,
                    ),
                  ),
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
                color: cs.onSurface.withAlpha(80),
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

  Widget _buildGoalGrid(List<GoalModel> goals, String selectedGoalSlug) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Sort goals in the specified order: Calma, Equilibrio, Enfoque, Energia
    final sortedGoals = _sortGoalsByPreferredOrder(goals);

    // Calculate the number of columns based on screen width
    // Smaller screens might need 2 columns, larger can have 2
    final int columnCount = 2;
    final double chipWidth = (screenWidth - 60) / columnCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: sortedGoals.map((goal) {
          final isSelected = goal.slug == selectedGoalSlug;

          return SizedBox(
            width: chipWidth,
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
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurface,
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

  List<GoalModel> _sortGoalsByPreferredOrder(List<GoalModel> goals) {
    // The preferred order is: Calma, Equilibrio, Enfoque, Energia
    final preferredOrder = ['calming', 'grounding', 'focusing', 'energizing'];

    // Create a copy to avoid modifying the original list
    final sortedGoals = [...goals];

    // Sort based on the preferred order
    sortedGoals.sort((a, b) {
      final indexA = preferredOrder.indexOf(a.slug);
      final indexB = preferredOrder.indexOf(b.slug);

      // If both slugs are found in preferred order, sort by that order
      if (indexA >= 0 && indexB >= 0) {
        return indexA.compareTo(indexB);
      }

      // If only one slug is found, prioritize it
      if (indexA >= 0) return -1;
      if (indexB >= 0) return 1;

      // Otherwise, sort alphabetically by display name
      return a.displayName.compareTo(b.displayName);
    });

    return sortedGoals;
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
                    color: cs.onSurface.withAlpha(40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay patrones disponibles para esta meta',
                    textAlign: TextAlign.center,
                    style: tt.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withAlpha(60),
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
          child: SizedBox(
            height: 200,
            child: DelayedLoadingAnimation(
              loadingText: 'Cargando patrones...',
              showQuote: false,
              delayMilliseconds: 300,
            ),
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
      color: cs.surfaceContainerHighest,
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
                  color: cs.primary.withAlpha(20),
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
                          color: cs.onSurface.withAlpha(60),
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: cs.onSurface,
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

Future<void> showGoalPatternSheet(BuildContext context) {
  // Get screen dimensions to calculate explicit heights
  final screenHeight = MediaQuery.of(context).size.height;
  final viewPadding = MediaQuery.of(context).viewPadding;
  final availableHeight = screenHeight - viewPadding.top - viewPadding.bottom;

  // More reliable approach for modal sheets
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    constraints: BoxConstraints(
      // Limit sheet height to ~70% of screen following common UI guidelines
      maxHeight: availableHeight * 0.7,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          // Start slightly over half the screen but allow expansion up to 70%
          height: availableHeight * 0.6,
          child: const GoalPatternSheet(),
        ),
      );
    },
  );
}
