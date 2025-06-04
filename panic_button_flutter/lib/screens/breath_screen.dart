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
import 'package:panic_button_flutter/models/breath_models.dart';

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
          // Set default audio selections immediately
          _setDefaultAudioIfNeeded();
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

  // Method to ensure default audio options are set
  void _setDefaultAudioIfNeeded() {
    if (_isDisposed) return;

    try {
      // Set default guiding voice if none is selected
      final currentVoice =
          ref.read(selectedAudioProvider(AudioType.guidingVoice));
      if (currentVoice == null || currentVoice.isEmpty) {
        ref
            .read(selectedAudioProvider(AudioType.guidingVoice).notifier)
            .selectTrack('manu');
      }

      // Set default background music if none is selected
      final currentMusic =
          ref.read(selectedAudioProvider(AudioType.backgroundMusic));
      if (currentMusic == null || currentMusic.isEmpty) {
        ref
            .read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
            .selectTrack('river');
      }

      // Set default instrument if none is selected (gong is default)
      final currentInstrument = ref.read(selectedInstrumentProvider);
      if (currentInstrument == Instrument.off) {
        ref
            .read(selectedInstrumentProvider.notifier)
            .selectInstrument(Instrument.gong);
      }
    } catch (e) {
      debugPrint('Error setting default audio options: $e');
    }
  }

  // Modify the existing _initializeAudio method to use the new method
  void _initializeAudio() {
    if (_isDisposed) return;

    if (!_isAudioInitialized) {
      // Set all default audio options if needed
      _setDefaultAudioIfNeeded();
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

    // Save current audio selections before making changes
    final currentMusicTrackId =
        ref.read(selectedAudioProvider(AudioType.backgroundMusic));
    final currentVoiceTrackId =
        ref.read(selectedAudioProvider(AudioType.guidingVoice));
    final currentInstrument = ref.read(selectedInstrumentProvider);

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

        // Restore the audio track selections
        if (currentMusicTrackId != null && currentMusicTrackId.isNotEmpty) {
          ref
              .read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
              .selectTrack(currentMusicTrackId);
        }

        if (currentVoiceTrackId != null && currentVoiceTrackId.isNotEmpty) {
          ref
              .read(selectedAudioProvider(AudioType.guidingVoice).notifier)
              .selectTrack(currentVoiceTrackId);
        }

        // Restore the instrument selection
        ref
            .read(selectedInstrumentProvider.notifier)
            .selectInstrument(currentInstrument);

        // Resume playback if it was playing before
        if (wasPlaying) {
          controller.play();
        }
      }
    } catch (e) {
      debugPrint('Error updating breathing controller: $e');
    }
  }

  // Add this function to open the pattern sheet with height constraints
  void _openGoalPatternSheet(BuildContext context) {
    if (_isDisposed) return;

    // Use the shared helper from goal_pattern_sheet.dart so the bottom sheet
    // never exceeds roughly 70% of the screen height.
    showGoalPatternSheet(context).then((_) {
      // Update the controller when the sheet is closed
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

        // Ensure default audio is set when returning to screen
        _setDefaultAudioIfNeeded();

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
                          onTap: () => _toggleBreathing(),
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
      onPressed: () => _toggleBreathing(),
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
        onPressed: () => _openGoalPatternSheet(context),
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

  Future<void> _toggleBreathing() async {
    if (_isDisposed) return;

    // Get all references we need upfront to avoid using ref after disposal
    final controller = ref.read(breathingPlaybackControllerProvider.notifier);
    final playbackState = ref.read(breathingPlaybackControllerProvider);
    final isPlaying = playbackState.isPlaying;
    final stepsAsync = ref.read(expandedStepsProvider);
    List<ExpandedStep> expandedSteps;
    if (stepsAsync.hasValue) {
      expandedSteps = stepsAsync.value ?? [];
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando patrón...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1500),
        ),
      );
      expandedSteps = await ref.read(expandedStepsProvider.future);
      if (_isDisposed) return;
    }
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
        _openGoalPatternSheet(context);
        return;
      }

      // First initialize audio before starting the exercise
      _initializeAudio();

      // Small delay to ensure audio is preloaded before starting the first breathe
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isDisposed) return;

        // Check if we're resuming an existing session or starting a new one
        if (!hasExistingSession) {
          // Only initialize when starting a new session, not when resuming
          controller.initialize(expandedSteps, duration);
        }

        // Always call play
        controller.play();
      });
    }
  }
}
