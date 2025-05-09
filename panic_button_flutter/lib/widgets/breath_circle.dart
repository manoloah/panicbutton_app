import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/providers/breathing_playback_controller.dart';
import 'package:panic_button_flutter/widgets/wave_animation.dart';
import 'dart:math' as math;

class BreathCircle extends ConsumerWidget {
  final VoidCallback onTap;
  final Widget? phaseIndicator;
  final bool isBreathing; // Added to support simplified usage
  final double size; // Added for flexible sizing

  const BreathCircle({
    super.key,
    required this.onTap,
    this.phaseIndicator,
    this.isBreathing = false, // Default to false for backward compatibility
    this.size = 240, // Reduced from 280 to 240
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final playbackState = ref.watch(breathingPlaybackControllerProvider);

    // Get screen size to adjust scaling based on device
    final screenSize = MediaQuery.of(context).size;
    // Adjust scaling factors for smaller screens
    final maxScaleFactor = screenSize.width < 360 ? 1.2 : 1.25;

    // Calculate scale factor based on current phase
    double scaleFactor = 1.0;
    double opacity = 1.0;

    // Only animate when playing or specifically requested via isBreathing
    if ((playbackState.isPlaying && playbackState.currentStep != null) ||
        isBreathing) {
      final totalPhaseSeconds = _getTotalPhaseSeconds(playbackState);
      final progress = totalPhaseSeconds > 0
          ? 1.0 - (playbackState.phaseSecondsRemaining / totalPhaseSeconds)
          : 0.0;

      // Apply easing to progress for more natural movement
      // Using a custom easing function to make transitions softer
      final easedProgress = _applyCubicEasing(progress);

      switch (playbackState.currentPhase) {
        case BreathPhase.inhale:
          // Scale from 1.0 to maxScaleFactor during inhale with eased transition
          scaleFactor = 1.0 + ((maxScaleFactor - 1.0) * easedProgress);
          break;
        case BreathPhase.holdIn:
          // Subtle pulsing animation during hold for more organic feel
          scaleFactor =
              maxScaleFactor + (0.02 * math.sin(progress * math.pi * 2));
          break;
        case BreathPhase.exhale:
          // Scale from maxScaleFactor back to 1.0 during exhale with eased transition
          scaleFactor =
              maxScaleFactor - ((maxScaleFactor - 1.0) * easedProgress);
          break;
        case BreathPhase.holdOut:
          // Subtle pulsing animation during hold out for more organic feel
          scaleFactor = 1.0 + (0.01 * math.sin(progress * math.pi * 2));
          break;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: scaleFactor,
        duration: const Duration(
            milliseconds: 200), // Slightly longer for smoother transitions
        curve: Curves.easeInOutCubic, // More natural curve for breathing
        child: Container(
          width: size,
          height: size,
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
          child: AnimatedOpacity(
            opacity: opacity,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: phaseIndicator ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  // Helper function to apply cubic easing for smoother transitions
  double _applyCubicEasing(double progress) {
    // Slow at start, faster in middle, slow at end
    if (progress < 0.5) {
      return 4 * progress * progress * progress;
    } else {
      final f = ((2 * progress) - 2);
      return 0.5 * f * f * f + 1;
    }
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
    // Create a slow-moving wave controller that continuously animates
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
          seconds: 12), // Slower wave movement for more natural flow
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

    // Calculate fill level based on breathing phase
    double fillLevel = 0.0;

    if (playbackState.isPlaying && playbackState.currentStep != null) {
      final totalPhaseSeconds = _getTotalPhaseSeconds(playbackState);
      final progress = totalPhaseSeconds > 0
          ? 1.0 - (playbackState.phaseSecondsRemaining / totalPhaseSeconds)
          : 0.0;

      switch (playbackState.currentPhase) {
        case BreathPhase.inhale:
          // Start at completely empty (0.0) and fill to 1.0
          fillLevel = progress;
          break;
        case BreathPhase.holdIn:
          fillLevel = 1.0; // Full
          break;
        case BreathPhase.exhale:
          // Go from full (1.0) to empty (0.0)
          fillLevel = 1.0 - progress;
          break;
        case BreathPhase.holdOut:
          fillLevel = 0.0; // Completely empty
          break;
      }
    } else {
      // When not playing, show a half-full gentle wave
      fillLevel = 0.5;
    }

    // Use the WaveAnimation widget with our fillLevel
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

    // Calculate phase seconds to display (ceiling to avoid showing 0 too early)
    final displaySeconds = playbackState.phaseSecondsRemaining > 0
        ? playbackState.phaseSecondsRemaining.ceil()
        : 0;

    // Adjust text size based on screen size
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
