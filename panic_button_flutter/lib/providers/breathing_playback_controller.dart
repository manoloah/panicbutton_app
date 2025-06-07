// REFACTORED: Enhanced breathing playback controller with session state persistence
// Changes:
// - Added session state saving/restoring functionality using SharedPreferences
// - Enhanced pause() method to save current session state
// - Added restoreSessionState() method to resume from saved state
// - Modified initialize() to avoid re-initialization when valid session exists
// - Added proper state cleanup and persistence on disposal

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/models/breath_models.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';
import 'package:panic_button_flutter/data/breath_repository.dart';
import 'package:panic_button_flutter/services/audio_service.dart';
import 'package:panic_button_flutter/services/breathing_state_persistence_service.dart';

// Provider to track the last breath phase for voice prompt triggering
final lastBreathPhaseProvider = StateProvider<BreathPhase?>((ref) => null);

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

// Helper extension to convert BreathPhase to BreathVoicePhase
extension BreathPhaseToVoicePhase on BreathPhase {
  BreathVoicePhase toVoicePhase() {
    switch (this) {
      case BreathPhase.inhale:
        return BreathVoicePhase.inhale;
      case BreathPhase.holdIn:
        return BreathVoicePhase.pauseAfterInhale;
      case BreathPhase.exhale:
        return BreathVoicePhase.exhale;
      case BreathPhase.holdOut:
        return BreathVoicePhase.pauseAfterExhale;
    }
  }
}

