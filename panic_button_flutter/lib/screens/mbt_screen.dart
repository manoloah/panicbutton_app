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

/// Screen for measuring the MBT (Maximum Breathlessness Test) metric
class MbtScreen extends StatefulWidget {
  const MbtScreen({super.key});

  @override
  State<MbtScreen> createState() => _MbtScreenState();
}

class _MbtScreenState extends State<MbtScreen>
    with SingleTickerProviderStateMixin {
  bool _isComplete = false;
  bool _isLoading = false;
  bool _isShowingInstructions = false;
  int _selectedSteps = 0;
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
      duration: const Duration(seconds: 5), // 5 seconds for breathing phases
    )..addListener(() {
        if (mounted) setState(() {}); // Ensure smooth animation updates
      });
  }

  @override
  void dispose() {
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
          .from(MetricConfigs.mbtConfig.tableName)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(1000);
      _scores = (response as List)
          .map((s) =>
              MetricScore.fromJson(s, MetricConfigs.mbtConfig.scoreFieldName))
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
      _instructionCountdownDouble = 0;
    });
    // Start the instruction flow immediately
    _advanceToNextInstruction();
  }

  void _startInstructionTimer() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      setState(() {
        if (_instructionCountdownDouble > 0) {
          _instructionCountdownDouble =
              math.max(0, _instructionCountdownDouble - 0.1);
        } else {
          // Move to next instruction
          _instructionStep++;

          switch (_instructionStep) {
            case 1: // Inhale instruction
              _instructionCountdownDouble = 5; // 5 seconds as per requirements
              _breathAnimationController.reset();
              _breathAnimationController.forward(from: 0.0);
              break;
            case 2: // Exhale instruction
              _instructionCountdownDouble = 5; // 5 seconds as per requirements
              _breathAnimationController.reset();
              _breathAnimationController.forward(from: 0.0);
              break;
            case 3: // Pinch nose instruction - STOP here and wait for button click
              // Cancel the timer - we'll wait for user to click the button
              timer.cancel();
              break;
            case 4: // Walk counting steps - STOP here and wait for button click
              // Cancel the timer - we'll wait for user to click the button
              timer.cancel();
              break;
            case 5: // This case should only be reached via button click now
              _isShowingInstructions = false;
              _showStepSelection();
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
      _instructionCountdownDouble = 5; // 5 seconds for inhale
      _breathAnimationController.reset();
      _breathAnimationController.duration =
          const Duration(seconds: 5); // Set proper duration
      _breathAnimationController.forward(from: 0.0);
      // Now start the timer for automatic progression through remaining steps
      _startInstructionTimer();
    });
  }

  // Method to manually advance from step 3 to step 4
  void _advanceToStep4() {
    setState(() {
      _instructionStep = 4; // Move to step 4 (walk counting steps)
    });
  }

  void _showStepSelection() {
    setState(() {
      _isComplete = true;
      _selectedSteps = 0;
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
          .from(MetricConfigs.mbtConfig.tableName)
          .insert({
        MetricConfigs.mbtConfig.scoreFieldName: _selectedSteps,
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
      _selectedSteps = 0;
      _isShowingInstructions = true;
      _instructionStep = 0;
      _instructionCountdownDouble = 0;
    });
    // Start the instruction flow immediately
    _advanceToNextInstruction();
  }

  // Shows the score info dialog
  void _showScoreInfoDialog() {
    MetricScoreInfoDialog.show(context, MetricConfigs.mbtConfig);
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

  Widget _buildMbtMeasurementUI() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (!_isComplete) {
      return MetricInstructionsCard(
        metricConfig: MetricConfigs.mbtConfig,
        onStart: _startMeasurement,
      );
    }

    // Get state color and description from the metric config
    final stateColor = MetricConfigs.mbtConfig.getScoreColor(_selectedSteps);
    final stateDescription =
        MetricConfigs.mbtConfig.getScoreDescription(_selectedSteps);

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
            'Selecciona el número de pasos realizados',
            style: tt.titleLarge, // Smaller title
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16), // Reduced spacing

          // Steps display - more compact
          Container(
            padding: const EdgeInsets.all(12), // Reduced padding
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha((0.3 * 255).toInt()),
              borderRadius: BorderRadius.circular(12), // Smaller radius
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_selectedSteps',
                  style: tt.displayMedium?.copyWith(
                    // Smaller font
                    fontSize: 36, // Reduced from 48
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'pasos',
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface.withAlpha((0.8 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16), // Reduced spacing

          // Enhanced slider with better visibility - more compact
          Column(
            children: [
              // Slider with enhanced styling
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withAlpha((0.5 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outline.withAlpha((0.3 * 255).toInt()),
                    width: 1,
                  ),
                ),
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: cs.primary,
                    inactiveTrackColor:
                        cs.onSurface.withAlpha((0.2 * 255).toInt()),
                    thumbColor: cs.primary,
                    overlayColor: cs.primary.withAlpha((0.2 * 255).toInt()),
                    valueIndicatorColor: cs.primary,
                    valueIndicatorTextStyle: TextStyle(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                      elevation: 4,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                  ),
                  child: Slider(
                    value: _selectedSteps.toDouble(),
                    min: 0,
                    max: 200,
                    divisions: 200,
                    label: '$_selectedSteps pasos',
                    onChanged: (value) {
                      setState(() {
                        _selectedSteps = value.round();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 6), // Reduced spacing

              // Range labels with icons - more compact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 pasos',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                  ),
                  Text(
                    'Desliza para seleccionar',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha((0.7 * 255).toInt()),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    '200 pasos',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16), // Reduced spacing

          // Action buttons - 2 column grid layout for better visibility
          Row(
            children: [
              // Secondary action button - left column
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

              // Primary action button - right column
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedSteps > 0 ? _saveMeasurement : null,
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

          if (_selectedSteps > 0) ...[
            const SizedBox(height: 16), // Reduced spacing

            // Score description - moved below buttons
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
        ],
      ),
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
                        'Tu nivel de estrés en movimiento a largo plazo',
                        style: tt.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        MetricConfigs.mbtConfig.description,
                        style: tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Measurement UI - only show this when not in instructions mode
                      if (!_isShowingInstructions) _buildMbtMeasurementUI(),

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
                        Text(MetricConfigs.mbtConfig.chartTitle,
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
                                              .withOpacity(0.5),
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
                                // First row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: firstRowAggregations
                                      .map(buildAggregationButton)
                                      .toList(),
                                ),
                                // Second row
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
                        // Remove fixed height to allow chart to size itself properly
                        ScoreChart(
                          periodScores: periodScores,
                          formatBottomLabel: _formatBottom,
                          metricConfig: MetricConfigs.mbtConfig,
                          maxY: 200, // Max steps for MBT
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
                          'Realiza tu primera prueba MBT para ver tu progreso',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withAlpha((0.7 * 255).toInt()),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      // Dynamic bottom padding for navbar
                      SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 100),
                    ]),
                  ),
                ),
              ],
            ),

            // Instruction overlay
            if (_isShowingInstructions)
              MetricInstructionOverlay(
                instructionStep: _instructionStep,
                instructions: MetricConfigs.mbtConfig.detailedInstructions,
                instructionCountdown: _instructionCountdown,
                onClose: () => setState(() => _isShowingInstructions = false),
                onNext: () {
                  if (_instructionStep == 0) {
                    _advanceToNextInstruction();
                  } else if (_instructionStep == 3) {
                    _advanceToStep4();
                  }
                },
                onStartMeasurement: () {
                  setState(() {
                    _instructionStep = 5;
                    _isShowingInstructions = false;
                    _showStepSelection();
                  });
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
