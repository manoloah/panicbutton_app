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

class _BreathworkScreenState extends State<BreathworkScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isBreathing = false;
  int _totalSeconds = 0;
  int _remainingSeconds = 180; // 3 minutes default
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
      duration: const Duration(seconds: 12), // Full breath cycle
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
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _totalSeconds++;
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
    setState(() {
      _remainingSeconds += 180; // Add 3 more minutes
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF132737),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'PanicButton',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _isBreathing ? _stopBreathing : _startBreathing,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00B383),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B383).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Wave Animation
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
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
                          // Text
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _phase,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_isBreathing) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _phaseSeconds.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isBreathing) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        '+3 minutos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
    final baseHeight = size.height * 0.5;
    final amplitude = size.height * 0.2;
    final frequency = 2 * math.pi;

    // Adjust wave based on breathing phase
    double waveHeight = baseHeight;
    switch (phase) {
      case 'Inhala':
        waveHeight = baseHeight - (amplitude * animation);
        break;
      case 'Exhala':
        waveHeight = baseHeight + (amplitude * animation);
        break;
      case 'Mantén':
        // Keep current height
        break;
    }

    path.moveTo(0, size.height);
    
    for (double x = 0; x < size.width; x++) {
      final y = waveHeight +
          amplitude * math.sin((x / size.width * frequency) + (animation * frequency));
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
} 