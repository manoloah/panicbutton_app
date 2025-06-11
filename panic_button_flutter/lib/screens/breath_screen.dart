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
import 'package:provider/provider.dart';
import 'package:panic_button_flutter/providers/journey_provider.dart';
import 'package:panic_button_flutter/models/breath_models.dart';
import 'package:panic_button_flutter/main.dart'; // Import for routeObserver

// --- SESSION STATE ENUM ---
enum BreathingSessionState {
  notStarted,
  playing,
  paused,
  finished,
}


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

class _BreathScreenState extends ConsumerState<BreathScreen> with RouteAware {
  bool _isInitialized = false;
  bool _isFirstBuild = true;
  bool _isAudioInitialized = false;
  bool _isDisposed = false;
  AudioService? _audioService;
  BreathingSessionState _sessionState = BreathingSessionState.notStarted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes for auto-pausing
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    // Mark as disposed first to prevent any further operations
    _isDisposed = true;

    // Unsubscribe from route observer
    try {
      routeObserver.unsubscribe(this);
    } catch (e) {
      debugPrint('Error unsubscribing from route observer: $e');
    }

    super.dispose();
  }

  /// Called when the screen is left, e.g., by pushing a new screen on top.
  @override
  void didPushNext() {
    _pauseSessionOnLeave();
  }

  /// Called when navigating back to this screen.
  @override
  void didPopNext() {
    // No action needed on return, session should remain paused
    // until the user explicitly resumes it.
  }

  /// Pauses the session and stops all audio.
  /// This is called when the user navigates away from the screen.
  void _pauseSessionOnLeave() {
    // Use Future.microtask to defer state update and prevent provider modification errors
    Future.microtask(() {
      if (_isDisposed || !mounted) return;

      if (_sessionState == BreathingSessionState.playing) {
        try {
          final controller =
              ref.read(breathingPlaybackControllerProvider.notifier);
          controller.pause(); // Pause the controller
          _audioService?.stopAllAudio(); // Stop all audio

          // This setState is now safe within the microtask
          if (mounted) {
            setState(() {
              _sessionState = BreathingSessionState.paused;
            });
          }
        } catch (e) {
          debugPrint('Error pausing session during navigation: $e');
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Delay initialization to allow proper provider setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed) return;

      // --- PERSISTENT SESSION LOGIC ---
      // Check if a session is already active (e.g., user navigated back)
      final existingState = ref.read(breathingPlaybackControllerProvider);
      if (existingState.currentActivityId != null &&
          existingState.secondsRemaining > 0) {
        // A session is in progress, restore the UI in a paused state
        setState(() {
          _sessionState = BreathingSessionState.paused;
          _isInitialized = true;
          _audioService = ref.read(audioServiceProvider);
        });
        return; // Skip re-initialization
      }

      // --- STANDARD INITIALIZATION ---
      // No active session, proceed with normal setup.
      try {
        _audioService = ref.read(audioServiceProvider);
        // Set default audio selections immediately
        _setDefaultAudioIfNeeded();
      } catch (e) {
        debugPrint('Error accessing audioServiceProvider during initState: $e');
      }
      _initializePattern();
    });
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

  /// Restore audio state when resuming a paused session
  /// This ensures background music and other audio continues from where it left off
  void _restoreAudioState() {
    if (_isDisposed || _audioService == null) return;

    try {
      // Get the currently selected background music
      final selectedMusicId =
          ref.read(selectedAudioProvider(AudioType.backgroundMusic));

      if (selectedMusicId != null &&
          selectedMusicId.isNotEmpty &&
          selectedMusicId != 'off') {
        // Find the music track and restart it
        final audioService = ref.read(audioServiceProvider);
        final musicTracks =
            audioService.getTracksByType(AudioType.backgroundMusic);
        final selectedTrack = musicTracks.firstWhere(
          (track) => track.id == selectedMusicId,
          orElse: () =>
              musicTracks.first, // Fallback to first track if not found
        );

        if (selectedTrack.path.isNotEmpty) {
          // Restart the background music
          audioService.playMusic(selectedTrack);
          debugPrint('🎵 Restored background music: ${selectedTrack.name}');
        }
      }
    } catch (e) {
      debugPrint('Error restoring audio state: $e');
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

  // Add this function to properly update when selecting a pattern from the sheet

  void showGoalPatternSheet(BuildContext context) {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            height:
                MediaQuery.of(context).size.height * 0.85, // Adjust height here
            child: const GoalPatternSheet(),
          ),
        );
      },
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

    // --- SESSION STATE MACHINE LOGIC ---
    // Update _sessionState based on playbackState and timer
    if (!_isDisposed) {
      if (playbackState.isPlaying && playbackState.secondsRemaining > 0) {
        _sessionState = BreathingSessionState.playing;
      } else if (!playbackState.isPlaying &&
          playbackState.secondsRemaining > 0 &&
          playbackState.currentActivityId != null) {
        _sessionState = BreathingSessionState.paused;
      } else if (playbackState.secondsRemaining <= 0 &&
          playbackState.currentActivityId == null) {
        _sessionState = BreathingSessionState.finished;
      } else if (playbackState.currentActivityId == null) {
        _sessionState = BreathingSessionState.notStarted;
      }
    }

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

          // Refresh journey progress when a session finishes
          if (previous != null &&
              previous.isPlaying &&
              !next.isPlaying &&
              previous.currentActivityId != null &&
              next.currentActivityId == null) {
            context.read<JourneyProvider>().checkProgress();
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
                      // --- CONTROL BUTTONS AND SELECTORS ---
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

  // --- CONTROL BUTTONS AND SELECTORS LAYOUT ---
  Widget _buildControlsLayout() {
    final bool isNotStartedOrFinished =
        _sessionState == BreathingSessionState.notStarted ||
            _sessionState == BreathingSessionState.finished;

    // Use AnimatedSwitcher for smooth transitions between control layouts
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Column(
        key: ValueKey<BreathingSessionState>(_sessionState),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_sessionState == BreathingSessionState.paused)
            _buildPausedControls()
          else
            _buildPlayPauseButton(),

          // Show selectors only when not in a session
          if (isNotStartedOrFinished) ...[
            const SizedBox(height: 24),
            _buildPatternButton(),
            const SizedBox(height: 16),
            _buildDurationButton(),
          ]
        ],
      ),
    );
  }

  // --- PAUSED STATE CONTROLS ---
  Widget _buildPausedControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Smaller Play (Resume) button
        ElevatedButton(
          onPressed: _toggleBreathing,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            elevation: 4,
          ),
          child: const Icon(Icons.play_arrow_rounded, size: 36),
        ),
        const SizedBox(width: 24),
        // Stop button matching the design
        _buildStopButton(),
      ],
    );
  }

  // --- STOP BUTTON (Corrected Style) ---
  Widget _buildStopButton() {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: _handleStop,
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.surfaceVariant.withOpacity(0.5),
        foregroundColor: cs.onSurfaceVariant,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        elevation: 0, // Flat design as in the picture
      ),
      child: const Icon(Icons.stop_rounded, size: 36),
    );
  }

  // --- PLAY/PAUSE BUTTON ---
  Widget _buildPlayPauseButton() {
    final isPlaying = _sessionState == BreathingSessionState.playing;
    final isPaused = _sessionState == BreathingSessionState.paused;
    final isNotStartedOrFinished =
        _sessionState == BreathingSessionState.notStarted ||
            _sessionState == BreathingSessionState.finished;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    // Only show Play on Not Started/Finished, Pause on Playing, Play (resume) on Paused
    IconData icon;
    if (isPlaying) {
      icon = Icons.pause_rounded;
    } else {
      icon = Icons.play_arrow_rounded;
    }

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
        icon,
        size: isSmallScreen ? 32 : 40,
      ),
    );
  }

  // --- PATTERN SELECTOR BUTTON ---
  Widget _buildPatternButton() {
    if (!(_sessionState == BreathingSessionState.notStarted ||
        _sessionState == BreathingSessionState.finished)) {
      return const SizedBox.shrink(); // Hide during Playing/Paused
    }
    final pattern = ref.watch(selectedPatternProvider);
    final patternName = pattern?.name ?? 'Seleccionar patrón';
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final buttonWidth = isSmallScreen ? 240.0 : 280.0;

    return Container(
      width: buttonWidth,
      constraints: BoxConstraints(maxWidth: buttonWidth),
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

  // --- DURATION SELECTOR BUTTON ---
  Widget _buildDurationButton() {
    if (!(_sessionState == BreathingSessionState.notStarted ||
        _sessionState == BreathingSessionState.finished)) {
      return const SizedBox.shrink(); // Hide during Playing/Paused
    }
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final buttonWidth = isSmallScreen ? 180.0 : 220.0;
    // Using a container to apply custom styling to the DurationSelectorButton
    return Container(
      width: buttonWidth,
      constraints: BoxConstraints(
        maxWidth: buttonWidth,
      ),
      child: const DurationSelectorButton(),
    );
  }

  Future<void> _toggleBreathing() async {
    if (_isDisposed) return;

    // Only allow play if in NotStarted, Finished, or Paused. Only allow pause if in Playing.
    final controller = ref.read(breathingPlaybackControllerProvider.notifier);
    final playbackState = ref.read(breathingPlaybackControllerProvider);
    final isPlaying = _sessionState == BreathingSessionState.playing;
    final isPaused = _sessionState == BreathingSessionState.paused;
    final isNotStartedOrFinished =
        _sessionState == BreathingSessionState.notStarted ||
            _sessionState == BreathingSessionState.finished;
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
      setState(() {
        _sessionState = BreathingSessionState.paused;
      });
    } else if (isPaused || isNotStartedOrFinished) {
      if (expandedSteps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona un patrón primero'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        showGoalPatternSheet(context);
        return;
      }

      // Initialize audio (for new sessions) or restore audio state (for paused sessions)
      if (isPaused) {
        _restoreAudioState(); // Restore music that was playing before pause
      } else {
        _initializeAudio(); // Set defaults for new sessions
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isDisposed) return;
        if (!hasExistingSession) {
          controller.initialize(expandedSteps, duration);
        }
        controller.play();
        setState(() {
          _sessionState = BreathingSessionState.playing;
        });
      });
    }
  }

  // --- STOP LOGIC ---
  void _handleStop() async {
    if (_isDisposed) return;
    final controller = ref.read(breathingPlaybackControllerProvider.notifier);
    await controller.reset(); // This pauses, completes, and resets the state
    _audioService?.stopAllAudio();
    if (mounted) {
      setState(() {
        _sessionState = BreathingSessionState.notStarted;
      });
    }
  }
}
