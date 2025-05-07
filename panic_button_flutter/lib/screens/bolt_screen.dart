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
    // Start directly with the instructions and "SIGUIENTE" button
    setState(() {
      _isShowingInstructions = true;
      _instructionStep = 0;
      // Do not start any timers here - wait for user to click "SIGUIENTE"
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
            case 3: // Pinch nose instruction - show longer
              _instructionCountdownDouble = 3; // Unchanged
              break;
            case 4: // Start BOLT measurement
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Instrucciones para medir tu BOLT',
            style: tt.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Para mejores resultados, realiza esta medición al despertar por la mañana.',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Instruction steps
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionStep(1,
                  'Cálmate y respira normal por la nariz durante 10 segundos'),
              _buildInstructionStep(
                  2, 'Realiza una inhalación NORMAL durante 5 segundos'),
              _buildInstructionStep(
                  3, 'Realiza una exhalación NORMAL durante 5 segundos'),
              _buildInstructionStep(
                  4, 'Pincha tu nariz o retén la respiración'),
              _buildInstructionStep(5, 'Inicia el cronómetro'),
              _buildInstructionStep(6,
                  'Espera hasta sentir la PRIMERA necesidad de respirar o falta de aire'),
              _buildInstructionStep(7, 'Detén el cronometro en ese momento'),
              _buildInstructionStep(
                  8, 'Recupera tu respiración normal, lenta y controlada'),
            ],
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startMeasurement,
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 4,
              shadowColor: cs.shadow.withOpacity(0.5),
              side: BorderSide(
                color: cs.primary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Text('COMENZAR'),
          ),
        ],
      ),
    );
  }

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

  Widget _buildInstructionAnimation() {
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

    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: Container(
        key: ValueKey<int>(_instructionStep),
        width: double.infinity,
        height: 480, // Fixed height for all instruction steps
        padding: const EdgeInsets.all(24.0),
        color: cs.surface, // Match parent container color
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              phaseText,
              style: tt.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Main content - same height for all steps
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_instructionStep == 0) ...[
                    Image.asset(
                      instructionImage,
                      width: 120,
                      height: 120,
                      color: cs.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Preparate para hacer una inhalación normal',
                      style: tt.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _advanceToNextInstruction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        elevation: 4,
                        shadowColor: cs.shadow.withOpacity(0.5),
                        side: BorderSide(
                          color: cs.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Text('SIGUIENTE'),
                    ),
                  ] else if (_instructionStep == 1 ||
                      _instructionStep == 2) ...[
                    // Display the countdown above the circle in its own container
                    Container(
                      margin: const EdgeInsets.only(
                          bottom: 16), // Add space between countdown and circle
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
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
                      size: 200,
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
                  ] else if (_instructionStep == 3) ...[
                    Image.asset(
                      instructionImage,
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 30),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 12),
                        elevation: 4,
                        shadowColor: cs.shadow.withOpacity(0.5),
                        side: BorderSide(
                          color: cs.primary.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Text('EMPEZAR RETENCIÓN'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementUI() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
              'Lo hicistes bien si después de retener lograste respirar normal y controlado como empezaste',
              style: tt.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          if (_isMeasuring) ...[
            Text(
              '$_seconds segundos',
              style: tt.displayLarge,
              textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final periodScores = _periodScores;

    // Debug state
    // print(
    //     "Build: _isShowingInstructions=[4m_isShowingInstructions, _isMeasuring=[4m_isMeasuring, _isComplete=[4m_isComplete");

    return Scaffold(
      // SliverAppBar will scroll away
      body: CustomScrollView(
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title & description
                Text(
                  'Mide tu probabilidad de tener un ataque de pánico',
                  style: tt.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'La prueba BOLT (Body Oxygen Level Test) mide tu tolerancia al CO2. '
                  'Es un gran indicador de tu nivel de ansiedad y tu capacidad para manejar el estrés. '
                  'Mientras mayor sea tu score de BOLT, menor será tu probabilidad de tener un ataque de pánico.',
                  style: tt.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Measurement UI
                if (_isShowingInstructions)
                  Material(
                    elevation: 0,
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildInstructionAnimation(),
                    ),
                  )
                else if (!_isMeasuring && !_isComplete)
                  _buildInstructionsCard()
                else
                  _buildMeasurementUI(),

                const SizedBox(height: 30),

                // Chart or loader
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (periodScores.isNotEmpty) ...[
                  Text('Tu progreso', style: tt.headlineMedium),
                  const SizedBox(height: 16),

                  // Aggregation selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: Aggregation.values.map((a) {
                      final sel = a == _aggregation;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _aggregation = a),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? cs.primary : cs.surface,
                              borderRadius: BorderRadius.circular(20),
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
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Responsive chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.7,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 10,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: cs.onSurface.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 10,
                                reservedSize: 40,
                                getTitlesWidget: (v, _) => Text(
                                    v.toInt().toString(),
                                    style: tt.bodyMedium),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize:
                                    30, // plenty of room for rotated labels
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= periodScores.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final label =
                                      _formatBottom(periodScores[i].period);
                                  return Transform.rotate(
                                    angle: -math.pi / 4,
                                    alignment: Alignment.topLeft,
                                    child: Text(label, style: tt.bodyMedium),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: periodScores
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(
                                      e.key.toDouble(), e.value.averageScore))
                                  .toList(),
                              isCurved: true,
                              color: cs.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: cs.primary.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
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
