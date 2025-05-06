import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:panic_button_flutter/widgets/breath_circle.dart';
import 'package:panic_button_flutter/widgets/duration_selector_button.dart';
import 'package:panic_button_flutter/widgets/goal_pattern_sheet.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';
import 'package:panic_button_flutter/providers/breathing_playback_controller.dart';

class BreathScreen extends ConsumerStatefulWidget {
  const BreathScreen({super.key});

  @override
  ConsumerState<BreathScreen> createState() => _BreathScreenState();
}

class _BreathScreenState extends ConsumerState<BreathScreen> {
  bool _isInitialized = false;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    // Delay initialization to allow proper provider setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDefaultPattern();
    });
  }

  Future<void> _initializeDefaultPattern() async {
    try {
      // First, get and select a default pattern
      final defaultPattern = await ref.read(defaultPatternProvider.future);
      if (defaultPattern != null) {
        // Set this as the selected pattern
        ref.read(selectedPatternProvider.notifier).state = defaultPattern;

        // Now get expanded steps for this pattern
        final expandedSteps = await ref.read(expandedStepsProvider.future);
        final duration = ref.read(selectedDurationProvider);

        if (expandedSteps.isNotEmpty) {
          // Initialize the playback controller with the steps
          ref
              .read(breathingPlaybackControllerProvider.notifier)
              .initialize(expandedSteps, duration);

          setState(() {
            _isInitialized = true;
          });
        } else {
          setState(() {
            _isInitialized = true; // Still mark as initialized to show UI
          });
        }
      } else {
        setState(() {
          _isInitialized = true; // Still mark as initialized to show UI
        });
      }
    } catch (e) {
      setState(() {
        _isInitialized = true; // Still mark as initialized to show UI
      });
    }
  }

  // Update breathing controller with the current pattern and duration
  Future<void> _updateBreathingController() async {
    final controller = ref.read(breathingPlaybackControllerProvider.notifier);
    final wasPlaying = ref.read(breathingPlaybackControllerProvider).isPlaying;

    // Pause if playing
    if (wasPlaying) {
      controller.pause();
    }

    // Get expanded steps for the currently selected pattern
    final expandedSteps = await ref.read(expandedStepsProvider.future);
    final duration = ref.read(selectedDurationProvider);

    if (expandedSteps.isNotEmpty) {
      // Initialize controller with new pattern and duration
      controller.initialize(expandedSteps, duration);

      // Resume playback if it was playing before
      if (wasPlaying) {
        controller.play();
      }
    }
  }

  // Add this function to properly update when selecting a pattern from the sheet
  void showGoalPatternSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoalPatternSheet(),
    ).then((_) {
      // This will be called when the sheet is closed
      // We need to update the controller to use the newly selected pattern
      _updateBreathingController();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(breathingPlaybackControllerProvider);
    final tt = Theme.of(context).textTheme;

    // Setup listeners in the build method
    if (_isFirstBuild) {
      // Only add these listeners once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Setup pattern change listener
        ref.listenManual(selectedPatternProvider, (previous, next) {
          if (next != null && _isInitialized) {
            _updateBreathingController();
          }
        });

        // Setup duration change listener
        ref.listenManual(selectedDurationProvider, (previous, next) {
          if (_isInitialized) {
            _updateBreathingController();
          }
        });

        _isFirstBuild = false;
      });
    }

    // Show loading indicator while initializing
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('PanicButton', style: tt.displayLarge),
                const SizedBox(height: 40),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('Cargando ejercicios...', style: tt.bodyLarge),
              ],
            ),
          ),
        ),
      );
    }

    // Get device dimensions
    final bottomNavHeight = 56.0; // Standard navbar height
    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        // Completely restructured layout for better centering
        child: Column(
          children: [
            // This is the scrollable main content area
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        bottomNavHeight -
                        viewPadding.top -
                        viewPadding.bottom,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          Text(
                            'PanicButton',
                            style: tt.displayLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Breathing circle
                          BreathCircle(
                            onTap: _toggleBreathing,
                            phaseIndicator: const Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleWaveOverlay(),
                                PhaseCountdownDisplay(),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Timer display
                          _buildTimerDisplay(playbackState),

                          const SizedBox(height: 20),

                          // Control buttons row
                          _buildControlsRow(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Fixed navbar at the bottom spanning full width
            Container(
              width: double.infinity,
              child: const CustomNavBar(currentIndex: 1),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildPlayPauseButton(),
    );
  }

  Widget _buildTimerDisplay(BreathingPlaybackState playbackState) {
    // Ensure we don't show negative time
    final totalSeconds =
        playbackState.secondsRemaining > 0 ? playbackState.secondsRemaining : 0;

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds.floor() % 60;

    return Text(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: Theme.of(context).textTheme.displayMedium,
    );
  }

  Widget _buildControlsRow() {
    final cs = Theme.of(context).colorScheme;

    // Get the current selected pattern
    final pattern = ref.watch(selectedPatternProvider);
    final patternName = pattern?.name ?? 'Seleccionar patrón';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // Duration selector
          const DurationSelectorButton(),

          // Pattern selector button
          TextButton.icon(
            onPressed: () => showGoalPatternSheet(context),
            style: TextButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.air, size: 20),
            label: Text(
              patternName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    final isPlaying = ref.watch(breathingPlaybackControllerProvider).isPlaying;
    final cs = Theme.of(context).colorScheme;

    return FloatingActionButton(
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      onPressed: _toggleBreathing,
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 32,
      ),
    );
  }

  void _toggleBreathing() {
    final controller = ref.read(breathingPlaybackControllerProvider.notifier);
    final isPlaying = ref.read(breathingPlaybackControllerProvider).isPlaying;
    final expandedSteps = ref.read(expandedStepsProvider).value ?? [];

    if (isPlaying) {
      controller.pause();
    } else {
      if (expandedSteps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un patrón primero'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Show the pattern selector sheet
        showGoalPatternSheet(context);
        return;
      }

      // Check if we're resuming an existing session or starting a new one
      final playbackState = ref.read(breathingPlaybackControllerProvider);
      final hasExistingSession = playbackState.currentActivityId != null;

      if (!hasExistingSession) {
        // Only initialize when starting a new session, not when resuming
        final duration = ref.read(selectedDurationProvider);
        controller.initialize(expandedSteps, duration);
      }

      // Always call play
      controller.play();
    }
  }
}
