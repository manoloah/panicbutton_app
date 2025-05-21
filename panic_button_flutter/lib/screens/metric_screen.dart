import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/metric_config.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/score_chart.dart';
import '../widgets/delayed_loading_animation.dart';
import '../widgets/metric_instruction_card.dart';
import '../widgets/metric_measurement_ui.dart';
import '../widgets/metric_instruction_overlay.dart';
import '../widgets/metric_switcher.dart';

/// How we bucket raw metric scores:
enum Aggregation { day, week, month, quarter, year }

/// Generic screen for measuring any metric type
class MetricScreen extends StatefulWidget {
  /// The metric configuration to use for this screen
  final MetricConfig metricConfig;

  /// The initial aggregation period to use for charts
  final Aggregation initialAggregation;

  const MetricScreen({
    super.key,
    required this.metricConfig,
    this.initialAggregation = Aggregation.week,
  });

  @override
  State<MetricScreen> createState() => _MetricScreenState();
}

class _MetricScreenState extends State<MetricScreen>
    with SingleTickerProviderStateMixin {
  // UI state
  bool _isLoading = true;
  bool _isMeasuring = false;
  bool _isComplete = false;
  bool _isShowingInstructions = false;
  int _instructionStep = 0;
  double _instructionCountdownDouble = 0;
  int _seconds = 0;

  // Data state
  List<MetricScore> _scores = [];
  List<MetricPeriodScore> _periodScores = [];
  Aggregation _aggregation = Aggregation.week;

  // Timers
  Timer? _timer;
  Timer? _measureTimer;
  late AnimationController _breathAnimationController;

  @override
  void initState() {
    super.initState();
    _aggregation = widget.initialAggregation;
    _breathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _loadScores();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _measureTimer?.cancel();
    _breathAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Get user ID from Supabase
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Redirect to auth screen if user is not logged in
        context.go('/auth');
        return;
      }

      // Fetch scores for the current user from the appropriate table
      final response = await Supabase.instance.client
          .from(widget.metricConfig.tableName)
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      // Convert JSON to MetricScore objects using the configured score field name
      setState(() {
        _scores = response
            .map((json) =>
                MetricScore.fromJson(json, widget.metricConfig.scoreFieldName))
            .toList();

        // Generate period scores based on the selected aggregation
        _periodScores = _generatePeriodScores(_aggregation);
        _isLoading = false;
      });
    } catch (e) {
      _showSnackError('Error al cargar datos: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackError(String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: cs.onError)),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startMeasurement() {
    // Simply show the instructions overlay
    setState(() {
      _isShowingInstructions = true;
      _instructionStep = 0;
    });
  }

  void _startInstructionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      setState(() {
        if (_instructionCountdownDouble > 0) {
          // Reduce the countdown timer
          _instructionCountdownDouble =
              math.max(0, _instructionCountdownDouble - 0.1);

          // When countdown reaches zero, handle the end of step
          if (_instructionCountdownDouble <= 0) {
            // Move to next instruction
            _instructionStep++;

            // Process next step
            final currentSteps = widget.metricConfig.instructionSteps;
            if (_instructionStep < currentSteps.length) {
              final step = currentSteps[_instructionStep];

              // If this step has a duration, set the countdown
              if (step.duration != null) {
                _instructionCountdownDouble =
                    step.duration!.inSeconds.toDouble();

                // For breath visualization, start animation controller
                if (step.requiresBreathVisualization) {
                  // Reset and start breath animation
                  _breathAnimationController.reset();
                  _breathAnimationController.forward();
                }
              }
            } else {
              // All instruction steps completed, start actual measurement
              _startActualMeasurement();
            }
          }
        }
      });
    });

    // Set initial countdown for first step
    if (_instructionStep < widget.metricConfig.instructionSteps.length) {
      final step = widget.metricConfig.instructionSteps[_instructionStep];
      if (step.duration != null) {
        _instructionCountdownDouble = step.duration!.inSeconds.toDouble();

        // Start breath animation for the first step if needed
        if (step.requiresBreathVisualization) {
          _breathAnimationController.reset();
          _breathAnimationController.forward();
        }
      }
    }
  }

  void _manualAdvanceInstruction() {
    setState(() {
      // Move to next instruction immediately
      _instructionStep++;

      // Process next step
      if (_instructionStep < widget.metricConfig.instructionSteps.length) {
        final step = widget.metricConfig.instructionSteps[_instructionStep];

        // If this step has a duration, set the countdown and start timer
        if (step.duration != null) {
          _instructionCountdownDouble = step.duration!.inSeconds.toDouble();
          _startInstructionTimer();

          // For breath visualization, start animation controller
          if (step.requiresBreathVisualization) {
            // Reset and start breath animation
            _breathAnimationController.reset();
            _breathAnimationController.forward();
          }
        }
      } else {
        // All instruction steps completed, start actual measurement
        _startActualMeasurement();
      }
    });
  }

  void _startActualMeasurement() {
    _timer?.cancel();

    setState(() {
      _isShowingInstructions = false;
      _isMeasuring = true;
      _seconds = 0;
    });

    // Start the measurement timer
    _measureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _seconds++;
      });
    });
  }

  void _stopMeasurement() {
    _measureTimer?.cancel();
    setState(() {
      _isMeasuring = false;
      _isComplete = true;
    });
  }

  Future<void> _saveMeasurement() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/auth');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from(widget.metricConfig.tableName)
          .insert({
        widget.metricConfig.scoreFieldName: _seconds,
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadScores();
      setState(() => _isComplete = false);
    } catch (_) {
      _showSnackError('Error al guardar la puntuación');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _restartMeasurement() {
    setState(() {
      _isComplete = false;
      _seconds = 0;
      _isShowingInstructions = true;
      _instructionStep = 0;
      _instructionCountdownDouble = 0;
      _timer?.cancel();
    });
  }

  List<MetricPeriodScore> _generatePeriodScores(Aggregation aggregation) {
    if (_scores.isEmpty) return [];

    // Identify periods based on aggregation
    final Map<DateTime, List<int>> scoresByPeriod = {};

    for (final score in _scores) {
      final date = score.createdAt;
      final period = _getPeriodStart(date, aggregation);

      if (!scoresByPeriod.containsKey(period)) {
        scoresByPeriod[period] = [];
      }

      scoresByPeriod[period]!.add(score.scoreValue);
    }

    // Calculate average for each period
    final List<MetricPeriodScore> result = [];

    for (final period in scoresByPeriod.keys) {
      final scores = scoresByPeriod[period]!;
      final average = scores.reduce((a, b) => a + b) / scores.length;

      result.add(MetricPeriodScore(
        period: period,
        averageScore: average,
      ));
    }

    // Sort by date
    result.sort((a, b) => a.period.compareTo(b.period));

    return result;
  }

  DateTime _getPeriodStart(DateTime date, Aggregation aggregation) {
    switch (aggregation) {
      case Aggregation.day:
        return DateTime(date.year, date.month, date.day);
      case Aggregation.week:
        // Find start of week (Monday)
        final daysToSubtract = (date.weekday - 1) % 7;
        return DateTime(date.year, date.month, date.day - daysToSubtract);
      case Aggregation.month:
        return DateTime(date.year, date.month, 1);
      case Aggregation.quarter:
        final quarter = ((date.month - 1) ~/ 3);
        return DateTime(date.year, quarter * 3 + 1, 1);
      case Aggregation.year:
        return DateTime(date.year, 1, 1);
    }
  }

  String _formatPeriodLabel(DateTime date, Aggregation aggregation) {
    switch (aggregation) {
      case Aggregation.day:
        return DateFormat('dd/MM').format(date);
      case Aggregation.week:
        // Format as "10-16 Jul"
        final endOfWeek = date.add(const Duration(days: 6));
        final startFormat = date.month == endOfWeek.month
            ? DateFormat('dd')
            : DateFormat('dd/MM');
        final endFormat = DateFormat('dd/MM');
        return '${startFormat.format(date)}-${endFormat.format(endOfWeek)}';
      case Aggregation.month:
        return DateFormat('MMM').format(date);
      case Aggregation.quarter:
        final quarter = ((date.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${date.year}';
      case Aggregation.year:
        return date.year.toString();
    }
  }

  String _getAggregationTitle(Aggregation aggregation) {
    switch (aggregation) {
      case Aggregation.day:
        return 'Días';
      case Aggregation.week:
        return 'Semanas';
      case Aggregation.month:
        return 'Meses';
      case Aggregation.quarter:
        return 'Trimestres';
      case Aggregation.year:
        return 'Años';
    }
  }

  void _changeAggregation(Aggregation newAggregation) {
    setState(() {
      _aggregation = newAggregation;
      _periodScores = _generatePeriodScores(newAggregation);
    });
  }

  void _showScoreInfoDialog() {
    final tt = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.9,
            maxHeight: screenSize.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom title bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '¿Qué significa tu score?',
                        style: tt.headlineSmall?.copyWith(
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(height: 1),

              // Scrollable content
              Flexible(
                child: Scrollbar(
                  controller: scrollController,
                  thickness: 8,
                  radius: const Radius.circular(4),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          widget.metricConfig.longDescription,
                          style: tt.bodyMedium,
                        ),
                      ),

                      // Zone explanations
                      ...widget.metricConfig.scoreZones.map((zone) {
                        // Handle infinite max value
                        final label = zone.maxValue == double.infinity
                            ? '>${widget.metricConfig.scoreZones[widget.metricConfig.scoreZones.length - 2].maxValue.toInt()}'
                            : zone.maxValue ==
                                    widget
                                        .metricConfig.scoreZones.first.maxValue
                                ? '<${zone.maxValue.toInt()}'
                                : '${widget.metricConfig.scoreZones[widget.metricConfig.scoreZones.indexOf(zone) - 1].maxValue.toInt()}-${zone.maxValue.toInt()}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                margin:
                                    const EdgeInsets.only(top: 4, right: 12),
                                decoration: BoxDecoration(
                                  color: zone.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$label - ${zone.label.split(' - ').last}',
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      zone.description,
                                      style: tt.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstructionsDialog() {
    final tt = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;
    final scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.9,
            maxHeight: screenSize.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom title bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Cómo hacer la medición',
                        style: tt.headlineSmall?.copyWith(
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(height: 1),

              // Scrollable content with instructions
              Flexible(
                child: Scrollbar(
                  controller: scrollController,
                  thickness: 8,
                  radius: const Radius.circular(4),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Detailed instructions from the metric config
                      ...widget.metricConfig.buildDetailedInstructions(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final periodScores = _periodScores;

    // Convert to ScorePeriod for the chart
    final chartData = periodScores
        .map((p) => ScorePeriod(
              period: p.period,
              averageScore: p.averageScore,
            ))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom:
                false, // Don't pad the bottom - we'll handle that separately
            child: CustomScrollView(
              slivers: [
                const CustomSliverAppBar(
                  showBackButton: true,
                  showSettings: true,
                ),

                // Content with padding
                SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom:
                        90, // Add extra bottom padding to avoid navbar overlap
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Metric switcher
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MetricSwitcher(
                          currentMetric: widget.metricConfig,
                        ),
                      ),

                      // Title & description
                      Text(
                        widget.metricConfig.screenTitle,
                        style: tt.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.metricConfig.metricDescription,
                        style: tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Measurement UI - only show this when not in instructions mode
                      if (!_isShowingInstructions)
                        !_isMeasuring && !_isComplete
                            ? MetricInstructionCard(
                                metricConfig: widget.metricConfig,
                                onStart: _startMeasurement,
                                onInfoPressed: _showInstructionsDialog,
                              )
                            : MetricMeasurementUI(
                                metricConfig: widget.metricConfig,
                                score: _seconds,
                                isMeasuring: _isMeasuring,
                                isComplete: _isComplete,
                                isLoading: _isLoading,
                                onStop: _stopMeasurement,
                                onRestart: _restartMeasurement,
                                onSave: _saveMeasurement,
                                onInfoPressed: _showScoreInfoDialog,
                              ),

                      const SizedBox(height: 30),

                      // Chart or loader
                      if (_isLoading) ...[
                        const DelayedLoadingAnimation(),
                      ] else if (periodScores.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color:
                                cs.surfaceVariant.withAlpha(77), // ~0.3 opacity
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Todavía no hay datos',
                                style: tt.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Completa una medición para ver tu progreso.',
                                style: tt.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Chart title with aggregation buttons
                        Container(
                          decoration: BoxDecoration(
                            color:
                                cs.surfaceVariant.withAlpha(77), // ~0.3 opacity
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            border: Border.all(
                              color: cs.outlineVariant,
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tu progreso',
                                style: tt.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildAggregationButton(
                                        Aggregation.day, 'Días'),
                                    _buildAggregationButton(
                                        Aggregation.week, 'Semanas'),
                                    _buildAggregationButton(
                                        Aggregation.month, 'Meses'),
                                    _buildAggregationButton(
                                        Aggregation.quarter, 'Trimestres'),
                                    _buildAggregationButton(
                                        Aggregation.year, 'Años'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // The chart itself (Container with dark background to match theme)
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(20),
                            ),
                            border: Border.all(
                              color: cs.outlineVariant,
                              width: 1,
                            ),
                          ),
                          child: ScoreChart(
                            periodScores: chartData,
                            scoreZones: widget.metricConfig.scoreZones,
                            formatBottomLabel: (date) =>
                                _formatPeriodLabel(date, _aggregation),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Instruction overlay when active
          if (_isShowingInstructions)
            MetricInstructionOverlay(
              metricConfig: widget.metricConfig,
              instructionStep: _instructionStep,
              countdownValue: _instructionCountdownDouble,
              onClose: () => setState(() => _isShowingInstructions = false),
              onManualAdvance: _manualAdvanceInstruction,
            ),
        ],
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }

  Widget _buildAggregationButton(Aggregation aggregation, String label) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _aggregation == aggregation;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => _changeAggregation(aggregation),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? cs.primary
              : cs.surfaceVariant.withAlpha((0.5 * 255).toInt()),
          foregroundColor: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
          elevation: isSelected ? 4 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
