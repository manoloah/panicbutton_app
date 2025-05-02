// lib/screens/breathwork_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:panic_button_flutter/models/breathing_exercise.dart';
import 'package:panic_button_flutter/models/breathwork_models.dart' as db;
import 'package:panic_button_flutter/services/exercise_service.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/widgets/breathing_circle.dart';
import 'package:panic_button_flutter/widgets/wave_animation.dart';
import 'package:panic_button_flutter/widgets/phase_indicator.dart';
import 'package:panic_button_flutter/widgets/remaining_time_display.dart';
import 'package:panic_button_flutter/widgets/add_time_button.dart';
import 'package:panic_button_flutter/widgets/breathing_method_indicator.dart';

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

  final ExerciseService _exerciseService = ExerciseService();
  BreathingExercise? _currentExercise;
  bool _isLoading = true;
  bool _isBreathing = false;
  int _remainingSeconds = 180;
  Timer? _timer;
  String _phase = 'Presiona para comenzar';
  int _currentPhaseIndex = 0;

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
      duration: const Duration(seconds: 4), // Default duration, will be updated
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

    // Load the default exercise
    _loadDefaultExercise();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _breathController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startBreathing() {
    if (_currentExercise == null || _currentExercise!.phases.isEmpty) {
      return;
    }

    _currentPhaseIndex = 0;
    final firstPhase = _currentExercise!.phases[_currentPhaseIndex];

    // Calculate the starting countdown for the first phase
    _countdownValue = firstPhase.seconds;

    setState(() {
      _isBreathing = true;
      _phase = firstPhase.displayName;
      _fillLevel = 0.0;
    });

    // Set up the animation for the first phase
    _setupAnimationForPhase(firstPhase);

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

  void _setupAnimationForPhase(BreathingPhase phase) {
    // Only set up animation for inhale and exhale
    if (phase.type == PhaseType.inhale || phase.type == PhaseType.exhale) {
      _breathController.duration = Duration(seconds: phase.seconds);
      _breathController.forward(from: 0.0);
    }
  }

  void _transitionToNextPhase() {
    if (!mounted) return;
    if (_currentExercise == null) return;

    final phases = _currentExercise!.phases;

    // Move to the next phase
    _currentPhaseIndex = (_currentPhaseIndex + 1) % phases.length;
    final nextPhase = phases[_currentPhaseIndex];

    if (!mounted) return;
    setState(() {
      _phase = nextPhase.displayName;
      _countdownValue = nextPhase.seconds;
    });

    // Handle the different types of phases
    switch (nextPhase.type) {
      case PhaseType.inhale:
        if (!mounted) return;
        setState(() => _fillLevel = 0.0);
        _breathController.duration = Duration(seconds: nextPhase.seconds);
        _breathController.forward(from: 0.0);
        break;

      case PhaseType.holdIn:
        if (!mounted) return;
        setState(() => _fillLevel = 1.0);
        _breathController.stop();

        // Use separate timer for hold phases to ensure they run for full duration
        // Cancel any existing timer
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          // Every 100ms, update the countdown
          if (timer.tick % 10 == 0 && _countdownValue > 0) {
            setState(() {
              _countdownValue = math.max(1, _countdownValue - 1);
              _remainingSeconds = math.max(0, _remainingSeconds - 1);
            });
          }

          // When countdown reaches 0, move to next phase
          if (_countdownValue <= 1 && timer.tick >= nextPhase.seconds * 10) {
            timer.cancel();
            if (mounted && _isBreathing) {
              _transitionToNextPhase();
            }
          }
        });
        break;

      case PhaseType.exhale:
        if (!mounted) return;
        setState(() => _fillLevel = 1.0);
        _breathController.duration = Duration(seconds: nextPhase.seconds);
        _breathController.forward(from: 0.0);
        break;

      case PhaseType.holdOut:
        if (!mounted) return;
        setState(() => _fillLevel = 0.0);
        _breathController.stop();

        // Use separate timer for hold phases to ensure they run for full duration
        // Cancel any existing timer
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }

          // Every 100ms, update the countdown
          if (timer.tick % 10 == 0 && _countdownValue > 0) {
            setState(() {
              _countdownValue = math.max(1, _countdownValue - 1);
              _remainingSeconds = math.max(0, _remainingSeconds - 1);
            });
          }

          // When countdown reaches 0, move to next phase
          if (_countdownValue <= 1 && timer.tick >= nextPhase.seconds * 10) {
            timer.cancel();
            if (mounted && _isBreathing) {
              _transitionToNextPhase();
            }
          }
        });
        break;
    }
  }

  void _stopBreathing() {
    if (!mounted) return;

    _timer?.cancel();
    _breathController.stop();

    // Track the completion of the exercise
    if (_currentExercise != null) {
      _exerciseService.trackRoutineCompletion(_currentExercise!.id);
    }

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

  Future<void> _showGoalSelectionDialog() async {
    if (_isBreathing) return; // Don't show dialog if breathing is active

    setState(() => _isLoading = true);
    final goals = await _exerciseService.getGoals();
    setState(() => _isLoading = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Selecciona un objetivo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              if (goals.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No se encontraron objetivos'),
                ))
              else
                SizedBox(
                  height: 300, // Fixed height for scrolling
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      // Determine color based on goal type
                      Color goalColor;
                      IconData goalIcon;

                      switch (goal.slug) {
                        case 'calming':
                          goalColor = Colors.blue;
                          goalIcon = Icons.spa;
                          break;
                        case 'energizing':
                          goalColor = Colors.orange;
                          goalIcon = Icons.flash_on;
                          break;
                        case 'focusing':
                          goalColor = Colors.purple;
                          goalIcon = Icons.center_focus_strong;
                          break;
                        case 'grounding':
                          goalColor = Colors.green;
                          goalIcon = Icons.balance;
                          break;
                        default:
                          goalColor = Theme.of(context).colorScheme.primary;
                          goalIcon = Icons.air;
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showRoutineSelectionDialog(goal);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: goalColor.withOpacity(0.2),
                                  child: Icon(
                                    goalIcon,
                                    color: goalColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      if (goal.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          goal.description!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRoutineSelectionDialog(db.Goal goal) async {
    setState(() => _isLoading = true);

    final routines = await _exerciseService.getRoutinesByGoal(goal.id);

    setState(() => _isLoading = false);

    if (!mounted) return;

    // Determine color based on goal type
    Color goalColor;
    switch (goal.slug) {
      case 'calming':
        goalColor = Colors.blue;
        break;
      case 'energizing':
        goalColor = Colors.orange;
        break;
      case 'focusing':
        goalColor = Colors.purple;
        break;
      case 'grounding':
        goalColor = Colors.green;
        break;
      default:
        goalColor = Theme.of(context).colorScheme.primary;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: goalColor.withOpacity(0.2),
                    child: Icon(
                      _getIconForGoal(goal.slug),
                      color: goalColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      goal.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (routines.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                        'No se encontraron rutinas para ${goal.displayName}'),
                  ),
                )
              else
                SizedBox(
                  height: 300, // Fixed height for scrolling
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).pop();
                            _loadRoutine(routine);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: goalColor.withOpacity(0.2),
                                  child: Text(
                                    '${routine.totalMinutes ?? "?"}m',
                                    style: TextStyle(
                                      color: goalColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    routine.name ?? 'Rutina sin nombre',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForGoal(String? slug) {
    switch (slug) {
      case 'calming':
        return Icons.spa;
      case 'energizing':
        return Icons.flash_on;
      case 'focusing':
        return Icons.center_focus_strong;
      case 'grounding':
        return Icons.balance;
      default:
        return Icons.air;
    }
  }

  Future<void> _loadDefaultExercise() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final exercise = await _exerciseService.getDefaultExercise();
      if (!mounted) return;

      setState(() {
        _currentExercise = exercise;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading default exercise: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRoutine(db.Routine routine) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final exercise =
          await _exerciseService.getExerciseFromRoutine(routine.id);
      if (!mounted) return;

      setState(() {
        if (exercise != null) {
          _currentExercise = exercise;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('No se pudo cargar este ejercicio. Intenta con otro.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading exercise: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ocurrió un error al cargar el ejercicio. Intenta de nuevo.'),
          duration: Duration(seconds: 3),
        ),
      );
      setState(() => _isLoading = false);
    }
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
                    onTap: _isLoading
                        ? () {}
                        : _isBreathing
                            ? _stopBreathing
                            : _startBreathing,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        WaveAnimation(
                          waveAnimation: _waveController,
                          fillLevel: _fillLevel,
                        ),
                        if (_isLoading) ...[
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ] else ...[
                          PhaseIndicator(
                            phase: _phase,
                            countdown: _countdownValue,
                            isBreathing: _isBreathing,
                          ),
                          // Show method indicators when breathing
                          if (_isBreathing && _currentExercise != null) ...[
                            // Get the current phase
                            BreathingMethodIndicator(
                              phase: _phase,
                              method: _currentPhaseIndex <
                                      _currentExercise!.phases.length
                                  ? _currentExercise!
                                      .phases[_currentPhaseIndex].method
                                  : null,
                              isActive: true,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Timer
                  RemainingTimeDisplay(totalSeconds: _remainingSeconds),

                  // Add time button when breathing
                  if (_isBreathing) ...[
                    const SizedBox(height: 20),
                    AddTimeButton(onPressed: _addTime),
                  ]
                  // Show exercise selection button when not breathing
                  else if (!_isLoading) ...[
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: _showGoalSelectionDialog,
                      icon: const Icon(Icons.list),
                      label: const Text('Otros ejercicios'),
                    ),
                    if (_currentExercise != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _currentExercise!.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        _currentExercise!.patternCode,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
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
