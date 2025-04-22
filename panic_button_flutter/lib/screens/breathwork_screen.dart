// lib/screens/breathwork_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';

class BreathworkScreen extends StatefulWidget {
  const BreathworkScreen({super.key});

  @override
  State<BreathworkScreen> createState() => _BreathworkScreenState();
}

class _BreathworkScreenState extends State<BreathworkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isBreathing = false;
  int _remainingSeconds = 180;
  Timer? _timer;
  String _phase = 'Presiona para comenzar';
  final int _inhaleSeconds = 4;
  final int _holdSeconds = 4;
  final int _exhaleSeconds = 4;
  int _phaseSeconds = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isBreathing = true;
      _phase = 'Inhala';
      _phaseSeconds = _inhaleSeconds;
    });
    _controller.repeat();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _phaseSeconds--;
          if (_phaseSeconds <= 0) {
            switch (_phase) {
              case 'Inhala':
                _phase = 'Mantén';
                _phaseSeconds = _holdSeconds;
                break;
              case 'Mantén':
                _phase = 'Exhala';
                _phaseSeconds = _exhaleSeconds;
                break;
              case 'Exhala':
                _phase = 'Inhala';
                _phaseSeconds = _inhaleSeconds;
                break;
            }
          }
        } else {
          _stopBreathing();
        }
      });
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    _controller.stop();
    setState(() {
      _isBreathing = false;
      _phase = 'Presiona para comenzar';
    });
  }

  void _addTime() {
    setState(() => _remainingSeconds += 180);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PanicButton', style: tt.displayLarge),
                  const SizedBox(height: 40),

                  // 🌬 Breathing circle
                  GestureDetector(
                    onTap: _isBreathing ? _stopBreathing : _startBreathing,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary, // brand green
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center, // ← CENTER ALL CHILDREN
                        children: [
                          // Wave
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                return ClipPath(
                                  clipper: WaveClipper(
                                    animation: _controller.value,
                                    phase: _phase,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Phase text & counter
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _phase,
                                style: tt.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                              if (_isBreathing) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _phaseSeconds.toString(),
                                  style: tt.displayLarge,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Timer
                  Text(_formatTime(_remainingSeconds), style: tt.displayLarge),

                  // Add time
                  if (_isBreathing) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addTime,
                      child: const Text('+3 minutos'),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom nav
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomNavBar(currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animation;
  final String phase;

  WaveClipper({required this.animation, required this.phase});

  @override
  Path getClip(Size size) {
    final path = Path();
    final baseH = size.height * 0.5;
    final amp = size.height * 0.2;
    const freq = 2 * math.pi;
    double waveH = baseH;

    switch (phase) {
      case 'Inhala':
        waveH = baseH - (amp * animation);
        break;
      case 'Exhala':
        waveH = baseH + (amp * animation);
        break;
      case 'Mantén':
        break;
    }

    path.moveTo(0, size.height);
    for (double x = 0; x < size.width; x++) {
      final y =
          waveH + amp * math.sin((x / size.width * freq) + (animation * freq));
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => true;
}
