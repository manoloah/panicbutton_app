import 'package:flutter/material.dart';
import '../models/metric_config.dart';
import '../widgets/breath_circle.dart';
import '../widgets/wave_animation.dart';

/// An enhanced overlay widget that displays step-by-step instructions for a metric
/// with all 5 parts: Main Text, Support Text, Animation, Next Step Prep, and Call to Action
class MetricInstructionOverlay extends StatefulWidget {
  /// Unique key for this overlay instance to prevent widget reuse
  final String overlayKey;

  /// The current instruction step (0-based index)
  final int instructionStep;

  /// The enhanced instruction steps with all 5 parts
  final List<EnhancedInstructionStep> instructions;

  /// The countdown for timed steps
  final int instructionCountdown;

  /// Callback when the overlay is closed
  final VoidCallback onClose;

  /// Callback to proceed to next instruction
  final VoidCallback onNext;

  /// Callback to start measurement
  final VoidCallback onStartMeasurement;

  /// Animation controller for breath animations
  final Animation<double> breathAnimation;

  const MetricInstructionOverlay({
    super.key,
    required this.overlayKey,
    required this.instructionStep,
    required this.instructions,
    required this.instructionCountdown,
    required this.onClose,
    required this.onNext,
    required this.onStartMeasurement,
    required this.breathAnimation,
  });

  @override
  State<MetricInstructionOverlay> createState() =>
      _MetricInstructionOverlayState();
}

class _MetricInstructionOverlayState extends State<MetricInstructionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _localAnimationController;

  @override
  void initState() {
    super.initState();
    _localAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _localAnimationController.forward();
  }

  @override
  void didUpdateWidget(covariant MetricInstructionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset animation when step changes or overlay key changes
    if (oldWidget.instructionStep != widget.instructionStep ||
        oldWidget.overlayKey != widget.overlayKey) {
      _localAnimationController.reset();
      _localAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _localAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      key: ValueKey('overlay_${widget.overlayKey}'),
      child: Container(
        color: Colors.black.withAlpha((0.9 * 255).toInt()),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),

                  // Instruction content - takes most of the screen
                  Expanded(
                    child: _buildInstructionContent(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get the current instruction (1-based indexing)
    final currentInstruction = widget.instructionStep >= 1 &&
            widget.instructionStep <= widget.instructions.length
        ? widget.instructions[widget.instructionStep - 1]
        : null;

    return AnimatedBuilder(
      animation: _localAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _localAnimationController.value),
          child: Opacity(
            opacity: _localAnimationController.value,
            child: Container(
              key: ValueKey(
                  'instruction_${widget.overlayKey}_${widget.instructionStep}'),
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.8,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main Text (Headline)
                  Text(
                    currentInstruction?.mainText ?? 'Cargando...',
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Support Text (Subtitle)
                  if (currentInstruction?.supportText.isNotEmpty == true)
                    Text(
                      currentInstruction!.supportText,
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface.withAlpha((0.7 * 255).toInt()),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 40),

                  // Main content area - Animation/Image/Countdown
                  Flexible(
                    child: Center(
                      child: _buildMainContent(context, currentInstruction),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Call to Action Button
                  _buildCallToActionButton(context, currentInstruction),

                  const SizedBox(height: 24),

                  // Next Step Prep Text (Simple italic text at bottom)
                  if (currentInstruction?.nextStepPrepText.isNotEmpty == true)
                    Text(
                      '...${currentInstruction!.nextStepPrepText}',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withAlpha((0.6 * 255).toInt()),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent(
      BuildContext context, EnhancedInstructionStep? currentStep) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Timed steps (inhale/exhale) - steps with countdown
    if (currentStep?.isTimedStep == true) {
      return Column(
        key: ValueKey('timed_step_${widget.instructionStep}'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Breathing circle with animation
          BreathCircle(
            onTap: () {}, // Empty tap handler for instruction overlay
            isBreathing: true, // Enable breathing animation
            size: 200,
            phaseIndicator: Stack(
              alignment: Alignment.center,
              children: [
                // Wave animation for breathing effect
                WaveAnimation(
                  waveAnimation: widget.breathAnimation,
                  fillLevel: widget.instructionStep == 2
                      ? widget.breathAnimation.value // Inhale: fill up
                      : 1 - widget.breathAnimation.value, // Exhale: empty out
                ),
                // Countdown display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.primary.withAlpha((0.9 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.instructionCountdown.toString(),
                    style: tt.displayMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.instructionStep == 2 ? 'Inhala...' : 'Exhala...',
            style: tt.headlineSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    // Non-timed steps with icon or image
    else {
      return Column(
        key: ValueKey('static_step_${widget.instructionStep}'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentStep?.imagePath != null)
            Image.asset(
              currentStep!.imagePath!,
              width: 120,
              height: 120,
            )
          else if (currentStep?.icon != null)
            Icon(
              currentStep!.icon,
              size: 120,
              color: cs.primary,
            )
          else
            Icon(
              Icons.info_outline,
              size: 120,
              color: cs.primary,
            ),
        ],
      );
    }
  }

  Widget _buildCallToActionButton(
      BuildContext context, EnhancedInstructionStep? currentStep) {
    final cs = Theme.of(context).colorScheme;

    // Don't show button for timed steps that move automatically OR if callToActionText is empty/None
    if (currentStep?.movesToNextStepAutomatically == true ||
        currentStep?.callToActionText == null ||
        currentStep!.callToActionText.isEmpty ||
        currentStep.callToActionText == 'None') {
      return const SizedBox.shrink();
    }

    String buttonText = currentStep.callToActionText.isNotEmpty
        ? currentStep.callToActionText
        : 'SIGUIENTE';
    VoidCallback? onPressed;

    // Determine button action based on step
    if (widget.instructionStep == 1) {
      // First step - use the callToActionText from CSV (should be "Comenzar")
      buttonText = currentStep.callToActionText.isNotEmpty
          ? currentStep.callToActionText
          : 'COMENZAR';
      onPressed = widget.onNext;
    } else if (widget.instructionStep == widget.instructions.length) {
      // Last step - start measurement
      onPressed = widget.onStartMeasurement;
    } else {
      // Middle steps - next instruction
      onPressed = widget.onNext;
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 280),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: 4,
          shadowColor: cs.shadow.withAlpha((0.3 * 255).toInt()),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
