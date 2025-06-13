import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/widgets/custom_sliver_app_bar.dart';
import 'package:panic_button_flutter/providers/journey_provider.dart';
import 'package:panic_button_flutter/models/journey_level.dart';

import 'package:panic_button_flutter/widgets/delayed_loading_animation.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  int? expandedLevelId;
  bool _isRequirementsExpanded = false;
  // Map to store pattern names locally
  final Map<String, String> _patternNames = {};

  // Map level IDs to themed icons
  final Map<int, IconData> _levelIcons = {
    1: Icons.eco, // Beginner level - first growth
    2: Icons.air_rounded, // Basic breathing - gentle air
    3: Icons.waves_rounded, // Steady breathing waves
    4: Icons.favorite_outline, // Heart and health focus
    5: Icons.self_improvement, // Meditation and mindfulness
    6: Icons.lightbulb_outline, // Mental clarity and insight
    7: Icons.park_rounded, // Nature connection - forest immersion
    8: Icons.water_drop, // Flow state - fluid like water
    9: Icons.palette, // Emotional balance and expression
    10: Icons.flight_takeoff, // Transcendence and breakthrough
    11: Icons.electric_bolt, // Chispa Controlada - spark/electricity control
    12: Icons.insights, // Balance Supremo - harmony and equilibrium
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          provider_pkg.Provider.of<JourneyProvider>(context, listen: false);
      provider.init();
    });
  }

  void _toggleExpandLevel(int id) {
    setState(() {
      expandedLevelId = expandedLevelId == id ? null : id;
    });
  }

  void _startExercise(JourneyLevel level) {
    if (level.patternSlugs.isNotEmpty) {
      // Use Go Router for navigation to ensure the URL path is updated correctly
      // Explicitly set autoStart to false
      context.go('/breath/${level.patternSlugs.first}');
    }
  }

  void _navigateToBoltScreen() {
    context.go('/bolt');
  }

  // Load pattern name and cache it
  Future<String> _getPatternName(String slug, JourneyProvider provider) async {
    if (_patternNames.containsKey(slug)) {
      return _patternNames[slug]!;
    }

    final name = await provider.getPatternName(slug);
    setState(() {
      _patternNames[slug] = name;
    });
    return name;
  }

  // Helper method to get medal icon based on level
  IconData _getMedalIcon(int levelId) {
    // Use the same icon as in the level indicator for consistency
    return _levelIcons[levelId] ?? Icons.emoji_events;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: provider_pkg.Consumer<JourneyProvider>(
                builder: (context, journeyProvider, child) {
                  if (journeyProvider.isLoading) {
                    return const SafeArea(
                      child: DelayedLoadingAnimation(
                        loadingText: 'Cargando tu camino...',
                        showQuote: true,
                        delayMilliseconds: 500,
                      ),
                    );
                  }

                  if (journeyProvider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${journeyProvider.errorMessage}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => journeyProvider.init(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final allLevels = journeyProvider.allLevels;

                  // Preload all pattern names for a smoother UI
                  for (final level in allLevels) {
                    if (level.patternSlugs.isNotEmpty) {
                      _getPatternName(
                          level.patternSlugs.first, journeyProvider);
                    }
                  }

                  return CustomScrollView(
                    slivers: [
                      const CustomSliverAppBar(
                        showBackButton: false,
                        showSettings: true,
                      ),
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: 80 + bottomPadding,
                          left: 16.0,
                          right: 16.0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 32),
                            Text(
                              'Camino a la Calma',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontSize: 32,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Desbloquea nuevas técnicas de respiración y toma el control remoto de tu sistema nervioso',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: const Color(0xFFB0B0B0),
                                  ),
                            ),
                            const SizedBox(height: 32),
                            _buildProgressSection(context, journeyProvider),
                            const SizedBox(height: 32),
                            _buildJourneyPath(
                                context, allLevels, journeyProvider),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const CustomNavBar(
            currentIndex: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, JourneyProvider provider) {
    final currentLevel = provider.currentLevel;
    final nextLevel = provider.nextLevel;

    if (currentLevel == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF336699)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current level with medal
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00B383),
                  border: Border.all(
                    color: const Color(0xFF00B383),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B383).withAlpha(192),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _getMedalIcon(currentLevel.id),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nivel Actual ${currentLevel.id}: ${currentLevel.nameEs}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          LinearProgressIndicator(
            value: provider.progressPercent,
            backgroundColor: const Color(0xFF243649),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B383)),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 16),

          if (nextLevel != null) ...{
            Text(
              'Próximo nivel: ${nextLevel.nameEs}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFB0B0B0),
                  ),
            ),
            const SizedBox(height: 16),

            // Collapsible requirements section
            GestureDetector(
              onTap: () {
                setState(() {
                  _isRequirementsExpanded = !_isRequirementsExpanded;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF243649),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFF336699).withAlpha(128)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estado de tu progreso',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Icon(
                      _isRequirementsExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF336699),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Expandable requirements content
            if (_isRequirementsExpanded) ...[
              const SizedBox(height: 12),
              _buildRequirementItem(
                context,
                'BOLT mayor a',
                provider.averageBolt.toStringAsFixed(1),
                nextLevel.boltMin.toString(),
                provider.averageBolt / nextLevel.boltMin,
                isBolt: true,
              ),
              const SizedBox(height: 16),
              _buildRequirementItem(
                context,
                'Minutos acumulados',
                provider.cumulativeMinutes.toString(),
                (nextLevel.id * nextLevel.minutesWeek).toString(),
                provider.cumulativeMinutes /
                    (nextLevel.id * nextLevel.minutesWeek),
                isBolt: false,
              ),
              const SizedBox(height: 12),
              // Add exercise completion requirement if next level exists
              if (nextLevel.id > 1)
                FutureBuilder<double>(
                  future: provider.getMinutesCompletedForExercise(
                      currentLevel.patternSlugs.first),
                  builder: (context, snapshot) {
                    final completedMinutes = snapshot.data ?? 0.0;
                    return _buildRequirementItem(
                      context,
                      'Ejercicio nivel ${currentLevel.id}',
                      completedMinutes.toStringAsFixed(1),
                      '3.0',
                      completedMinutes / 3.0,
                      isBolt: false,
                    );
                  },
                ),
            ],
          } else ...{
            Text(
              '¡Felicidades! Has alcanzado el nivel máximo.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF00B383),
                  ),
            ),
          },
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context,
    String title,
    String current,
    String target,
    double progress, {
    required bool isBolt,
  }) {
    String unit = isBolt ? 's' : 'min';
    bool noBoltMeasurements = isBolt && (current == '0.0' || current == '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row for the title and value
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - title with optional info icon
            Flexible(
              flex: 2,
              child: isBolt
                  ? GestureDetector(
                      onTap: _navigateToBoltScreen,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'BOLT promedio 7 días: $target$unit',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Este valor es el promedio de tus mediciones BOLT de los últimos 7 días.',
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF336699),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      '$title: $target$unit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),

            // Right side - current value
            Flexible(
              flex: 1,
              child: isBolt && noBoltMeasurements
                  ? Text(
                      'Medir BOLT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB0B0B0),
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      '$current/$target$unit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFB0B0B0),
                          ),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),

        // Small vertical spacing
        const SizedBox(height: 4),

        // Progress bar below
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: const Color(0xFF243649),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF336699)),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildJourneyPath(
    BuildContext context,
    List<JourneyLevel> levels,
    JourneyProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveles de Respiración',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...List.generate(levels.length, (index) {
          final level = levels[index];
          final isLastLevel = index == levels.length - 1;
          final isExpanded = expandedLevelId == level.id;
          final isUnlocked = provider.isLevelUnlocked(level.id);

          return Column(
            children: [
              _buildJourneyLevel(
                context,
                level,
                isExpanded,
                isUnlocked,
                provider,
              ),
              if (!isLastLevel)
                _buildConnector(
                    provider.isLevelUnlocked(level.id + 1), level.id),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildConnector(bool isUnlocked, int levelId) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: 30,
      width: 2,
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00B383),
                  Color(0xFF336699),
                ],
              )
            : null,
        color: isUnlocked ? null : const Color(0xFF444444),
      ),
    );
  }

  Widget _buildJourneyLevel(
    BuildContext context,
    JourneyLevel level,
    bool isExpanded,
    bool isUnlocked,
    JourneyProvider provider,
  ) {
    final Color backgroundColor = isUnlocked
        ? (level.id == provider.currentLevel?.id
            ? const Color(0xFF1A392A)
            : const Color(0xFF1A2A3C))
        : const Color(0xFF1A1F2C);

    final Color borderColor = isUnlocked
        ? (level.id == provider.currentLevel?.id
            ? const Color(0xFF00B383)
            : const Color(0xFF336699))
        : const Color(0xFF444444);

    String patternName = 'Cargando...';
    if (level.patternSlugs.isNotEmpty) {
      final slug = level.patternSlugs.first;
      if (_patternNames.containsKey(slug)) {
        patternName = _patternNames[slug]!;
      } else {
        // Trigger loading
        _getPatternName(slug, provider);
      }
    }

    return GestureDetector(
      onTap: isUnlocked ? () => _toggleExpandLevel(level.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: borderColor.withAlpha(192),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildLevelIndicator(level.id, isUnlocked),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${level.id}. ${level.nameEs}",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isUnlocked
                                      ? Colors.white
                                      : const Color(0xFF777777),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      _buildUnlockRequirements(context, level, provider),
                    ],
                  ),
                ),
                if (isUnlocked)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFFB0B0B0),
                  ),
              ],
            ),
            if (isExpanded && isUnlocked) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF444444)),
              const SizedBox(height: 16),
              if (level.patternSlugs.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22463A),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFF00B383), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF00B383),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ejercicio desbloqueado:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        patternName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF00B383),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      // Benefits text moved inside the container
                      Text(
                        'Beneficios:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.benefitEs,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFB0B0B0),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () => _startExercise(level),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B383),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Iniciar Ejercicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockRequirements(
      BuildContext context, JourneyLevel level, JourneyProvider provider) {
    return GestureDetector(
      onTap: () => _showRequirementsPopup(context, level, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              'Ver requisitos',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: provider.isLevelUnlocked(level.id)
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 14,
              color: provider.isLevelUnlocked(level.id)
                  ? const Color(0xFF336699)
                  : const Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(int levelId, bool isUnlocked) {
    // Use the icon from the map, or a default trophy icon if not found
    final IconData icon = _levelIcons[levelId] ?? Icons.emoji_events;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked ? const Color(0xFF00B383) : const Color(0xFF444444),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF00B383) : const Color(0xFF444444),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: const Color(0xFF00B383).withAlpha(192),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          color: isUnlocked ? Colors.white : const Color(0xFF777777),
          size: 20,
        ),
      ),
    );
  }

  // Show requirements popup modal
  void _showRequirementsPopup(
      BuildContext context, JourneyLevel level, JourneyProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF336699), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(128),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Requisitos para Nivel ${level.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Level name
                Text(
                  level.nameEs,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF00B383),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),

                // Requirements list
                _buildRequirementRow(
                  context,
                  Icons.bolt,
                  'BOLT Score',
                  'Mayor a ${level.boltMin}s',
                  provider.averageBolt >= level.boltMin,
                  'Actual: ${provider.averageBolt.toStringAsFixed(1)}s',
                ),
                const SizedBox(height: 12),

                _buildRequirementRow(
                  context,
                  Icons.timer,
                  'Minutos Acumulados',
                  '${level.id * level.minutesWeek} minutos',
                  provider.cumulativeMinutes >= (level.id * level.minutesWeek),
                  'Actual: ${provider.cumulativeMinutes} min',
                ),
                const SizedBox(height: 12),

                // Exercise completion requirement for levels > 1
                if (level.id > 1)
                  FutureBuilder<double>(
                    future: provider.getMinutesCompletedForExercise(provider
                        .allLevels
                        .firstWhere((l) => l.id == level.id - 1)
                        .patternSlugs
                        .first),
                    builder: (context, snapshot) {
                      final completedMinutes = snapshot.data ?? 0.0;
                      return _buildRequirementRow(
                        context,
                        Icons.fitness_center,
                        'Ejercicio Nivel ${level.id - 1}',
                        'Completar 3+ minutos',
                        completedMinutes >= 3.0,
                        'Actual: ${completedMinutes.toStringAsFixed(1)} min',
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    if (!provider.isLevelUnlocked(level.id)) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _navigateToBoltScreen,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF336699),
                            side: const BorderSide(color: Color(0xFF336699)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Medir BOLT'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B383),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to build requirement rows in the popup
  Widget _buildRequirementRow(
    BuildContext context,
    IconData icon,
    String title,
    String requirement,
    bool isCompleted,
    String currentValue,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF1A392A) : const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isCompleted ? const Color(0xFF00B383) : const Color(0xFF666666),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                isCompleted ? const Color(0xFF00B383) : const Color(0xFF666666),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  requirement,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB0B0B0),
                      ),
                ),
                Text(
                  currentValue,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCompleted
                            ? const Color(0xFF00B383)
                            : const Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color:
                isCompleted ? const Color(0xFF00B383) : const Color(0xFF666666),
            size: 20,
          ),
        ],
      ),
    );
  }
}
