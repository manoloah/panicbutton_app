// lib/screens/breathwork_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/theme/app_theme.dart';

class BreathworkScreen extends StatefulWidget {
  const BreathworkScreen({super.key});

  @override
  State<BreathworkScreen> createState() => _BreathworkScreenState();
}

class _BreathworkScreenState extends State<BreathworkScreen>
    with TickerProviderStateMixin {
  // Using multiple animation controllers for more fluid wave movement
  late AnimationController _waveController;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  bool _isBreathing = false;
  int _remainingSeconds = 180;
  Timer? _timer;
  String _phase = 'Presiona para comenzar';

  // Breathing pattern configuration
  final int _inhaleSeconds = 4;
  final int _holdAfterInhaleSeconds = 2;
  final int _exhaleSeconds = 4;
  final int _holdAfterExhaleSeconds = 2; // New pause after exhale

  int _countdownValue = 0; // Clear countdown display value
  double _fillLevel = 0.0; // Wave fill level (0.0 to 1.0)

  @override
  void initState() {
    super.initState();

    // Wave animation controller - continuous for side-to-side movement
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Slower for smoother wave
    );
    _waveController.repeat();

    // Breath animation controller - for up/down movement
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleSeconds), // Default to inhale duration
    );

    // Initialize breath animation
    _breathAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );

    // Listen to breath animation for smooth updates
    _breathAnimation.addListener(() {
      setState(() {
        // Update fill level based on current phase and animation
        if (_isBreathing) {
          switch (_phase) {
            case 'Inhala':
              _fillLevel = _breathAnimation.value;
              break;
            case 'Mantén':
              _fillLevel = 1.0;
              break;
            case 'Exhala':
              _fillLevel = 1.0 - _breathAnimation.value;
              break;
            case 'Relaja':
              _fillLevel = 0.0;
              break;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _breathController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    // Calculate the starting countdown for the first phase
    _countdownValue = _inhaleSeconds;

    setState(() {
      _isBreathing = true;
      _phase = 'Inhala';
      _fillLevel = 0.0;
    });

    // Set up the animation for inhale
    _breathController.duration = Duration(seconds: _inhaleSeconds);
    _breathController.forward(from: 0.0);

    _timer?.cancel();
    // Use a 100ms timer for smooth updates
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_remainingSeconds <= 0) {
        _stopBreathing();
        return;
      }

      // Every second, update the countdown and remaining time
      if (_timer!.tick % 10 == 0) {
        setState(() {
          _remainingSeconds--;
          _countdownValue = math.max(1, _countdownValue - 1);
        });
      }

      // Check if we need to transition to the next phase
      if (!_breathController.isAnimating && _isBreathing) {
        _transitionToNextPhase();
      }
    });
  }

  void _transitionToNextPhase() {
    switch (_phase) {
      case 'Inhala':
        setState(() {
          _phase = 'Mantén';
          _countdownValue = _holdAfterInhaleSeconds;
          _fillLevel = 1.0; // Keep wave at top during hold
        });

        // Hold at the top - use a timer instead of animation
        Future.delayed(Duration(seconds: _holdAfterInhaleSeconds), () {
          if (_isBreathing) {
            setState(() {
              _phase = 'Exhala';
              _countdownValue = _exhaleSeconds;
            });

            // Set up animation for exhale
            _breathController.duration = Duration(seconds: _exhaleSeconds);
            _breathController.forward(from: 0.0);
          }
        });
        break;

      case 'Exhala':
        setState(() {
          _phase = 'Relaja';
          _countdownValue = _holdAfterExhaleSeconds;
          _fillLevel = 0.0; // Keep wave at bottom during hold
        });

        // Hold at the bottom - use a timer instead of animation
        Future.delayed(Duration(seconds: _holdAfterExhaleSeconds), () {
          if (_isBreathing) {
            setState(() {
              _phase = 'Inhala';
              _countdownValue = _inhaleSeconds;
            });

            // Set up animation for inhale
            _breathController.duration = Duration(seconds: _inhaleSeconds);
            _breathController.forward(from: 0.0);
          }
        });
        break;
    }
  }

  void _stopBreathing() {
    _timer?.cancel();
    _breathController.stop();
    setState(() {
      _isBreathing = false;
      _phase = 'Presiona para comenzar';
      _fillLevel = 0.0;
      _countdownValue = 0;
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
    final breathColors = Theme.of(context).extension<BreathColors>()!;

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
                        alignment: Alignment.center,
                        children: [
                          // Fluid Wave Animation
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, _) {
                                return ClipOval(
                                  child: CustomPaint(
                                    painter: WavePainter(
                                      waveAnimation: _waveController.value,
                                      fillLevel: _fillLevel,
                                      oceanDeep: breathColors.oceanDeep,
                                      oceanMid: breathColors.oceanMid,
                                      oceanSurface: breathColors.oceanSurface,
                                    ),
                                    size: Size(280, 280),
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
                                  _countdownValue.toString(),
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

// A custom painter that creates fluid wave animation
class WavePainter extends CustomPainter {
  final double waveAnimation; // 0.0 to 1.0
  final double fillLevel; // 0.0 to 1.0, where 1.0 is filled to top
  final Color oceanDeep;
  final Color oceanMid;
  final Color oceanSurface;

  WavePainter({
    required this.waveAnimation,
    required this.fillLevel,
    required this.oceanDeep,
    required this.oceanMid,
    required this.oceanSurface,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate wave parameters
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;
    final radius = math.min(centerX, centerY);

    // Create a shader for the wave gradient
    final rect = Rect.fromLTWH(0, 0, width, height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        oceanSurface.withOpacity(0.9),
        oceanMid.withOpacity(0.7),
        oceanDeep.withOpacity(0.5),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    // Create paint for the wave
    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Area to fill (from bottom)
    final fillHeight = height * (1.0 - fillLevel);

    // Create the main path for water
    final path = Path();
    path.moveTo(0, height);

    // Wave parameters
    final baseWaveHeight = fillHeight;
    final waveWidth = width;
    final waveHeight = radius * 0.05; // amplitude

    // Draw two overlapping waves for more natural effect
    final primaryWaveSpeed = waveAnimation * math.pi * 2;
    final secondaryWaveSpeed = waveAnimation * math.pi * 3;

    // Higher resolution makes smoother curves
    final step = 2.0; // smaller step = smoother curve

    for (double x = 0; x <= width; x += step) {
      // Calculate wave Y position with two overlapping sine waves
      final primary =
          math.sin((x / waveWidth * 8 * math.pi) + primaryWaveSpeed);
      final secondary =
          math.sin((x / waveWidth * 12 * math.pi) + secondaryWaveSpeed) * 0.3;

      // Wave Y position with dynamic amplitude near the fill level
      final dynamicAmplitude =
          waveHeight * (1.0 - 0.3 * math.cos(primaryWaveSpeed));
      final waveY = baseWaveHeight + (primary + secondary) * dynamicAmplitude;

      // Add point to path
      path.lineTo(x, waveY);
    }

    // Complete the path
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    // Draw the wave, clipped to the circle
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromLTWH(0, 0, width, height));
    canvas.clipPath(clipPath);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.fillLevel != fillLevel;
  }
}
