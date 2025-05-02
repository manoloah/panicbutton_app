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
  });

  BreathingPlaybackState copyWith({
    bool? isPlaying,
    int? currentStepIndex,
    double? secondsRemaining,
    int? totalSeconds,
    List<ExpandedStep>? steps,
    BreathPhase? currentPhase,
    double? phaseSecondsRemaining,
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
    );
  }
}

enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathingPlaybackController
    extends StateNotifier<BreathingPlaybackState> {
  final BreathRepository _repository;
  final Ref _ref;
  Timer? _timer;

  BreathingPlaybackController(this._repository, this._ref)
      : super(const BreathingPlaybackState());

  void initialize(List<ExpandedStep> steps, int durationMinutes) {
    if (steps.isEmpty) {
      return;
    }

    final totalSeconds = durationMinutes * 60;
    state = BreathingPlaybackState(
      steps: steps,
      secondsRemaining: totalSeconds.toDouble(),
      totalSeconds: totalSeconds,
      currentPhase: BreathPhase.inhale,
      phaseSecondsRemaining:
          steps.isNotEmpty ? steps[0].inhaleSecs.toDouble() : 0,
    );
  }

  void play() {
    if (state.isPlaying || state.steps.isEmpty) {
      return;
    }

    state = state.copyWith(isPlaying: true);

    // Use a less frequent timer update to reduce CPU usage
    // Increase timer interval from 60ms to 100ms
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _onTimerTick);

    // Log the pattern run when starting
    final pattern = _ref.read(selectedPatternProvider);
    final duration = _ref.read(selectedDurationProvider);
    if (pattern != null) {
      _repository.logPatternRun(pattern.id, duration).catchError((e) {
        // Silent catch - pattern logging is non-critical
      });
    }
  }

  void pause() {
    if (!state.isPlaying) return;

    _timer?.cancel();
    state = state.copyWith(isPlaying: false);
  }

  void reset() {
    _timer?.cancel();

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
  }

  void _onTimerTick(Timer timer) {
    // If we've reached the end of the session, stop
    if (state.secondsRemaining <= 0) {
      timer.cancel();
      state = state.copyWith(isPlaying: false);
      return;
    }

    if (state.currentStepIndex >= state.steps.length) {
      timer.cancel();
      state = state.copyWith(isPlaying: false);
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
      // Just update the timers - keep the double precision for smoother countdown
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
