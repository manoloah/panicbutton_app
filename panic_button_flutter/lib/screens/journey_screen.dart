import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/providers/journey_provider.dart';
import 'package:panic_button_flutter/models/journey_level.dart';
import 'package:panic_button_flutter/screens/breath_screen.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  int? expandedLevelId;
  // Map to store pattern names locally
  final Map<String, String> _patternNames = {};

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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: provider_pkg.Consumer<JourneyProvider>(
                builder: (context, journeyProvider, child) {
                  if (journeyProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
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

                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: 80 + bottomPadding),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 32),
                              Text(
                                'Camino Respiratorio',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: 32,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Desbloquea nuevas técnicas y mejora tu respiración día a día',
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
                            ],
                          ),
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

    String patternName = 'Cargando...';
    if (currentLevel.patternSlugs.isNotEmpty) {
      final slug = currentLevel.patternSlugs.first;
      if (_patternNames.containsKey(slug)) {
        patternName = _patternNames[slug]!;
      } else {
        // Trigger loading
        _getPatternName(slug, provider);
      }
    }

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
          Text(
            'Nivel Actual ${currentLevel.id}: ${currentLevel.nameEs}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ejercicio: $patternName',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            _buildRequirementItem(
              context,
              'BOLT mayor a',
              provider.averageBolt.toStringAsFixed(1),
              nextLevel.boltMin.toString(),
              provider.averageBolt / nextLevel.boltMin,
              isBolt: true,
            ),
            const SizedBox(height: 8),
            _buildRequirementItem(
              context,
              'Respirar más de',
              provider.weeklyMinutes.toString(),
              nextLevel.minutesWeek.toString(),
              provider.weeklyMinutes / nextLevel.minutesWeek,
              isBolt: false,
            ),
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
    String unit = isBolt ? 's' : 'min/semana';
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '$title: $target$unit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
        Expanded(
          flex: 4,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFF243649),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF336699)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$target$unit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB0B0B0),
              ),
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
                    color: borderColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
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
                      Text(
                        _getUnlockRequirementsText(level, provider),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isUnlocked
                                  ? const Color(0xFFB0B0B0)
                                  : const Color(0xFF666666),
                            ),
                      ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                level.benefitEs,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB0B0B0),
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 16),
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

  String _getUnlockRequirementsText(
      JourneyLevel level, JourneyProvider provider) {
    final List<String> requirements = [];
    requirements.add('BOLT mayor a: ${level.boltMin}s');
    requirements.add('Respirar más de ${level.minutesWeek} min/semana');
    return 'Requisitos para desbloquear nivel: ${requirements.join(' | ')}';
  }

  Widget _buildLevelIndicator(int levelId, bool isUnlocked) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked ? const Color(0xFF00B383) : const Color(0xFF444444),
        border: Border.all(
          color: isUnlocked ? const Color(0xFF00B383) : const Color(0xFF444444),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          levelId.toString(),
          style: TextStyle(
            color: isUnlocked ? Colors.white : const Color(0xFF777777),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
