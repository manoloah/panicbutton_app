// lib/screens/bolt_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/breath_circle.dart';
import '../widgets/wave_animation.dart';
import '../widgets/score_chart.dart' show ScoreChart, ScorePeriod;
import '../constants/images.dart';
import '../widgets/delayed_loading_animation.dart';

/// How we bucket your raw BOLT scores:
enum Aggregation { day, week, month, quarter, year }

/// A period + its average score:
class BoltPeriodScore {
  final DateTime period;
  final double averageScore;
  BoltPeriodScore({required this.period, required this.averageScore});
}

class BoltScreen extends StatefulWidget {
  const BoltScreen({super.key});
  @override
  State<BoltScreen> createState() => _BoltScreenState();
}

class _BoltScreenState extends State<BoltScreen>
    with SingleTickerProviderStateMixin {
  bool _isMeasuring = false;
  bool _isComplete = false;
  bool _isLoading = false;
  bool _isShowingInstructions = false;
  int _seconds = 0;
  Timer? _timer;
  List<BoltScore> _scores = [];
  int _instructionStep = 0;
  double _instructionCountdownDouble =
      0; // Store as double for smooth animation
  late AnimationController _breathAnimationController;
  // No need for scroll controller and key with new approach

  /// Currently selected aggregation mode:
  Aggregation _aggregation = Aggregation.day;

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
          .from('bolt_scores')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true)
          .limit(1000);
      _scores = (response as List).map((s) => BoltScore.fromJson(s)).toList();
    } catch (_) {
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
    // Simply show the instructions overlay - no scrolling needed
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
              _instructionCountdownDouble = 5; // Changed from 4 to 5 seconds
              _breathAnimationController.reset();
              _breathAnimationController.forward(
                from: 0.0,
              );
              break;
            case 2: // Exhale instruction
              _instructionCountdownDouble = 5; // Changed from 4 to 5 seconds
              _breathAnimationController.reset();
              _breathAnimationController.forward(
                from: 0.0,
              );
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
    debugPrint("_advanceToNextInstruction called");
    setState(() {
      _instructionStep = 1; // Explicitly set to step 1 (inhale)
      _instructionCountdownDouble = 5; // Changed from 4 to 5 seconds
      _breathAnimationController.reset();
      _breathAnimationController.forward(
        from: 0.0,
      );
      // Now start the timer for automatic progression through remaining steps
      _startInstructionTimer();
    });
    debugPrint("Advanced to step: $_instructionStep");
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
      await Supabase.instance.client.from('bolt_scores').insert({
        'score_seconds': _seconds,
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

  // Added a new method to fully restart the BOLT measurement flow
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

  /// Convert raw [_scores] into averaged scores by [_aggregation].
  List<BoltPeriodScore> get _periodScores {
    if (_scores.isEmpty) return [];
    final Map<DateTime, List<BoltScore>> buckets = {};
    for (final s in _scores) {
      late DateTime key;
      switch (_aggregation) {
        case Aggregation.day:
          key = DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day);
          break;
        case Aggregation.week:
          final mon =
              s.createdAt.subtract(Duration(days: s.createdAt.weekday - 1));
          key = DateTime(mon.year, mon.month, mon.day);
          break;
        case Aggregation.month:
          key = DateTime(s.createdAt.year, s.createdAt.month);
          break;
        case Aggregation.quarter:
          final q = ((s.createdAt.month - 1) ~/ 3) + 1;
          final monthStart = (q - 1) * 3 + 1;
          key = DateTime(s.createdAt.year, monthStart);
          break;
        case Aggregation.year:
          key = DateTime(s.createdAt.year);
          break;
      }
      buckets.putIfAbsent(key, () => []).add(s);
    }
    final list = buckets.entries.map((e) {
      final avg = e.value.map((s) => s.scoreSeconds).reduce((a, b) => a + b) /
          e.value.length;
      return BoltPeriodScore(period: e.key, averageScore: avg);
    }).toList()
      ..sort((a, b) => a.period.compareTo(b.period));
    return list;
  }

  String _aggLabel(Aggregation a) {
    switch (a) {
      case Aggregation.day:
        return 'Día';
      case Aggregation.week:
        return 'Semana';
      case Aggregation.month:
        return 'Mes';
      case Aggregation.quarter:
        return 'Trimestre';
      case Aggregation.year:
        return 'Año';
    }
  }

  String _formatBottom(DateTime dt) {
    switch (_aggregation) {
      case Aggregation.day:
        return DateFormat('dd/MMM').format(dt);
      case Aggregation.week:
        // dt is already the Monday of the week — just format it as a date
        return DateFormat('MMM-dd').format(dt);
      case Aggregation.month:
        return DateFormat('MMM-yy').format(dt);
      case Aggregation.quarter:
        final q = ((dt.month - 1) ~/ 3) + 1;
        final yy = DateFormat('yy').format(dt);
        return 'Q$q-$yy';
      case Aggregation.year:
        return DateFormat('yyyy').format(dt);
    }
  }

  Widget _buildInstructionsCard() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOLT',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Para mejores resultados, realiza esta medición al despertar por la mañana.',
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
              // Info button
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: cs.primary,
                ),
                onPressed: () {
                  // Show detailed instructions in a dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Instrucciones Detalladas'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildInstructionStep(1,
                                'Respira de forma tranquila por la nariz unas cuantas veces'),
                            _buildInstructionStep(2,
                                'Realiza una inhalación NORMAL durante 5 segundos'),
                            _buildInstructionStep(3,
                                'Realiza una exhalación NORMAL durante 5 segundos'),
                            _buildInstructionStep(
                                4, 'Pincha tu nariz o retén la respiración'),
                            _buildInstructionStep(5, 'Inicia el cronómetro'),
                            _buildInstructionStep(6,
                                'Espera hasta sentir la PRIMERA necesidad de respirar o falta de aire'),
                            _buildInstructionStep(
                                7, 'Detén el cronometro en ese momento'),
                            _buildInstructionStep(8,
                                'Regresa a respirar como empezaste de forma normal, lenta y controlada'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Compact instruction steps - just show core steps with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Step 1-3: Breathe
              _buildCompactStep(
                cs,
                Icons.air_rounded,
                'Respira\nNormal',
              ),

              // Arrow
              Icon(Icons.arrow_forward, color: cs.onSurface.withAlpha(128)),

              // Step 4: Hold breath - using pinch nose image
              _buildCompactStepWithImage(
                cs,
                Images.pinchNose,
                'Retén\nrespiración',
              ),

              // Arrow
              Icon(Icons.arrow_forward, color: cs.onSurface.withAlpha(128)),

              // Step 5-7: Measure time specifically
              _buildCompactStep(
                cs,
                Icons.timer,
                'Mide\nTiempo',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Start button
          ElevatedButton(
            onPressed: _startMeasurement,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 4,
              shadowColor: cs.shadow.withAlpha(102),
              side: BorderSide(
                color: cs.primary.withAlpha(102),
                width: 1.5,
              ),
              minimumSize:
                  const Size(double.infinity, 48), // Make button full width
            ),
            child: const Text('COMENZAR'),
          ),
        ],
      ),
    );
  }

  // New helper method for compact step display
  Widget _buildCompactStep(ColorScheme cs, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFFB0B0B0), // _altText from app_theme.dart
          size: 30,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // New helper method for compact step using image instead of icon
  Widget _buildCompactStepWithImage(
      ColorScheme cs, String imagePath, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 30,
          height: 30,
          color: const Color(0xFFB0B0B0), // _altText from app_theme.dart
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // Add back the instruction step method
  Widget _buildInstructionStep(int step, String text) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: tt.bodySmall?.copyWith(color: cs.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium,
            ),
          ),
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
      // SliverAppBar will scroll away
      body: Stack(
        children: [
          // Main content
          SafeArea(
            bottom:
                false, // Don't pad the bottom - we'll handle that separately
            child: CustomScrollView(
              slivers: [
                const CustomSliverAppBar(
                  showBackButton: false,
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
                        'Mide tu nivel de calma',
                        style: tt.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'La prueba BOLT mide tu resistencia al CO2 y refleja tu nivel de calma. A mayor puntaje, menor riesgo de ansiedad o ataques de pánico.',
                        style: tt.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Measurement UI - only show this when not in instructions mode
                      if (!_isShowingInstructions)
                        !_isMeasuring && !_isComplete
                            ? _buildInstructionsCard()
                            : _buildMeasurementUI(),

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
                        Text('Tu progreso', style: tt.headlineMedium),
                        const SizedBox(height: 16),

                        // Two-row layout for aggregation selectors
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Split the aggregation values into two rows
                            final firstRowAggregations = [
                              Aggregation.day,
                              Aggregation.week,
                              Aggregation.month,
                            ];
                            final secondRowAggregations = [
                              Aggregation.quarter,
                              Aggregation.year,
                            ];

                            // Function to build an aggregation button
                            Widget buildAggregationButton(Aggregation a) {
                              final sel = a == _aggregation;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 4),
                                child: InkWell(
                                  onTap: () => setState(() => _aggregation = a),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel ? cs.primary : cs.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      // Add subtle border for non-selected items
                                      border: !sel
                                          ? Border.all(
                                              color:
                                                  cs.onSurface.withAlpha(128),
                                              width: 1,
                                            )
                                          : null,
                                    ),
                                    child: Text(
                                      _aggLabel(a),
                                      style: tt.bodyMedium?.copyWith(
                                        color:
                                            sel ? cs.onPrimary : cs.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              );
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
                                  periodScores: periodScores
                                      .map((p) => ScorePeriod(
                                          period: p.period,
                                          averageScore: p.averageScore))
                                      .toList(),
                                  formatBottomLabel: _formatBottom,
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
          if (_isShowingInstructions) _buildFullScreenInstructionOverlay(),
        ],
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }

  // New method to build a full-screen overlay for instructions
  Widget _buildFullScreenInstructionOverlay() {
    final cs = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withAlpha((0.9 * 255).toInt()), // Dim background
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () =>
                            setState(() => _isShowingInstructions = false),
                      ),
                    ],
                  ),

                  // Instruction animation - takes most of the screen
                  Expanded(
                    child: _buildCompactInstructionAnimation(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // New more compact instruction animation
  Widget _buildCompactInstructionAnimation() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    String phaseText;
    String instructionImage = Images.breathCalm;

    switch (_instructionStep) {
      case 0:
        phaseText = 'Cálmate y respira de forma normal';
        break;
      case 1:
        phaseText = 'Inhala normal';
        break;
      case 2:
        phaseText = 'Exhala normal';
        break;
      case 3:
        phaseText = 'Pincha tu nariz o retén la respiración';
        instructionImage = Images.pinchNose;
        break;
      default:
        phaseText = '';
    }

    // Calculate display countdown - never show less than 1 for inhale/exhale
    int displayCountdown = _instructionCountdown;
    if ((_instructionStep == 1 || _instructionStep == 2) &&
        displayCountdown < 1) {
      displayCountdown = 1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            phaseText,
            style: tt.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Main content
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildInstructionStepContent(
                    cs, tt, instructionImage, displayCountdown),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the content for each instruction step
  Widget _buildInstructionStepContent(ColorScheme cs, TextTheme tt,
      String instructionImage, int displayCountdown) {
    if (_instructionStep == 0) {
      return Column(
        key: const ValueKey('step0'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            instructionImage,
            width: 100,
            height: 100,
            color: cs.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Preparate para hacer una inhalación normal',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _advanceToNextInstruction,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 4,
              shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
              side: BorderSide(
                color: cs.primary.withAlpha((0.4 * 255).toInt()),
                width: 1.5,
              ),
            ),
            child: const Text('SIGUIENTE'),
          ),
        ],
      );
    } else if (_instructionStep == 1 || _instructionStep == 2) {
      return Column(
        key: ValueKey('step${_instructionStep}'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Countdown
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              displayCountdown.toString(),
              style: tt.displayLarge?.copyWith(
                color: cs.primary,
                fontSize: 48,
              ),
            ),
          ),

          // Circle
          BreathCircle(
            isBreathing: true,
            onTap: () {},
            size: 150, // Smaller size
            phaseIndicator: WaveAnimation(
              waveAnimation: _breathAnimationController,
              fillLevel: _instructionStep == 1
                  ? _breathAnimationController.value
                  : 1 - _breathAnimationController.value,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _instructionStep == 1
                ? 'Preparate para exhalar...'
                : 'Preparate para retener...',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (_instructionStep == 3) {
      return Column(
        key: const ValueKey('step3'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            instructionImage,
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 20),
          Text(
            'Cuando estés listo para comenzar la retención, presiona el botón:',
            style: tt.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _instructionStep = 4; // Move to next step
                _isShowingInstructions = false;
                _actuallyStartMeasurement();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 4,
              shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
              side: BorderSide(
                color: cs.primary.withAlpha((0.4 * 255).toInt()),
                width: 1.5,
              ),
            ),
            child: const Text('EMPEZAR MEDICIÓN'),
          ),
        ],
      );
    } else {
      return const SizedBox(); // Fallback
    }
  }

  Widget _buildMeasurementUI() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Get mental state description based on score
    String getMentalStateDescription(int score) {
      if (score <= 10) {
        return 'Vives en un estado constante de alerta, sientes que todo es peligroso aunque no lo sea.';
      } else if (score <= 15) {
        return 'Todavía te sientes en alerta, pero empiezas a darte cuenta de que no todo es una amenaza.';
      } else if (score <= 20) {
        return 'Empiezas a relajarte, pero todavía te sientes un poco nervioso o inquieto.';
      } else if (score <= 30) {
        return 'La mayor parte del tiempo te sientes en calma, pero a veces puedes ponerte nervioso fácilmente.';
      } else if (score <= 40) {
        return 'Te sientes tranquilo, seguro y estable.';
      } else {
        return 'Estás en un estado profundo de calma y control, difícilmente te alteras.';
      }
    }

    // Get color based on score
    Color getMentalStateColor(int score) {
      if (score <= 10) {
        return const Color(0xFF8D7DAF); // Soft purple
      } else if (score <= 15) {
        return const Color(0xFF7A97C9); // Soft blue-purple
      } else if (score <= 20) {
        return const Color(0xFF68B0C1); // Teal-blue
      } else if (score <= 25) {
        return const Color(0xFF5BBFAD); // Mint green
      } else if (score <= 30) {
        return const Color(0xFF52A375); // More green than teal
      } else if (score <= 40) {
        return const Color(0xFF3B7F8C); // Deep teal
      } else {
        return const Color(0xFF4265D6); // Brighter blue for better contrast
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum required space
        children: [
          Text(
            _isMeasuring
                ? 'Detén al primer deseo de respirar'
                : _isComplete
                    ? 'Tu puntuación: $_seconds segundos'
                    : 'Presiona para empezar',
            style: tt.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (_isComplete) ...[
            const SizedBox(height: 8),
            Text(
              'Lo hicistes bien si después de retener lograste respirar normal y de forma controlada como empezaste',
              style: tt.bodySmall,
              textAlign: TextAlign.center,
            ),
            // Mental state description
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getMentalStateColor(_seconds)
                    .withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: getMentalStateColor(_seconds)
                      .withAlpha((0.5 * 255).toInt()),
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
                      color: getMentalStateColor(_seconds),
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
                          getMentalStateDescription(_seconds),
                          style: tt.bodyMedium?.copyWith(
                            color: getMentalStateColor(_seconds),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          Icons.info_outline,
                          color: getMentalStateColor(_seconds),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 24, minHeight: 24),
                        onPressed: () {
                          _showBoltScoreInfoDialog();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_isMeasuring) ...[
            Container(
              constraints:
                  const BoxConstraints(maxHeight: 140), // Constrain height
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum space
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_seconds',
                    style: tt.displayLarge?.copyWith(
                      fontSize: 60, // Reduced from 64
                      height: 0.9, // Tighter line height
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'segundos',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface.withAlpha((0.8 * 255).toInt()),
                      fontSize: 18, // Smaller text
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Reduced from 20
            Padding(
              padding: const EdgeInsets.only(bottom: 8), // Added bottom padding
              child: ElevatedButton(
                onPressed: _stopMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4500), // Error color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  elevation: 4,
                  shadowColor: Colors.red.withAlpha((0.5 * 255).toInt()),
                  side: BorderSide(
                    color: Colors.red.withAlpha((0.4 * 255).toInt()),
                    width: 1.5,
                  ),
                ),
                child: const Text('DETENER'),
              ),
            ),
          ] else if (_isComplete) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _restartMeasurement, // Use new restart method
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.surface,
                    foregroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    elevation: 4,
                    shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                    side: BorderSide(
                      color: cs.primary.withAlpha((0.4 * 255).toInt()),
                      width: 1.5,
                    ),
                  ),
                  child: const Text('Reintentar'),
                ),
                ElevatedButton(
                  onPressed: _saveMeasurement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primaryContainer,
                    foregroundColor: cs.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    elevation: 4,
                    shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                    side: BorderSide(
                      color: cs.primary.withAlpha((0.4 * 255).toInt()),
                      width: 1.5,
                    ),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            )
          ] else ...[
            ElevatedButton(
              onPressed: _startMeasurement,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 4,
                shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                side: BorderSide(
                  color: cs.primary.withAlpha((0.4 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              child: const Text('EMPEZAR'),
            ),
          ],
        ],
      ),
    );
  }

  void _showBoltScoreInfoDialog() {
    final cs = Theme.of(context).colorScheme;
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
              const Divider(height: 1),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Table(
                          columnWidths: const {
                            0: FixedColumnWidth(
                                80), // Fixed width for score range column
                            1: FlexColumnWidth(), // Flexible width for description column
                          },
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            _buildScoreTableRow(
                                cs,
                                tt,
                                '1-10 segs',
                                'Vives en un estado constante de alerta, sientes que todo es peligroso aunque no lo sea.',
                                const Color(0xFF8D7DAF)),
                            _buildScoreTableRow(
                                cs,
                                tt,
                                '11-15 segs',
                                'Todavía te sientes en alerta, pero empiezas a darte cuenta de que no todo es una amenaza.',
                                const Color(0xFF7A97C9)),
                            _buildScoreTableRow(
                                cs,
                                tt,
                                '16-20 segs',
                                'Empiezas a relajarte, pero todavía te sientes un poco nervioso o inquieto.',
                                const Color(0xFF68B0C1)),
                            _buildScoreTableRow(
                                cs,
                                tt,
                                '21-30 segs',
                                'La mayor parte del tiempo te sientes en calma, pero a veces puedes ponerte nervioso fácilmente.',
                                const Color(0xFF52A375)),
                            _buildScoreTableRow(
                                cs,
                                tt,
                                '31-40 segs',
                                'Te sientes tranquilo, seguro y estable.',
                                const Color(0xFF3B7F8C)),
                            _buildScoreTableRow(
                                cs,
                                tt,
                                '40+ segs',
                                'Estás en un estado profundo de calma y control, difícilmente te alteras.',
                                const Color(0xFF4265D6)),
                          ],
                        ),
                        // Add padding at the bottom to ensure the last item is fully visible
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              // Scroll indicator at the bottom
              Container(
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surface.withAlpha((0 * 255).toInt()),
                      cs.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurface.withAlpha((0.6 * 255).toInt()),
                  ),
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method for table rows
  TableRow _buildScoreTableRow(ColorScheme cs, TextTheme tt, String range,
      String description, Color color) {
    return TableRow(
      children: [
        // Score range cell
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: color.withAlpha((0.6 * 255).toInt()), width: 1.5),
            ),
            child: Text(
              range,
              style: tt.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Description cell
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Text(
            description,
            style: tt.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// Raw score record:
class BoltScore {
  final int scoreSeconds;
  final DateTime createdAt;
  BoltScore({required this.scoreSeconds, required this.createdAt});

  factory BoltScore.fromJson(Map<String, dynamic> json) => BoltScore(
        scoreSeconds: json['score_seconds'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
