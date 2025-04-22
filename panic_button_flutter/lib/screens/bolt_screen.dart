// lib/screens/bolt_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

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

class _BoltScreenState extends State<BoltScreen> {
  bool _isMeasuring = false;
  bool _isComplete = false;
  bool _isLoading = false;
  int _seconds = 0;
  Timer? _timer;
  List<BoltScore> _scores = [];

  /// Currently selected aggregation mode:
  Aggregation _aggregation = Aggregation.day;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  void _resetMeasurement() {
    setState(() {
      _isComplete = false;
      _seconds = 0;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final periodScores = _periodScores;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Title & description
              Text(
                'Mide tu probabilidad de tener un ataque de pánico',
                style: tt.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'La prueba BOLT (Body Oxygen Level Test) mide tu tolerancia al CO2. '
                'Es un gran indicador tu nivel de ansiedad y tu capacidad para manejar el estrés.',
                style: tt.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Measurement UI
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      _isMeasuring
                          ? '$_seconds segundos'
                          : _isComplete
                              ? 'Tu puntuación: $_seconds segundos'
                              : 'Presiona para empezar',
                      style: tt.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_isComplete) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                              onPressed: _resetMeasurement,
                              child: const Text('Reintentar')),
                          ElevatedButton(
                              onPressed: _saveMeasurement,
                              child: const Text('Guardar')),
                        ],
                      )
                    ] else ...[
                      ElevatedButton(
                        onPressed:
                            _isMeasuring ? _stopMeasurement : _startMeasurement,
                        child: Text(_isMeasuring ? 'DETENER' : 'EMPEZAR'),
                      ),
                    ],
                  ],
                ),
              ),
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
            ],
          ),
        ),
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
