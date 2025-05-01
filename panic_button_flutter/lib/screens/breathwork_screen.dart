// lib/screens/breathwork_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/widgets/breathing_circle.dart';
import 'package:panic_button_flutter/widgets/wave_animation.dart';
import 'package:panic_button_flutter/widgets/phase_indicator.dart';
import 'package:panic_button_flutter/widgets/remaining_time_display.dart';
import 'package:panic_button_flutter/widgets/add_time_button.dart';
import 'package:panic_button_flutter/widgets/timer_controls.dart';
import 'package:panic_button_flutter/widgets/goal_selector.dart';
import 'package:panic_button_flutter/widgets/breathing_method_indicator.dart';
import 'package:panic_button_flutter/services/breath_queries.dart';
import 'package:panic_button_flutter/models/breath_types.dart';
import 'package:panic_button_flutter/widgets/pattern_selector.dart';

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
  int _remainingSeconds = 180; // Default 3 minutes
  Timer? _timer;
  String _phase = 'Presiona para comenzar';
  String _selectedGoal = 'calming'; // Default goal
  String _currentBreathingMethod = 'nose'; // Default method
  String? _selectedRoutineId;
  String _currentRoutineName = 'Respiración básica'; // Default routine name

  // Breathing pattern configuration (default values)
  int _inhaleSeconds = 4;
  int _holdAfterInhaleSeconds = 0;
  int _exhaleSeconds = 6;
  int _holdAfterExhaleSeconds = 0;

  List<ExpandedStep>? _breathSteps;
  int _currentStepIndex = 0;

  int _countdownValue = 0; // Clear countdown display value
  double _fillLevel = 0.0; // Wave fill level (0.0 to 1.0)

  @override
  void initState() {
    super.initState();

    _initializeAnimationControllers();

    // Load the first breathing routine for the default goal
    _loadBreathingRoutine(_selectedGoal);
  }

  void _initializeAnimationControllers() {
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
      if (!mounted) return;

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

  Future<void> _loadBreathingRoutine(String goalSlug) async {
    try {
      final steps = await getRoutinesByGoalSlug(goalSlug);

      // If we have steps, update our configuration
      if (steps.isNotEmpty) {
        if (mounted) {
          // Check if widget is still mounted
          setState(() {
            _breathSteps = steps;
            _currentStepIndex = 0;

            // Set the initial breathing parameters from the first step
            final firstStep = steps[0];
            _inhaleSeconds = firstStep.inhaleSecs;
            _holdAfterInhaleSeconds = firstStep.holdInSecs;
            _exhaleSeconds = firstStep.exhaleSecs;
            _holdAfterExhaleSeconds = firstStep.holdOutSecs;
            _currentBreathingMethod = firstStep.inhaleMethod;

            debugPrint(
                'Loaded breathing pattern: $_inhaleSeconds:$_exhaleSeconds');
          });
        }
      } else {
        // If no steps returned, set default pattern
        _setDefaultBreathingPattern();
      }
    } catch (e) {
      // If we can't load from the database, keep using the defaults
      debugPrint('Error loading breathing routine: $e');
      _setDefaultBreathingPattern();
    }
  }

  void _onGoalSelected(String goalSlug) {
    setState(() {
      _selectedGoal = goalSlug;

      // Stop any current breathing session when changing goals
      if (_isBreathing) {
        _stopBreathing();
      }
    });

    // Load the new breathing routine
    _loadBreathingRoutine(goalSlug);
  }

  void _onRoutineSelected(String routineData) {
    // Parse routine ID and name from the data (format: "id:name")
    final parts = routineData.split(':');
    if (parts.length >= 2) {
      final routineId = parts[0];
      final routineName =
          parts.sublist(1).join(':'); // Handle names with colons

      setState(() {
        _selectedRoutineId = routineId;
        _currentRoutineName = routineName;

        // Stop any current breathing session when changing routine
        if (_isBreathing) {
          _stopBreathing();
        }
      });

      // Load the breathing steps for this routine
      // Note: For now we're just loading by goal, will need to update to load by routine ID
      _loadBreathingRoutine(_selectedGoal);
    }
  }

  void _updateTotalTime(int newSeconds) {
    setState(() => _remainingSeconds = newSeconds);
  }

  void _startBreathing() {
    if (_breathSteps == null || _breathSteps!.isEmpty) {
      // If no steps are loaded, use default values
      _setDefaultBreathingPattern();
    }

    // Get the first step (or use current configuration)
    final currentStep = _breathSteps != null && _breathSteps!.isNotEmpty
        ? _breathSteps![_currentStepIndex]
        : null;

    // If we have a step, update our configuration
    if (currentStep != null) {
      _inhaleSeconds = currentStep.inhaleSecs;
      _holdAfterInhaleSeconds = currentStep.holdInSecs;
      _exhaleSeconds = currentStep.exhaleSecs;
      _holdAfterExhaleSeconds = currentStep.holdOutSecs;
      _currentBreathingMethod = currentStep.inhaleMethod;
    }

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
      if (!mounted) return;

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

  void _setDefaultBreathingPattern() {
    debugPrint('Setting default breathing pattern 4:6');
    _inhaleSeconds = 4;
    _holdAfterInhaleSeconds = 0;
    _exhaleSeconds = 6;
    _holdAfterExhaleSeconds = 0;
    _currentBreathingMethod = 'nose';

    // Create a default step for the breathSteps list
    _breathSteps = [
      const ExpandedStep(
        inhaleSecs: 4,
        inhaleMethod: 'nose',
        holdInSecs: 0,
        exhaleSecs: 6,
        exhaleMethod: 'nose',
        holdOutSecs: 0,
        repetitions: 1,
      ),
    ];
  }

  void _transitionToNextPhase() {
    // If the breathing session is not active, don't transition
    if (!_isBreathing) return;

    // Calculate which phase comes next
    String nextPhase;
    int nextDuration;

    switch (_phase) {
      case 'Inhala':
        if (_holdAfterInhaleSeconds > 0) {
          nextPhase = 'Mantén';
          nextDuration = _holdAfterInhaleSeconds;
        } else {
          nextPhase = 'Exhala';
          nextDuration = _exhaleSeconds;
        }
        break;
      case 'Mantén':
        nextPhase = 'Exhala';
        nextDuration = _exhaleSeconds;
        break;
      case 'Exhala':
        if (_holdAfterExhaleSeconds > 0) {
          nextPhase = 'Relaja';
          nextDuration = _holdAfterExhaleSeconds;
        } else {
          nextPhase = 'Inhala';
          nextDuration = _inhaleSeconds;
          // Move to the next step in the sequence if there are multiple steps
          if (_breathSteps != null && _breathSteps!.length > 1) {
            _currentStepIndex = (_currentStepIndex + 1) % _breathSteps!.length;
            final nextStep = _breathSteps![_currentStepIndex];
            _inhaleSeconds = nextStep.inhaleSecs;
            _holdAfterInhaleSeconds = nextStep.holdInSecs;
            _exhaleSeconds = nextStep.exhaleSecs;
            _holdAfterExhaleSeconds = nextStep.holdOutSecs;
            _currentBreathingMethod = nextStep.inhaleMethod;
          }
        }
        break;
      case 'Relaja':
        nextPhase = 'Inhala';
        nextDuration = _inhaleSeconds;
        // Move to the next step in the sequence if there are multiple steps
        if (_breathSteps != null && _breathSteps!.length > 1) {
          _currentStepIndex = (_currentStepIndex + 1) % _breathSteps!.length;
          final nextStep = _breathSteps![_currentStepIndex];
          _inhaleSeconds = nextStep.inhaleSecs;
          _holdAfterInhaleSeconds = nextStep.holdInSecs;
          _exhaleSeconds = nextStep.exhaleSecs;
          _holdAfterExhaleSeconds = nextStep.holdOutSecs;
          _currentBreathingMethod = nextStep.inhaleMethod;
        }
        break;
      default:
        nextPhase = 'Inhala';
        nextDuration = _inhaleSeconds;
    }

    // Update phase and countdown
    setState(() {
      _phase = nextPhase;
      _countdownValue = nextDuration;
    });

    // Configure and start the animation for the next phase
    _breathController.duration = Duration(seconds: nextDuration);

    if (nextPhase == 'Inhala') {
      _breathController.forward(from: 0.0);
    } else if (nextPhase == 'Exhala') {
      _breathController.forward(from: 0.0);
    } else {
      // For hold phases, we don't animate, but need to wait
      Future.delayed(Duration(seconds: nextDuration), () {
        if (mounted && _isBreathing) {
          _transitionToNextPhase();
        }
      });
    }
  }

  void _stopBreathing() {
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isBreathing = false;
      _phase = 'Presiona para comenzar';
      _fillLevel = 0.0;
    });

    _breathController.stop();
  }

  void _addTime() {
    setState(() {
      _remainingSeconds += 60; // Add one minute
    });
  }

  void _showRoutineSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PatternSelectorModal(
        currentPattern: _selectedRoutineId ?? '', // No longer using patterns
        onPatternSelected: _onRoutineSelected, // This now receives routineData
        onGoalSelected: _onGoalSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Main content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // 🌬 Breathing circle
                Expanded(
                  child: Center(
                    child: BreathingCircle(
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
                  ),
                ),

                // Bottom controller section
                if (_isBreathing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child:
                        RemainingTimeDisplay(totalSeconds: _remainingSeconds),
                  ),

                // Routine selector and time display - when not breathing
                if (!_isBreathing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 80, top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Time display
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_remainingSeconds ~/ 60} min',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Open routines selector button
                        GestureDetector(
                          onTap: _showRoutineSelector,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Otras respiraciones',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Add time button during active session
                if (_isBreathing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: AddTimeButton(onPressed: _addTime),
                  ),
              ],
            ),
          ),

          // Bottom nav (outside of Expanded to ensure it's at the bottom)
          const CustomNavBar(currentIndex: 2),
        ],
      ),
    );
  }
}
