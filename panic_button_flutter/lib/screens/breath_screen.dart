import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/widgets/breath_circle.dart';
import 'package:panic_button_flutter/widgets/duration_selector_button.dart';
import 'package:panic_button_flutter/widgets/goal_pattern_sheet.dart';
import 'package:panic_button_flutter/widgets/custom_nav_bar.dart';
import 'package:panic_button_flutter/providers/breathing_providers.dart';
import 'package:panic_button_flutter/providers/breathing_playback_controller.dart';
import 'package:panic_button_flutter/widgets/delayed_loading_animation.dart';
import 'package:panic_button_flutter/widgets/audio_selection_sheet.dart';
import 'package:panic_button_flutter/services/audio_service.dart';

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
  bool _isAudioInitialized = false;
  bool _isDisposed = false;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    // Delay initialization to allow proper provider setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        // Store audio service reference early
        try {
          _audioService = ref.read(audioServiceProvider);
        } catch (e) {
          debugPrint(
              'Error accessing audioServiceProvider during initState: $e');
        }
        _initializePattern();
      }
    });
  }

  @override
  void dispose() {
    // Mark as disposed first
    _isDisposed = true;

    // Call super.dispose() to properly cleanup widget resources
    super.dispose();

    // Then stop audio using the saved reference
    try {
      if (_audioService != null) {
        _audioService!.stopAllAudio();
      }
    } catch (e) {
      debugPrint('Error stopping audio during dispose: $e');
    }
  }

  Future<void> _initializePattern() async {
    try {
      if (_isDisposed) return;

      // Get all notifiers we'll need before any async operations
      final selectedPatternNotifier =
          ref.read(selectedPatternProvider.notifier);
      final playbackController =
          ref.read(breathingPlaybackControllerProvider.notifier);

      if (widget.patternSlug != null) {
        // If a patternSlug is provided, select the pattern by slug first
        await selectedPatternNotifier.selectPatternBySlug(widget.patternSlug!);

        if (_isDisposed) return;

        // Get expanded steps for the selected pattern
        final expandedSteps = await ref.read(expandedStepsProvider.future);

        if (_isDisposed) return;
        final duration = ref.read(selectedDurationProvider);

        if (_isDisposed) return;

        if (expandedSteps.isNotEmpty) {
          // Initialize the playback controller with the steps
          playbackController.initialize(expandedSteps, duration);

          // Auto-start only if explicitly requested (coming from home screen)
          if (widget.autoStart) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_isDisposed) return;

              playbackController.play();

              // Start default background music if user hasn't selected anything yet
              _initializeAudio();
            });
          }

          if (!_isDisposed) {
            setState(() {
              _isInitialized = true;
            });
          }
          return;
        }
      }

      // Fallback to default pattern if slug not provided or pattern not found
      final defaultPattern = await ref.read(defaultPatternProvider.future);

      if (_isDisposed) return;

      if (defaultPattern != null) {
        // Set this as the selected pattern
        selectedPatternNotifier.state = defaultPattern;

        // Now get expanded steps for this pattern
        final expandedSteps = await ref.read(expandedStepsProvider.future);

        if (_isDisposed) return;
        final duration = ref.read(selectedDurationProvider);

        if (_isDisposed) return;

        if (expandedSteps.isNotEmpty) {
          // Initialize the playback controller with the steps
          playbackController.initialize(expandedSteps, duration);
        }
      }

      if (!_isDisposed) {
        setState(() {
          _isInitialized = true; // Still mark as initialized to show UI
        });
      }
    } catch (e) {
      debugPrint('Error initializing pattern: $e');
      if (!_isDisposed) {
        setState(() {
          _isInitialized = true; // Still mark as initialized to show UI
        });
      }
    }
  }

  // Initialize audio (only once)
  void _initializeAudio() {
    if (_isDisposed) return;

    if (!_isAudioInitialized) {
      // Set default background music if none is playing
      final currentMusic =
          _audioService?.getCurrentTrack(AudioType.backgroundMusic);
      if (currentMusic == null) {
        // Start river as default background music
        ref
            .read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
            .selectTrack('river');
      }

      // Set default breathing tone if none is playing
      final currentTone = _audioService?.getCurrentTrack(AudioType.breathGuide);
      if (currentTone == null) {
        // Start sine as default tone
        ref
            .read(selectedAudioProvider(AudioType.breathGuide).notifier)
            .selectTrack('sine');
      }

      // Set default guiding voice if none is playing
      final currentVoice =
          _audioService?.getCurrentTrack(AudioType.guidingVoice);
      if (currentVoice == null) {
        // Start manu as default voice
        ref
            .read(selectedAudioProvider(AudioType.guidingVoice).notifier)
            .selectTrack('manu');
      }

      _isAudioInitialized = true;
    }
  }

  // Show the audio selection sheet
  void _showAudioSelectionSheet(BuildContext context) {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AudioSelectionSheet(),
    );
  }

  // Update breathing controller with the current pattern and duration
  Future<void> _updateBreathingController() async {
    if (_isDisposed) return;

    // Store local references to avoid accessing ref after widget disposal
    final controller = ref.read(breathingPlaybackControllerProvider.notifier);
    final wasPlaying = ref.read(breathingPlaybackControllerProvider).isPlaying;
    final expandedStepsFuture = ref.read(expandedStepsProvider.future);
    final duration = ref.read(selectedDurationProvider);

    // Pause if playing
    if (wasPlaying) {
      controller.pause();
    }

    try {
      // Get expanded steps for the currently selected pattern
      final expandedSteps = await expandedStepsFuture;

      // Check if widget is still mounted before continuing
      if (_isDisposed) return;

      if (expandedSteps.isNotEmpty) {
        // Initialize controller with new pattern and duration
        controller.initialize(expandedSteps, duration);

        // Resume playback if it was playing before
        if (wasPlaying) {
          controller.play();
        }
      }
    } catch (e) {
      debugPrint('Error updating breathing controller: $e');
    }
  }

  // Add this function to properly update when selecting a pattern from the sheet
  void showGoalPatternSheet(BuildContext context) {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoalPatternSheet(),
    ).then((_) {
      // This will be called when the sheet is closed
      // We need to update the controller to use the newly selected pattern
      if (!_isDisposed) {
        _updateBreathingController();
      }
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
    final cs = Theme.of(context).colorScheme;

    // Setup listeners in the build method
    if (_isFirstBuild && !_isDisposed) {
      // Only add these listeners once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed) return;

        // Setup pattern change listener
        ref.listenManual(selectedPatternProvider, (previous, next) {
          if (_isDisposed) return;
          if (next != null && _isInitialized) {
            _updateBreathingController();
          }
        });

        // Setup duration change listener
        ref.listenManual(selectedDurationProvider, (previous, next) {
          if (_isDisposed) return;
          if (_isInitialized) {
            _updateBreathingController();
          }
        });

        // Setup breathing playback state listener for audio control
        ref.listenManual(breathingPlaybackControllerProvider, (previous, next) {
          if (_isDisposed) return;
          // Start audio when exercise starts
          if (previous != null && !previous.isPlaying && next.isPlaying) {
            _initializeAudio();
          }
        });

        _isFirstBuild = false;
      });
    }

    // Show loading indicator while initializing
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const SafeArea(
          child: DelayedLoadingAnimation(
            loadingText: 'Cargando ejercicios...',
            showQuote: true,
            delayMilliseconds: 500,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Custom app bar with music button
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: cs.surface,
              elevation: 0,
              leadingWidth: 56,
              leading: IconButton(
                icon: Icon(
                  Icons.music_note,
                  color: cs.onSurface,
                  size: 24,
                ),
                onPressed: () => _showAudioSelectionSheet(context),
                tooltip: 'Audio settings',
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: cs.onSurface,
                    size: 24,
                  ),
                  onPressed: _navigateToJourney,
                  tooltip: 'Back to journey',
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: cs.onSurface,
                    size: 24,
                  ),
                  onPressed: () {
                    context.go('/settings');
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
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
                      // Control buttons with better layout
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24, top: 16),
                        child: _buildControlsLayout(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
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

  // Reorganized layout for controls following the correct hierarchy
  Widget _buildControlsLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play button centered - primary action (#1 in hierarchy)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildPlayPauseButton(),
          ),

          // Pattern selector button (#2 in hierarchy)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPatternButton(),
          ),

          // Duration selector button (#3 in hierarchy)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDurationButton(),
          ),
        ],
      ),
    );
  }

  // Play/pause button - primary action
  Widget _buildPlayPauseButton() {
    final isPlaying = ref.watch(breathingPlaybackControllerProvider).isPlaying;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return ElevatedButton(
      onPressed: _toggleBreathing,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        elevation: 4,
      ),
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: isSmallScreen ? 32 : 40,
      ),
    );
  }

  // Pattern selector button - uses new 3D secondary button style
  Widget _buildPatternButton() {
    final pattern = ref.watch(selectedPatternProvider);
    final patternName = pattern?.name ?? 'Seleccionar patrón';
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? 280 : 350,
      ),
      child: TextButton.icon(
        onPressed: () => showGoalPatternSheet(context),
        style: Theme.of(context).outlinedButtonTheme.style,
        icon: const Icon(
          Icons.air,
          size: 24,
        ),
        label: Text(
          patternName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  // Duration selector - uses the DurationSelectorButton to preserve functionality
  Widget _buildDurationButton() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    // Using a container to apply custom styling to the DurationSelectorButton
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? 280 : 350,
      ),
      child: const DurationSelectorButton(),
    );
  }

  void _toggleBreathing() {
    if (_isDisposed) return;

    // Get all references we need upfront to avoid using ref after disposal
    final controller = ref.read(breathingPlaybackControllerProvider.notifier);
    final playbackState = ref.read(breathingPlaybackControllerProvider);
    final isPlaying = playbackState.isPlaying;
    final expandedSteps = ref.read(expandedStepsProvider).value ?? [];
    final hasExistingSession = playbackState.currentActivityId != null;
    final duration = ref.read(selectedDurationProvider);

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
      if (!hasExistingSession) {
        // Only initialize when starting a new session, not when resuming
        controller.initialize(expandedSteps, duration);
      }

      // Always call play
      controller.play();

      // Start background music if it's not already playing
      _initializeAudio();
    }
  }
}