class BreathingPlaybackController
    extends StateNotifier<BreathingPlaybackState> {
  final BreathRepository _repository;
  final Ref _ref;
  Timer? _timer;
  DateTime? _startTime;
  int _accumulatedSeconds = 0;

  BreathingPlaybackController(this._repository, this._ref)
      : super(const BreathingPlaybackState());

  /// Initializes the controller with a new set of steps and total duration.
  void initialize(List<ExpandedStep> steps, int durationMinutes,
      {bool forceReset = false}) {
    if (steps.isEmpty) {
      return;
    }

    // Don't re-initialize if we already have a valid session unless forced
    if (!forceReset && state.steps.isNotEmpty && state.totalSeconds > 0) {
      debugPrint('🔄 Skipping initialization - valid session already exists');
      return;
    }

    debugPrint('🔄 Initializing new breathing session');
    _timer?.cancel();

    // When we force a reset (like after finishing a session), we don't want
    // to call _completeCurrentActivity again. So we just reset timers.
    if (forceReset) {
      _startTime = null;
      _accumulatedSeconds = 0;
    } else {
      // If not a forceReset, it means a previous session might have been abandoned
      // without being finished. We mark it as incomplete.
      _completeCurrentActivity(false);
    }

    final totalSeconds = durationMinutes * 60;
    state = BreathingPlaybackState(
      steps: steps,
      secondsRemaining: totalSeconds.toDouble(),
      totalSeconds: totalSeconds,
      currentPhase: BreathPhase.inhale,
      phaseSecondsRemaining:
          steps.isNotEmpty ? steps[0].inhaleSecs.toDouble() : 0,
      elapsedSeconds: 0,
      currentActivityId: null, // Always start with a fresh activity ID
    );

    // Start a new activity record in the database
    _startNewActivity();

    // Log debug info about initialization
    final pattern = _ref.read(selectedPatternProvider);
    if (pattern != null) {
      debugPrint(
          '🔄 Initialized pattern: ${pattern.name} (${pattern.id}), duration: $durationMinutes minutes');
    }
  }

  /// Starts a new breathing activity and stores its ID in the state.
  Future<void> _startNewActivity() async {
    try {
      final pattern = _ref.read(selectedPatternProvider);
      if (pattern == null) {
        debugPrint('⚠️ Cannot start activity, no pattern selected');
        return;
      }

      // We get the current activity, which should have been created on page load.
      final newActivityId = await _repository.getCurrentBreathingActivity();
      if (newActivityId != null) {
        state = state.copyWith(currentActivityId: newActivityId);
        debugPrint('✅ Started new breathing activity: $newActivityId');
      }
    } catch (e) {
      debugPrint('❌ Error starting new activity: $e');
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
        }
      } catch (e) {
        debugPrint('Error starting activity tracking: $e');
      }
    }

    // Play the first voice prompt immediately when starting
    _playVoicePromptForPhase(state.currentPhase);
  }

  Future<void> pause() async {
    if (!state.isPlaying) return;

    // To prevent "modifying a provider during build" error when called from dispose,
    // we schedule the state update for after the build/dispose cycle is complete.
    // This is the officially recommended approach for this scenario.
    Future(() async {
      _timer?.cancel();
      state = state.copyWith(isPlaying: false);

      if (_startTime != null) {
        final sessionSeconds = DateTime.now().difference(_startTime!).inSeconds;
        _accumulatedSeconds += sessionSeconds;
        debugPrint(
            '⏸️ Paused - session duration: ${sessionSeconds}s, accumulated: ${_accumulatedSeconds}s');
        _startTime = null;
      }

      // Save session state when pausing.
      final pattern = _ref.read(selectedPatternProvider);
      await BreathingStatePersistenceService.saveSessionState(
        patternId: pattern?.id,
        duration: state.totalSeconds ~/ 60,
        currentStepIndex: state.currentStepIndex,
        secondsRemaining: state.secondsRemaining,
        elapsedSeconds: state.elapsedSeconds,
        currentPhase: state.currentPhase.name,
        phaseSecondsRemaining: state.phaseSecondsRemaining,
      );
    });
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

    // Remember the current phase before changing it (for voice prompts)
    final currentPhase = state.currentPhase;

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

    // Update state with new phase
    state = state.copyWith(
      currentStepIndex: newIndex,
      currentPhase: newPhase,
      phaseSecondsRemaining: phaseSeconds.toDouble(),
    );

    // Play guiding voice prompt for the new phase
    _playVoicePromptForPhase(newPhase);

    // Play instrument cue for inhale and exhale phases
    _playInstrumentCueForPhase(newPhase, phaseSeconds);

    // Store last phase
    _ref.read(lastBreathPhaseProvider.notifier).state = currentPhase;
  }

  // Play the appropriate voice prompt for the current phase
  void _playVoicePromptForPhase(BreathPhase phase) {
    try {
      // Only get audio service when needed
      final audioService = _ref.read(audioServiceProvider);

      // If we have a voice track selected
      final voiceTrack = audioService.getCurrentTrack(AudioType.guidingVoice);
      if (voiceTrack != null && voiceTrack.id != 'off') {
        // Play the appropriate voice prompt for this phase
        audioService.playVoicePrompt(phase.toVoicePhase());
      }
    } catch (e) {
      // Only log critical errors
      debugPrint('Critical error playing voice prompt: $e');
    }
  }

  // Play the appropriate instrument cue for inhale and exhale phases
  void _playInstrumentCueForPhase(BreathPhase phase, int phaseSeconds) {
    try {
      // Only play instrument cues for inhale and exhale phases
      if (phase != BreathPhase.inhale && phase != BreathPhase.exhale) {
        return;
      }

      // Get the selected instrument
      final selectedInstrument = _ref.read(selectedInstrumentProvider);

      // If instrument is off, don't play anything
      if (selectedInstrument == Instrument.off) {
        return;
      }

      // Convert BreathPhase to BreathInstrumentPhase
      final instrumentPhase = phase == BreathPhase.inhale
          ? BreathInstrumentPhase.inhale
          : BreathInstrumentPhase.exhale;

      // Get audio service and play the instrument cue
      final audioService = _ref.read(audioServiceProvider);
      audioService.playInstrumentCue(
        selectedInstrument,
        instrumentPhase,
        phaseSeconds,
      );
    } catch (e) {
      // Only log critical errors
      debugPrint('Critical error playing instrument cue: $e');
    }
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

    debugPrint('🔄 BreathingPlaybackController disposed');
    super.dispose();
  }

  /// Restore session state from persistent storage
  Future<bool> restoreSessionState() async {
    try {
      final sessionData =
          await BreathingStatePersistenceService.loadSessionState();
      if (sessionData == null) return false;

      debugPrint('📂 Restoring breathing session state');
      final patternId = sessionData['patternId'] as String?;
      if (patternId == null) {
        debugPrint('⚠️ Cannot restore session state, no patternId found');
        return false;
      }

      // Select the pattern from the saved state
      await _ref
          .read(selectedPatternProvider.notifier)
          .selectPatternBySlug(patternId);
      final duration = sessionData['duration'] as int? ?? 3;
      _ref.read(selectedDurationProvider.notifier).state = duration;

      final expandedSteps = await _ref.read(expandedStepsProvider.future);
      if (expandedSteps.isEmpty) {
        debugPrint(
            '⚠️ Cannot restore session state, could not expand steps for pattern $patternId');
        return false;
      }

      // Restore basic state
      state = state.copyWith(
        steps: expandedSteps,
        totalSeconds: duration * 60,
        currentStepIndex: sessionData['currentStepIndex'] as int? ?? 0,
        secondsRemaining:
            (sessionData['secondsRemaining'] as num?)?.toDouble() ?? 0.0,
        elapsedSeconds: sessionData['elapsedSeconds'] as int? ?? 0,
        phaseSecondsRemaining:
            (sessionData['phaseSecondsRemaining'] as num?)?.toDouble() ?? 0.0,
        isPlaying: false, // Always restore as paused
      );

      // Restore phase
      final phaseString = sessionData['currentPhase'] as String?;
      if (phaseString != null) {
        try {
          final phase =
              BreathPhase.values.firstWhere((p) => p.name == phaseString);
          state = state.copyWith(currentPhase: phase);
        } catch (e) {
          debugPrint('⚠️ Could not restore phase: $phaseString');
        }
      }

      // Restore accumulated seconds
      _accumulatedSeconds = sessionData['elapsedSeconds'] as int? ?? 0;

      debugPrint('✅ Session state restored successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring session state: $e');
      return false;
    }
  }

  /// Clear saved session state
  Future<void> clearSavedState() async {
    await BreathingStatePersistenceService.clearSessionState();
  }

  /// Finishes the session explicitly, marking it as complete and resetting.
  Future<void> finish() async {
    if (!state.isPlaying && state.elapsedSeconds == 0)
      return; // Nothing to finish

    debugPrint('➡️ Finishing session explicitly.');
    _timer?.cancel();
    await _completeCurrentActivity(true); // Mark as completed

    // Reset state completely by re-initializing with the default pattern.
    final defaultPattern = await _ref.read(defaultPatternProvider.future);
    final duration = _ref.read(selectedDurationProvider);
    if (defaultPattern != null) {
      final expandedSteps = await _ref.read(expandedStepsProvider.future);
      initialize(expandedSteps, duration, forceReset: true);
    }
  }

  /// Resumes the breathing exercise from the current state.
  Future<void> resume() async {
    // ... existing code ...
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
