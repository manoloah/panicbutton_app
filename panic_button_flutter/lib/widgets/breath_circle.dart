import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/providers/breathing_playback_controller.dart';
import 'package:panic_button_flutter/widgets/wave_animation.dart';
import 'dart:math' as math;

class BreathCircle extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  final Widget? phaseIndicator;
  final bool isBreathing;
  final double size;

  const BreathCircle({
    super.key,
    required this.onTap,
    this.phaseIndicator,
    this.isBreathing = false,
    this.size = 240,
  });

  @override
  ConsumerState<BreathCircle> createState() => _BreathCircleState();
}

class _BreathCircleState extends ConsumerState<BreathCircle> {
  String? _lastActivityId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final playbackState = ref.watch(breathingPlaybackControllerProvider);

    // Reset tracking when activity changes
    if (playbackState.currentActivityId != _lastActivityId) {
      _lastActivityId = playbackState.currentActivityId;
      debugPrint('🔄 Activity changed - reset tracking');
    }

    // Calculate animation scale
    final screenSize = MediaQuery.of(context).size;
    final maxScaleFactor = screenSize.width < 360 ? 1.2 : 1.25;
    double scaleFactor = _calculateScaleFactor(playbackState, maxScaleFactor);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scaleFactor,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primary,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withAlpha(76),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: widget.phaseIndicator ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Get duration for a specific phase
  int _getPhaseDuration(BreathPhase phase, dynamic step) {
    switch (phase) {
      case BreathPhase.inhale:
        return step.inhaleSecs as int;
      case BreathPhase.holdIn:
        return step.holdInSecs as int;
      case BreathPhase.exhale:
        return step.exhaleSecs as int;
      case BreathPhase.holdOut:
        return step.holdOutSecs as int;
    }
  }

  /// Calculate scale factor for animation
  double _calculateScaleFactor(
      BreathingPlaybackState playbackState, double maxScaleFactor) {
    if (!playbackState.isPlaying && !widget.isBreathing) {
      return 1.0;
    }

    if (playbackState.currentStep == null) return 1.0;

    final totalPhaseSeconds = _getPhaseDuration(
        playbackState.currentPhase, playbackState.currentStep!);
    final progress = totalPhaseSeconds > 0
        ? 1.0 - (playbackState.phaseSecondsRemaining / totalPhaseSeconds)
        : 0.0;

    final easedProgress = _applyCubicEasing(progress);

    switch (playbackState.currentPhase) {
      case BreathPhase.inhale:
        return 1.0 + ((maxScaleFactor - 1.0) * easedProgress);
      case BreathPhase.holdIn:
        return maxScaleFactor + (0.02 * math.sin(progress * math.pi * 2));
      case BreathPhase.exhale:
        return maxScaleFactor - ((maxScaleFactor - 1.0) * easedProgress);
      case BreathPhase.holdOut:
        return 1.0 + (0.01 * math.sin(progress * math.pi * 2));
    }
  }

  /// Apply cubic easing for smooth transitions
  double _applyCubicEasing(double progress) {
    if (progress < 0.5) {
      return 4 * progress * progress * progress;
    } else {
      final f = ((2 * progress) - 2);
      return 0.5 * f * f * f + 1;
    }
  }
}

class CircleWaveOverlay extends ConsumerStatefulWidget {
  const CircleWaveOverlay({super.key});

  @override
  ConsumerState<CircleWaveOverlay> createState() => _CircleWaveOverlayState();
}

class _CircleWaveOverlayState extends ConsumerState<CircleWaveOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveAnimationController;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _waveAnimationController.repeat();
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(breathingPlaybackControllerProvider);

    double fillLevel = 0.5; // Default to half-full

    if (playbackState.isPlaying && playbackState.currentStep != null) {
      final totalPhaseSeconds = _getTotalPhaseSeconds(playbackState);
      final progress = totalPhaseSeconds > 0
          ? 1.0 - (playbackState.phaseSecondsRemaining / totalPhaseSeconds)
          : 0.0;

      switch (playbackState.currentPhase) {
        case BreathPhase.inhale:
          fillLevel = progress;
          break;
        case BreathPhase.holdIn:
          fillLevel = 1.0;
          break;
        case BreathPhase.exhale:
          fillLevel = 1.0 - progress;
          break;
        case BreathPhase.holdOut:
          fillLevel = 0.0;
          break;
      }
    }

    return WaveAnimation(
      waveAnimation: _waveAnimationController,
      fillLevel: fillLevel,
    );
  }

  int _getTotalPhaseSeconds(BreathingPlaybackState state) {
    if (state.currentStep == null) return 0;

    switch (state.currentPhase) {
      case BreathPhase.inhale:
        return state.currentStep!.inhaleSecs;
      case BreathPhase.holdIn:
        return state.currentStep!.holdInSecs;
      case BreathPhase.exhale:
        return state.currentStep!.exhaleSecs;
      case BreathPhase.holdOut:
        return state.currentStep!.holdOutSecs;
    }
  }
}

class PhaseCountdownDisplay extends ConsumerWidget {
  const PhaseCountdownDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final playbackState = ref.watch(breathingPlaybackControllerProvider);
    final phaseText = ref.watch(breathingPhaseTextProvider);

    final displaySeconds = playbackState.phaseSecondsRemaining > 0
        ? playbackState.phaseSecondsRemaining.ceil()
        : 0;

    final screenSize = MediaQuery.of(context).size;
    final headlineMediumStyle = tt.headlineMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: screenSize.width < 360 ? 20 : 24,
    );

    final headlineLargeStyle = tt.headlineLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w400,
      fontSize: screenSize.width < 360 ? 28 : 34,
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            phaseText,
            textAlign: TextAlign.center,
            style: headlineMediumStyle,
          ),
          if (playbackState.isPlaying) ...[
            const SizedBox(height: 8),
            Text(
              displaySeconds.toString(),
              textAlign: TextAlign.center,
              style: headlineLargeStyle,
            ),
          ],
        ],
      ),
    );
  }
}
