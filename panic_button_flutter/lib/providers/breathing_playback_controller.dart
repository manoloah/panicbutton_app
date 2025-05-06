import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/models/breath_models.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';
import 'package:panic_button_flutter/data/breath_repository.dart';

class BreathingPlaybackState {
  final bool isPlaying;
  final int currentStepIndex;
  final double secondsRemaining;
  final int totalSeconds;
  final List<ExpandedStep> steps;
  final BreathPhase currentPhase;
  final double phaseSecondsRemaining;
  final String? currentActivityId;
  final int elapsedSeconds;

  ExpandedStep? get currentStep =>
      steps.isNotEmpty && currentStepIndex < steps.length
          ? steps[currentStepIndex]
          : null;

  const BreathingPlaybackState({
    this.isPlaying = false,
    this.currentStepIndex = 0,
    this.secondsRemaining = 0,
    this.totalSeconds = 0,
    this.steps = const [],
    this.currentPhase = BreathPhase.inhale,
    this.phaseSecondsRemaining = 0,
    this.currentActivityId,
    this.elapsedSeconds = 0,
  });

  BreathingPlaybackState copyWith({
    bool? isPlaying,
    int? currentStepIndex,
    double? secondsRemaining,
    int? totalSeconds,
    List<ExpandedStep>? steps,
    BreathPhase? currentPhase,
    double? phaseSecondsRemaining,
    String? currentActivityId,
    int? elapsedSeconds,
  }) {
    return BreathingPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      steps: steps ?? this.steps,
      currentPhase: currentPhase ?? this.currentPhase,
      phaseSecondsRemaining:
          phaseSecondsRemaining ?? this.phaseSecondsRemaining,
      currentActivityId: currentActivityId ?? this.currentActivityId,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }
}

enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingPlaybackController
    extends StateNotifier<BreathingPlaybackState> {
  final BreathRepository _repository;
  final Ref _ref;
  Timer? _timer;
  DateTime? _startTime;
  int _accumulatedSeconds = 0;

  BreathingPlaybackController(this._repository, this._ref)
      : super(const BreathingPlaybackState());

  void initialize(List<ExpandedStep> steps, int durationMinutes) {
    if (steps.isEmpty) {
      return;
    }

    // If there's an ongoing activity, complete it
    _completeCurrentActivity(false);

    final totalSeconds = durationMinutes * 60;
    state = BreathingPlaybackState(
      steps: steps,
      secondsRemaining: totalSeconds.toDouble(),
      totalSeconds: totalSeconds,
      currentPhase: BreathPhase.inhale,
      phaseSecondsRemaining:
          steps.isNotEmpty ? steps[0].inhaleSecs.toDouble() : 0,
      elapsedSeconds: 0,
      currentActivityId: null,
    );

    _startTime = null;
    _accumulatedSeconds = 0;

    // Log debug info about initialization
    final pattern = _ref.read(selectedPatternProvider);
    if (pattern != null) {
      debugPrint(
          '🔄 Initialized pattern: ${pattern.name} (${pattern.id}), duration: $durationMinutes minutes');
    }
  }

  Future<void> play() async {
    if (state.isPlaying || state.steps.isEmpty) {
      return;
    }

    // Set the start time for this session
    _startTime = DateTime.now();

    // Update state
    state = state.copyWith(isPlaying: true);

    // Start the timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _onTimerTick);

    // Get pattern and duration info
    final pattern = _ref.read(selectedPatternProvider);
    final duration = _ref.read(selectedDurationProvider);

    // Create a new activity if needed
    if (state.currentActivityId == null && pattern != null) {
      try {
        // Create a new activity record
        await _repository.logPatternRun(pattern.id, duration);

        // Get current activity ID
        final activityId = await _repository.getCurrentBreathingActivity();
        if (activityId != null) {
          state = state.copyWith(currentActivityId: activityId);
          debugPrint(
              '🧘 Started tracking activity: $activityId for pattern: ${pattern.name}');
        }
      } catch (e) {
        debugPrint('❌ Error starting activity tracking: $e');
      }
    } else {
      debugPrint(
          '▶️ Resuming existing session, accumulated seconds: $_accumulatedSeconds');
    }
  }

  Future<void> pause() async {
    if (!state.isPlaying) return;

    // Stop the timer
    _timer?.cancel();

    // Update state
    state = state.copyWith(isPlaying: false);

    // Calculate seconds for this session
    if (_startTime != null) {
      final sessionSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _accumulatedSeconds += sessionSeconds;
      debugPrint(
          '⏸️ Paused - session duration: ${sessionSeconds}s, accumulated: ${_accumulatedSeconds}s');
      _startTime = null;
    }
  }

  Future<void> reset() async {
    _timer?.cancel();

    // Complete the current activity
    _completeCurrentActivity(false);

    // Reset state
    final steps = state.steps;
    final totalSeconds = state.totalSeconds;

    if (steps.isEmpty) {
      return;
    }

    state = BreathingPlaybackState(
      steps: steps,
      secondsRemaining: totalSeconds.toDouble(),
      totalSeconds: totalSeconds,
      currentPhase: BreathPhase.inhale,
      phaseSecondsRemaining:
          steps.isNotEmpty ? steps[0].inhaleSecs.toDouble() : 0,
    );

    _startTime = null;
    _accumulatedSeconds = 0;
  }

  Future<void> _completeCurrentActivity(bool completed) async {
    try {
      final activityId = state.currentActivityId;
      if (activityId == null) return;

      // Calculate final duration
      int totalDuration = _accumulatedSeconds;

      // Add the current session if timer is running
      if (_startTime != null) {
        final currentSessionSeconds =
            DateTime.now().difference(_startTime!).inSeconds;
        totalDuration += currentSessionSeconds;
      }

      // Ensure minimum duration for completed activities (to trigger status update)
      if (completed && totalDuration < 10) {
        totalDuration = 10;
      }

      // Skip updating with zero duration
      if (totalDuration <= 0) {
        debugPrint('⚠️ Skipping activity update with zero duration');
        return;
      }

      // Update the activity record
      await _repository.completeBreathingActivity(
          activityId, totalDuration, completed);

      debugPrint(
          '✅ Activity completed: $activityId, total duration: ${totalDuration}s, completed: $completed');

      // Reset tracking
      state = state.copyWith(currentActivityId: null, elapsedSeconds: 0);
      _startTime = null;
      _accumulatedSeconds = 0;
    } catch (e) {
      debugPrint('❌ Error completing activity: $e');
    }
  }

  void _onTimerTick(Timer timer) {
    // If we've reached the end of the session, stop
    if (state.secondsRemaining <= 0) {
      timer.cancel();
      state = state.copyWith(isPlaying: false);

      // Mark activity as completed
      _completeCurrentActivity(true);
      return;
    }

    if (state.currentStepIndex >= state.steps.length) {
      timer.cancel();
      state = state.copyWith(isPlaying: false);

      // Mark activity as completed
      _completeCurrentActivity(true);
      return;
    }

    // Decrease overall time remaining (100ms per tick = 0.1 seconds)
    final newSecondsRemaining = state.secondsRemaining - 0.1;

    // Decrease phase time remaining (100ms per tick)
    final newPhaseSecondsRemaining = state.phaseSecondsRemaining - 0.1;

    // If current phase is complete, move to next phase
    if (newPhaseSecondsRemaining <= 0) {
      _moveToNextPhase();
    } else {
      // Just update the timers
      state = state.copyWith(
        secondsRemaining: newSecondsRemaining,
        phaseSecondsRemaining: newPhaseSecondsRemaining,
      );
    }
  }

  void _moveToNextPhase() {
    final currentStep = state.currentStep;
    if (currentStep == null) {
      return;
    }

    int newIndex = state.currentStepIndex;
    BreathPhase newPhase;
    int phaseSeconds;

    // Determine next phase based on current phase
    switch (state.currentPhase) {
      case BreathPhase.inhale:
        newPhase = BreathPhase.holdIn;
        phaseSeconds = currentStep.holdInSecs;
        break;
      case BreathPhase.holdIn:
        newPhase = BreathPhase.exhale;
        phaseSeconds = currentStep.exhaleSecs;
        break;
      case BreathPhase.exhale:
        newPhase = BreathPhase.holdOut;
        phaseSeconds = currentStep.holdOutSecs;
        break;
      case BreathPhase.holdOut:
        // Move to next step
        newIndex = state.currentStepIndex + 1;
        if (newIndex < state.steps.length) {
          newPhase = BreathPhase.inhale;
          phaseSeconds = state.steps[newIndex].inhaleSecs;
        } else {
          // End of steps
          _timer?.cancel();
          state = state.copyWith(isPlaying: false);
          return;
        }
        break;
    }

    // Skip zero-duration phases
    if (phaseSeconds <= 0) {
      state = state.copyWith(
        currentStepIndex: newIndex,
        currentPhase: newPhase,
        phaseSecondsRemaining: phaseSeconds.toDouble(),
      );
      _moveToNextPhase(); // Recursively move to next phase
      return;
    }

    state = state.copyWith(
      currentStepIndex: newIndex,
      currentPhase: newPhase,
      phaseSecondsRemaining: phaseSeconds.toDouble(),
    );
  }

  String getPhaseDisplayText() {
    switch (state.currentPhase) {
      case BreathPhase.inhale:
        return 'Inhala';
      case BreathPhase.holdIn:
        return 'Mantén';
      case BreathPhase.exhale:
        return 'Exhala';
      case BreathPhase.holdOut:
        return 'Relaja';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    // Make sure to complete any in-progress activity
    _completeCurrentActivity(false);

    super.dispose();
  }
}

final breathingPlaybackControllerProvider =
    StateNotifierProvider<BreathingPlaybackController, BreathingPlaybackState>(
        (ref) {
  final repository = ref.watch(breathRepositoryProvider);
  return BreathingPlaybackController(repository, ref);
});

// Provider for current breathing phase text
final breathingPhaseTextProvider = Provider<String>((ref) {
  final playbackState = ref.watch(breathingPlaybackControllerProvider);
  if (!playbackState.isPlaying) {
    return 'Presiona para comenzar';
  }

  switch (playbackState.currentPhase) {
    case BreathPhase.inhale:
      return 'Inhala';
    case BreathPhase.holdIn:
      return 'Mantén';
    case BreathPhase.exhale:
      return 'Exhala';
    case BreathPhase.holdOut:
      return 'Relaja';
  }
});
