// lib/screens/breathwork_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/widgets/breathing_circle.dart';
import 'package:panic_button_flutter/widgets/wave_animation.dart';
import 'package:panic_button_flutter/widgets/phase_indicator.dart';
import 'package:panic_button_flutter/widgets/remaining_time_display.dart';
import 'package:panic_button_flutter/widgets/add_time_button.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('PanicButton',
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 40),

                  // 🌬 Breathing circle
                  BreathingCircle(
                    isBreathing: _isBreathing,
                    onTap: _isBreathing ? _stopBreathing : _startBreathing,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        WaveAnimation(
                          waveAnimation: _waveController,
                          fillLevel: _fillLevel,
                        ),
                        PhaseIndicator(
                          phase: _phase,
                          countdown: _countdownValue,
                          isBreathing: _isBreathing,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Timer
                  RemainingTimeDisplay(totalSeconds: _remainingSeconds),

                  // Add time
                  if (_isBreathing) ...[
                    const SizedBox(height: 20),
                    AddTimeButton(onPressed: _addTime),
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
