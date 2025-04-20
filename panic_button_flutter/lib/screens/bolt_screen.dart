import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
      debugPrint('Error loading BOLT scores: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las puntuaciones'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _isComplete = false;
      _seconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
      debugPrint('Error saving BOLT score: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la puntuación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFF132737),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Mide Tu BOLT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'La prueba BOLT (Body Oxygen Level Test) mide tu tolerancia al CO2. Una mayor puntuación indica mejor salud respiratoria.',
                style: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_isComplete) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _resetMeasurement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Reintentar'),
                          ),
                          ElevatedButton(
                            onPressed: _saveMeasurement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00B383),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: _isMeasuring ? _stopMeasurement : _startMeasurement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMeasuring 
                              ? Colors.red 
                              : const Color(0xFF00B383),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _isMeasuring ? 'DETENER' : 'EMPEZAR',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_scores.isNotEmpty) ...[
                const Text(
                  'Tu progreso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Color(0xFFB0B0B0),
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= _scores.length) return const Text('');
                              final date = _scores[value.toInt()].createdAt;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('MM/dd').format(date),
                                  style: const TextStyle(
                                    color: Color(0xFFB0B0B0),
                                    fontSize: 12,
                                  ),
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
                          spots: _scores.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.scoreSeconds.toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF00B383),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF00B383).withOpacity(0.1),
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