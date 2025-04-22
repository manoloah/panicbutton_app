// lib/screens/bolt_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

class BoltScreen extends StatefulWidget {
  const BoltScreen({super.key});

  @override
  State<BoltScreen> createState() => _BoltScreenState();
}

class _BoltScreenState extends State<BoltScreen> {
  bool _isMeasuring = false;
  bool _isComplete = false;
  int _seconds = 0;
  bool _isLoading = false;
  List<BoltScore> _scores = [];
  Timer? _timer;

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
          .limit(10);
      setState(() {
        _scores = (response as List)
            .map((score) => BoltScore.fromJson(score))
            .toList();
      });
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
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      // uses theme.scaffoldBackgroundColor
      appBar: AppBar(
        // uses theme.appBarTheme.backgroundColor
        elevation: 0,
        title: Text(
          'Mide tu probabilidad de tener un ataque de pánico',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'La prueba BOLT (Body Oxygen Level Test) mide tu tolerancia al CO2. Es un gran indicador tu nivel de ansiedad y tu capacidad para manejar el estrés.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 30),

              // Measurement container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Timer / result text
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

                    // Buttons
                    if (_isComplete) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Retry as outlined
                          OutlinedButton(
                            onPressed: _resetMeasurement,
                            child: const Text('Reintentar'),
                          ),
                          // Save as primary
                          ElevatedButton(
                            onPressed: _saveMeasurement,
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Start / Stop as primary
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

              // Progress chart or loader
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_scores.isNotEmpty) ...[
                Text('Tu progreso', style: tt.headlineMedium),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
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
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) {
                              return Text(
                                value.toInt().toString(),
                                style: tt.bodyMedium,
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              if (value.toInt() >= _scores.length)
                                return const Text('');
                              final date = _scores[value.toInt()].createdAt;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MM/dd').format(date),
                                  style: tt.bodyMedium,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _scores.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(),
                                e.value.scoreSeconds.toDouble());
                          }).toList(),
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
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }
}

class BoltScore {
  final int scoreSeconds;
  final DateTime createdAt;

  BoltScore({required this.scoreSeconds, required this.createdAt});

  factory BoltScore.fromJson(Map<String, dynamic> json) {
    return BoltScore(
      scoreSeconds: json['score_seconds'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
