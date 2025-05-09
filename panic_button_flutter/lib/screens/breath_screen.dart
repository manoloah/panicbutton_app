import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/breath_circle.dart';
import 'package:panic_button_flutter/widgets/duration_selector_button.dart';
import 'package:panic_button_flutter/widgets/goal_pattern_sheet.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';
import 'package:panic_button_flutter/providers/breathing_playback_controller.dart';

class BreathScreen extends ConsumerStatefulWidget {
  final String? patternSlug;
  final bool autoStart;

  const BreathScreen({
    super.key,
    this.patternSlug,
    this.autoStart = false,
  });

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
      _initializePattern();
    });
  }

  Future<void> _initializePattern() async {
    try {
      if (widget.patternSlug != null) {
        // If a patternSlug is provided, select the pattern by slug first
        await ref
            .read(selectedPatternProvider.notifier)
            .selectPatternBySlug(widget.patternSlug!);

        // Get expanded steps for the selected pattern
        final expandedSteps = await ref.read(expandedStepsProvider.future);
        final duration = ref.read(selectedDurationProvider);

        if (expandedSteps.isNotEmpty) {
          // Initialize the playback controller with the steps
          ref
              .read(breathingPlaybackControllerProvider.notifier)
              .initialize(expandedSteps, duration);

          // Auto-start only if explicitly requested (coming from home screen)
          if (widget.autoStart) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(breathingPlaybackControllerProvider.notifier).play();
            });
          }

          setState(() {
            _isInitialized = true;
          });
          return;
        }
      }

      // Fallback to default pattern if slug not provided or pattern not found
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
        }
      }

      setState(() {
        _isInitialized = true; // Still mark as initialized to show UI
      });
    } catch (e) {
      debugPrint('Error initializing pattern: $e');
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

  // Navigate back to the journey screen
  void _navigateToJourney() {
    // Use Go Router to navigate back to the journey screen
    context.go('/journey');
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
    const bottomNavHeight = 56.0; // Standard navbar height
    final viewPadding = MediaQuery.of(context).padding;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToJourney,
        ),
        title: null,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
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
                        viewPadding.bottom -
                        kToolbarHeight, // Account for AppBar height
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Breathing circle centered
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: BreathCircle(
                            onTap: _toggleBreathing,
                            phaseIndicator: const Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleWaveOverlay(),
                                PhaseCountdownDisplay(),
                              ],
                            ),
                          ),
                        ),

                        // Timer display
                        _buildTimerDisplay(playbackState),

                        // Control buttons row wrapped for better layout on small screens
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildControlsRow(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Fixed navbar at the bottom spanning full width
            const SizedBox(
              width: double.infinity,
              child: CustomNavBar(currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(BreathingPlaybackState playbackState) {
    // Ensure we don't show negative time
    final totalSeconds =
        playbackState.secondsRemaining > 0 ? playbackState.secondsRemaining : 0;

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds.floor() % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.displayMedium,
      ),
    );
  }

  Widget _buildControlsRow() {
    final cs = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    // Get the current selected pattern
    final pattern = ref.watch(selectedPatternProvider);
    final patternName = pattern?.name ?? 'Seleccionar patrón';

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        // Duration selector button
        const DurationSelectorButton(),

        // Row with play button and pattern selector
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/pause button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildPlayPauseButton(),
            ),

            // Pattern selector button
            TextButton.icon(
              onPressed: () => showGoalPatternSheet(context),
              style: TextButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 14,
                    vertical: isSmallScreen ? 8 : 10),
                elevation: 4,
                shadowColor: cs.shadow.withOpacity(0.5),
                side: BorderSide(
                  color: cs.primary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              icon: Icon(Icons.air,
                  size: isSmallScreen ? 24 : 30, color: cs.onPrimaryContainer),
              label: Text(
                patternName,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onPrimaryContainer,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton() {
    final isPlaying = ref.watch(breathingPlaybackControllerProvider).isPlaying;
    final cs = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    // Use a regular material button instead of FloatingActionButton
    return ElevatedButton(
      onPressed: _toggleBreathing,
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        shape: const CircleBorder(),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        elevation: 4,
      ),
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: isSmallScreen ? 24 : 32,
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
