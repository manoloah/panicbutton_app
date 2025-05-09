// lib/screens/bolt_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_nav_bar.dart';
import '../widgets/breath_circle.dart';
import '../widgets/wave_animation.dart';
import '../widgets/bolt_chart.dart' as bolt_chart;
import '../constants/images.dart';
import 'package:animations/animations.dart';

/// How we bucket your raw BOLT scores:
enum Aggregation { day, week, month, quarter, year }

/// A period + its average score:
class PeriodScore {
  final DateTime period;
  final double averageScore;
  PeriodScore({required this.period, required this.averageScore});
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
    print("_advanceToNextInstruction called");
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
    print("Advanced to step: $_instructionStep");
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

  /// Convert raw [_scores] into averaged [PeriodScore]s by [_aggregation].
  List<PeriodScore> get _periodScores {
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
      return PeriodScore(period: e.key, averageScore: avg);
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
              Icon(Icons.arrow_forward, color: cs.onSurface.withOpacity(0.5)),

              // Step 4: Hold breath - using pinch nose image
              _buildCompactStepWithImage(
                cs,
                Images.pinchNose,
                'Retén\nrespiración',
              ),

              // Arrow
              Icon(Icons.arrow_forward, color: cs.onSurface.withOpacity(0.5)),

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
              shadowColor: cs.shadow.withOpacity(0.5),
              side: BorderSide(
                color: cs.primary.withOpacity(0.4),
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
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: cs.primary,
              size: 24,
            ),
          ),
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
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              imagePath,
              width: 30,
              height: 30,
              color: cs.primary,
            ),
          ),
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
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFF132737),
                foregroundColor: cs.onBackground,
                elevation: 0,
                // Makes it disappear when you scroll up
                pinned: false, // not fixed
                floating: true, // re-appears on quick swipe-down
                snap: true,
                // Kill the "scroll-under" tint/elevation
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.go('/settings'),
                  ),
                ],
              ),

              // Everything that used to be in your old Column
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      const Center(child: CircularProgressIndicator())
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
                                                cs.onSurface.withOpacity(0.1),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: Text(
                                    _aggLabel(a),
                                    style: tt.bodyMedium?.copyWith(
                                      color: sel ? cs.onPrimary : cs.onSurface,
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
                            : bolt_chart.BoltChart(
                                periodScores: periodScores
                                    .map((p) => bolt_chart.PeriodScore(
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
        color: Colors.black.withOpacity(0.9), // Dim background
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
              shadowColor: cs.shadow.withOpacity(0.5),
              side: BorderSide(
                color: cs.primary.withOpacity(0.4),
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
              color: cs.primary.withOpacity(0.2),
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
              shadowColor: cs.shadow.withOpacity(0.5),
              side: BorderSide(
                color: cs.primary.withOpacity(0.4),
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
        return 'Pánico Constante: Vives en un estado constante de alerta, sientes que todo es peligroso aunque no lo sea.';
      } else if (score <= 15) {
        return 'Ansioso/Inestable: Todavía te sientes en alerta, pero empiezas a darte cuenta de que no todo es una amenaza.';
      } else if (score <= 20) {
        return 'Inquieto/Irregular: Empiezas a relajarte, pero todavía te sientes un poco nervioso o inquieto.';
      } else if (score <= 25) {
        return 'Calma Parcial: La mayor parte del tiempo te sientes en calma, pero a veces puedes ponerte nervioso fácilmente.';
      } else if (score <= 30) {
        return 'Tranquilo/Estable: Te sientes tranquilo, seguro y estable.';
      } else if (score <= 35) {
        return 'Zen/Inmune: Estás en un estado profundo de calma y control, difícilmente te alteras.';
      } else {
        return 'Suprema Calma: Has alcanzado un nivel excepcional de calma y resiliencia mental.';
      }
    }

    // Get color based on score
    Color getMentalStateColor(int score) {
      if (score <= 10) {
        return Colors.redAccent.shade200;
      } else if (score <= 15) {
        return Colors.orange;
      } else if (score <= 20) {
        return Colors.amber;
      } else if (score <= 25) {
        return Colors.lightGreen;
      } else if (score <= 30) {
        return Colors.teal.shade300;
      } else if (score <= 35) {
        return Colors.blue.shade300;
      } else {
        return Colors.indigo.shade300;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
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
                color: getMentalStateColor(_seconds).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: getMentalStateColor(_seconds).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                getMentalStateDescription(_seconds),
                style: tt.bodyMedium?.copyWith(
                  color: getMentalStateColor(_seconds).withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_isMeasuring) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_seconds',
                  style: tt.displayLarge?.copyWith(
                    fontSize: 64,
                    height: 1.0, // Tighter line height
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'segundos',
                  style: tt.headlineSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
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
                shadowColor: Colors.red.withOpacity(0.5),
                side: BorderSide(
                  color: Colors.red.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: const Text('DETENER'),
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
                    shadowColor: cs.shadow.withOpacity(0.5),
                    side: BorderSide(
                      color: cs.primary.withOpacity(0.4),
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
                    shadowColor: cs.shadow.withOpacity(0.5),
                    side: BorderSide(
                      color: cs.primary.withOpacity(0.4),
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
                shadowColor: cs.shadow.withOpacity(0.5),
                side: BorderSide(
                  color: cs.primary.withOpacity(0.4),
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
