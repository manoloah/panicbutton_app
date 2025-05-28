// lib/screens/bolt_screen.dart

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
import '../widgets/metric_instruction_overlay.dart';
import '../widgets/metric_score_info_dialog.dart';
import '../constants/metric_configs.dart';
import '../models/metric_score.dart';

/// Screen for measuring the BOLT (Body Oxygen Level Test) metric
class BoltScreen extends StatefulWidget {
  const BoltScreen({super.key});

  @override
  State<BoltScreen> createState() => _BoltScreenState();
}

class _BoltScreenState extends State<BoltScreen>
    with SingleTickerProviderStateMixin {
  // Measurement state
  bool _isMeasuring = false;
  bool _isComplete = false;
  bool _isLoading = false;
  bool _isShowingInstructions = false;
  int _seconds = 0;
  Timer? _timer;
  List<MetricScore> _scores = [];

  // Instruction state - isolated for BOLT
  int _instructionStep = 0;
  double _instructionCountdownDouble = 0;
  late AnimationController _breathAnimationController;

  // Selected aggregation mode
  MetricAggregation _aggregation = MetricAggregation.week;

  // Unique key for this screen's overlay to prevent widget reuse
  static const String _overlayKey = 'bolt_overlay';

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
        if (mounted) setState(() {});
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
          .from(MetricConfigs.boltConfig.tableName)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(1000);
      _scores = (response as List)
          .map((s) =>
              MetricScore.fromJson(s, MetricConfigs.boltConfig.scoreFieldName))
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
      _instructionStep = 1;
      _instructionCountdownDouble = 0;
    });
    // Reset animations when starting
    _breathAnimationController.reset();
  }

  void _startInstructionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      setState(() {
        if (_instructionCountdownDouble > 0) {
          _instructionCountdownDouble =
              math.max(0, _instructionCountdownDouble - 0.1);
        } else {
          // Check if current step should move automatically
          final currentInstruction = _instructionStep > 0 &&
                  _instructionStep <=
                      MetricConfigs.boltConfig.enhancedInstructions.length
              ? MetricConfigs
                  .boltConfig.enhancedInstructions[_instructionStep - 1]
              : null;

          if (currentInstruction?.movesToNextStepAutomatically == true) {
            // Move to next instruction automatically
            _instructionStep++;

            if (_instructionStep <=
                MetricConfigs.boltConfig.enhancedInstructions.length) {
              final nextInstruction = MetricConfigs
                  .boltConfig.enhancedInstructions[_instructionStep - 1];
              if (nextInstruction.isTimedStep) {
                _instructionCountdownDouble =
                    nextInstruction.durationSeconds?.toDouble() ?? 5.0;
                _breathAnimationController.reset();
                _breathAnimationController.forward(from: 0.0);
              } else {
                // Non-timed step, stop timer and wait for user action
                timer.cancel();
              }
            } else {
              // All instructions completed, start measurement
              _isShowingInstructions = false;
              _actuallyStartMeasurement();
              timer.cancel();
            }
          } else {
            // Manual step, stop timer and wait for user action
            timer.cancel();
          }
        }
      });
    });
  }

  void _advanceToNextInstruction() {
    if (_instructionStep == 1) {
      setState(() {
        _instructionStep = 2;
        _instructionCountdownDouble = 5;
        _breathAnimationController.reset();
        _breathAnimationController.forward(from: 0.0);
      });
      _startInstructionTimer();
    } else if (_instructionStep == 4) {
      // Move from pinch nose to start measurement
      setState(() {
        _isShowingInstructions = false;
      });
      _actuallyStartMeasurement();
    }
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
          .from(MetricConfigs.boltConfig.tableName)
          .insert({
        MetricConfigs.boltConfig.scoreFieldName: _seconds,
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

  void _restartMeasurement() {
    setState(() {
      _isMeasuring = false;
      _isComplete = false;
      _seconds = 0;
    });
  }

  // Shows the score info dialog
  void _showScoreInfoDialog() {
    MetricScoreInfoDialog.show(context, MetricConfigs.boltConfig);
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

  Widget _buildBoltMeasurementUI() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isMeasuring) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cronómetro BOLT',
              style: tt.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$_seconds',
              style: tt.displayLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'segundos',
              style: tt.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopMeasurement,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              child: const Text('DETENER'),
            ),
          ],
        ),
      );
    }

    if (_isComplete) {
      final stateColor = MetricConfigs.boltConfig.getScoreColor(_seconds);
      final stateDescription =
          MetricConfigs.boltConfig.getScoreDescription(_seconds);

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu puntuación BOLT',
              style: tt.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: stateColor.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$_seconds',
                    style: tt.displayMedium?.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'segundos',
                    style: tt.titleMedium?.copyWith(color: stateColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _restartMeasurement,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'VUELVE A MEDIR',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveMeasurement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                    ),
                    child: Text(
                      'GUARDAR RESULTADO',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Score description section - matching MBT design
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: stateColor.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: stateColor.withAlpha((0.5 * 255).toInt()),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '¿Qué significa tu score?',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: stateColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          stateDescription,
                          style: tt.bodyMedium?.copyWith(
                            color: stateColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: stateColor,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: _showScoreInfoDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return MetricInstructionsCard(
      metricConfig: MetricConfigs.boltConfig,
      onStart: _startMeasurement,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final periodScores = _periodScores;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                CustomSliverAppBar(
                  showBackButton: true,
                  backRoute: '/measurements',
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Title & description
                      Text(
                        'Tu nivel de calma en reposo',
                        style: tt.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        MetricConfigs.boltConfig.description,
                        style: tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Measurement UI - only show when not in instructions mode
                      if (!_isShowingInstructions) _buildBoltMeasurementUI(),

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
                        Text(MetricConfigs.boltConfig.chartTitle,
                            style: tt.headlineMedium),
                        const SizedBox(height: 16),

                        // Aggregation selectors
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final firstRowAggregations = [
                              MetricAggregation.day,
                              MetricAggregation.week,
                              MetricAggregation.month,
                            ];
                            final secondRowAggregations = [
                              MetricAggregation.quarter,
                              MetricAggregation.year,
                            ];

                            Widget buildAggregationButton(MetricAggregation a) {
                              final sel = a == _aggregation;
                              final tt = Theme.of(context).textTheme;

                              if (sel) {
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
                                                  Size(0, 0)),
                                          padding: const WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 8),
                                          ),
                                          shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: firstRowAggregations
                                      .map(buildAggregationButton)
                                      .toList(),
                                ),
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
                        ScoreChart(
                          periodScores: periodScores,
                          formatBottomLabel: _formatBottom,
                          metricConfig: MetricConfigs.boltConfig,
                          //maxY: 100,
                          minY: 0,
                        ),
                      ] else ...[
                        const SizedBox(height: 40),
                        Text(
                          'Aún no tienes mediciones',
                          style: tt.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Realiza tu primera prueba BOLT para ver tu progreso',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withAlpha((0.7 * 255).toInt()),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 100),
                    ]),
                  ),
                ),
              ],
            ),

            // Enhanced instruction overlay with unique key
            if (_isShowingInstructions)
              MetricInstructionOverlay(
                key: const ValueKey(_overlayKey),
                overlayKey: _overlayKey,
                instructionStep: _instructionStep,
                instructions: MetricConfigs.boltConfig.enhancedInstructions,
                instructionCountdown: _instructionCountdown,
                onClose: () => setState(() => _isShowingInstructions = false),
                onNext: _advanceToNextInstruction,
                onStartMeasurement: () {
                  setState(() {
                    _isShowingInstructions = false;
                  });
                  _actuallyStartMeasurement();
                },
                breathAnimation: _breathAnimationController,
              ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }
}
