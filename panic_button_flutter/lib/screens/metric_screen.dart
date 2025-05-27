import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/custom_nav_bar.dart';
import '../widgets/custom_sliver_app_bar.dart';

import '../widgets/score_chart.dart';
import '../widgets/delayed_loading_animation.dart';
import '../widgets/metric_instructions_card.dart';
import '../widgets/metric_measurement_ui.dart';
import '../widgets/metric_instruction_overlay.dart';
import '../widgets/metric_score_info_dialog.dart';

import '../models/metric_config.dart';
import '../models/metric_score.dart';
import '../theme/app_theme.dart'; // Add this import

/// A generic screen for measuring various metrics
class MetricScreen extends StatefulWidget {
  /// The metric configuration to use
  final MetricConfig metricConfig;

  /// The index to use for the custom nav bar
  final int navbarIndex;

  const MetricScreen({
    super.key,
    required this.metricConfig,
    required this.navbarIndex,
  });

  @override
  State<MetricScreen> createState() => _MetricScreenState();
}

class _MetricScreenState extends State<MetricScreen>
    with SingleTickerProviderStateMixin {
  // Measurement state
  bool _isMeasuring = false;
  bool _isComplete = false;
  bool _isLoading = false;
  bool _isShowingInstructions = false;
  int _seconds = 0;
  Timer? _timer;
  List<MetricScore> _scores = [];

  // Instruction state
  int _instructionStep = 0;
  double _instructionCountdownDouble = 0;
  late AnimationController _breathAnimationController;

  // Selected aggregation mode
  MetricAggregation _aggregation = MetricAggregation.week;

  // Helper to get integer countdown
  int get _instructionCountdown => _instructionCountdownDouble.ceil();

  @override
  void initState() {
    super.initState();
    _loadScores();
    _breathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        if (mounted) setState(() {}); // Ensure smooth animation updates
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadScores() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.go('/auth');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from(widget.metricConfig.tableName)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(1000);
      _scores = (response as List)
          .map((s) =>
              MetricScore.fromJson(s, widget.metricConfig.scoreFieldName))
          .toList();
    } catch (e) {
      _showSnackError('Error al cargar las puntuaciones');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          // For inhale/exhale steps, stop at 1 second
          if ((_instructionStep == 1 || _instructionStep == 2) &&
              _instructionCountdownDouble <= 1.0 + 0.1) {
            // Adding small buffer for float comparison
            // Move to next step when reaching 1
            _instructionCountdownDouble = 0;
          } else {
            _instructionCountdownDouble =
                math.max(0, _instructionCountdownDouble - 0.1);
          }
        } else {
          // Move to next instruction
          _instructionStep++;

          switch (_instructionStep) {
            case 1: // Inhale instruction
              _instructionCountdownDouble = 5;
              _breathAnimationController.reset();
              _breathAnimationController.forward(from: 0.0);
              break;
            case 2: // Exhale instruction
              _instructionCountdownDouble = 5;
              _breathAnimationController.reset();
              _breathAnimationController.forward(from: 0.0);
              break;
            case 3: // Pinch nose instruction - STOP here and wait for button click
              // Cancel the timer - we'll wait for user to click the button
              timer.cancel();
              break;
            case 4: // This case should only be reached via button click now
              _isShowingInstructions = false;
              _actuallyStartMeasurement();
              timer.cancel();
              break;
          }
        }
      });
    });
  }

  // Method to advance to the next instruction manually
  void _advanceToNextInstruction() {
    setState(() {
      _instructionStep = 1; // Explicitly set to step 1 (inhale)
      _instructionCountdownDouble = 5;
      _breathAnimationController.reset();
      _breathAnimationController.forward(from: 0.0);
      // Now start the timer for automatic progression through remaining steps
      _startInstructionTimer();
    });
  }

  void _actuallyStartMeasurement() {
    setState(() {
      _isMeasuring = true;
      _isComplete = false;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _stopMeasurement() {
    _timer?.cancel();
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
    } catch (e) {
      _showSnackError('Error al guardar la puntuación');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Added a new method to fully restart the measurement flow
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

  // Shows the score info dialog
  void _showScoreInfoDialog() {
    MetricScoreInfoDialog.show(context, widget.metricConfig);
  }

  /// Convert raw [_scores] into averaged scores by [_aggregation].
  List<MetricPeriodScore> get _periodScores {
    if (_scores.isEmpty) return [];
    final Map<DateTime, List<MetricScore>> buckets = {};
    for (final s in _scores) {
      late DateTime key;
      switch (_aggregation) {
        case MetricAggregation.day:
          key = DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day);
          break;
        case MetricAggregation.week:
          final mon =
              s.createdAt.subtract(Duration(days: s.createdAt.weekday - 1));
          key = DateTime(mon.year, mon.month, mon.day);
          break;
        case MetricAggregation.month:
          key = DateTime(s.createdAt.year, s.createdAt.month);
          break;
        case MetricAggregation.quarter:
          final q = ((s.createdAt.month - 1) ~/ 3) + 1;
          final monthStart = (q - 1) * 3 + 1;
          key = DateTime(s.createdAt.year, monthStart);
          break;
        case MetricAggregation.year:
          key = DateTime(s.createdAt.year);
          break;
      }
      buckets.putIfAbsent(key, () => []).add(s);
    }
    final list = buckets.entries.map((e) {
      final avg = e.value.map((s) => s.scoreValue).reduce((a, b) => a + b) /
          e.value.length;
      return MetricPeriodScore(period: e.key, averageScore: avg);
    }).toList()
      ..sort((a, b) => a.period.compareTo(b.period));
    return list;
  }

  String _formatBottom(DateTime dt) {
    switch (_aggregation) {
      case MetricAggregation.day:
        return DateFormat('dd/MMM').format(dt);
      case MetricAggregation.week:
        // dt is already the Monday of the week — just format it as a date
        return DateFormat('MMM-dd').format(dt);
      case MetricAggregation.month:
        return DateFormat('MMM-yy').format(dt);
      case MetricAggregation.quarter:
        final q = ((dt.month - 1) ~/ 3) + 1;
        final yy = DateFormat('yy').format(dt);
        return 'Q$q-$yy';
      case MetricAggregation.year:
        return DateFormat('yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final periodScores = _periodScores;

    return Scaffold(
      // Main content
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
                  backRoute: '/measurements',
                  showSettings: true,
                ),

                // Everything that used to be in your old Column
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
                      // Title & description
                      Text(
                        'Tu nivel de estrés en resposo a corto plazo',
                        style: tt.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.metricConfig.description,
                        style: tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Measurement UI - only show this when not in instructions mode
                      if (!_isShowingInstructions)
                        !_isMeasuring && !_isComplete
                            ? MetricInstructionsCard(
                                metricConfig: widget.metricConfig,
                                onStart: _startMeasurement,
                              )
                            : MetricMeasurementUI(
                                metricConfig: widget.metricConfig,
                                isMeasuring: _isMeasuring,
                                isComplete: _isComplete,
                                seconds: _seconds,
                                onStart: _startMeasurement,
                                onStop: _stopMeasurement,
                                onRestart: _restartMeasurement,
                                onSave: _saveMeasurement,
                                onShowInfoDialog: _showScoreInfoDialog,
                              ),

                      const SizedBox(height: 30),

                      // Chart or loader
                      if (_isLoading)
                        SizedBox(
                            height: 200,
                            child: DelayedLoadingAnimation(
                              loadingText: 'Cargando datos...',
                              showQuote: false,
                              delayMilliseconds: 300,
                            ))
                      else if (periodScores.isNotEmpty) ...[
                        Text(widget.metricConfig.chartTitle,
                            style: tt.headlineMedium),
                        const SizedBox(height: 16),

                        // Two-row layout for aggregation selectors
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Split the aggregation values into two rows
                            final firstRowAggregations = [
                              MetricAggregation.day,
                              MetricAggregation.week,
                              MetricAggregation.month,
                            ];
                            final secondRowAggregations = [
                              MetricAggregation.quarter,
                              MetricAggregation.year,
                            ];

                            // Function to build an aggregation button
                            Widget buildAggregationButton(MetricAggregation a) {
                              final sel = a == _aggregation;
                              final tt = Theme.of(context).textTheme;

                              if (sel) {
                                // Selected: OutlinedButton, compact style
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 4),
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        setState(() => _aggregation = a),
                                    style: Theme.of(context)
                                        .outlinedButtonTheme
                                        .style
                                        ?.copyWith(
                                          minimumSize:
                                              const WidgetStatePropertyAll(
                                                  Size(0, 0)), // compact!
                                          padding: const WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 8),
                                          ),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      20), // match chips!
                                            ),
                                          ),
                                        ),
                                    child: Text(
                                      a.label,
                                      style: tt.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              } else {
                                // Unselected: ghost style, still compact
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 4),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _aggregation = a),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        a.label,
                                        style: tt.bodyMedium?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }

                            return Column(
                              children: [
                                // First row - Day, Week, Month
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: firstRowAggregations
                                      .map(buildAggregationButton)
                                      .toList(),
                                ),

                                // Small space between rows
                                const SizedBox(height: 4),

                                // Second row - Quarter, Year
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: secondRowAggregations
                                      .map(buildAggregationButton)
                                      .toList(),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Responsive chart with proper constraints for mobile
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.width < 400
                                ? 300
                                : 250,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: periodScores.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay datos suficientes para mostrar una gráfica',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ScoreChart(
                                  periodScores: periodScores,
                                  formatBottomLabel: _formatBottom,
                                  metricConfig: widget.metricConfig,
                                ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // Full-screen overlay for instruction steps
          if (_isShowingInstructions)
            MetricInstructionOverlay(
              instructionStep: _instructionStep,
              instructions: widget.metricConfig.detailedInstructions,
              instructionCountdown: _instructionCountdown,
              onClose: () => setState(() => _isShowingInstructions = false),
              onNext: _advanceToNextInstruction,
              onStartMeasurement: () {
                setState(() {
                  _instructionStep = 4;
                  _isShowingInstructions = false;
                  _actuallyStartMeasurement();
                });
              },
              breathAnimation: _breathAnimationController,
            ),
        ],
      ),
      bottomNavigationBar: CustomNavBar(currentIndex: widget.navbarIndex),
    );
  }
}
