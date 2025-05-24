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
  bool _isDisposed = false;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _audioService = ref.read(audioServiceProvider);
        _initializePattern();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();

    // Stop all audio when leaving the screen
    _audioService?.stopAllAudio().catchError((e) {
      debugPrint('Error stopping audio during dispose: $e');
    });
  }

  Future<void> _initializePattern() async {
    try {
      if (_isDisposed) return;

      final selectedPatternNotifier =
          ref.read(selectedPatternProvider.notifier);
      final playbackController =
          ref.read(breathingPlaybackControllerProvider.notifier);

      // Set default audio selections
      _setDefaultAudioSelections();

      if (widget.patternSlug != null) {
        await selectedPatternNotifier.selectPatternBySlug(widget.patternSlug!);
        if (_isDisposed) return;

        final expandedSteps = await ref.read(expandedStepsProvider.future);
        if (_isDisposed) return;

        final duration = ref.read(selectedDurationProvider);
        if (_isDisposed) return;

        if (expandedSteps.isNotEmpty) {
          playbackController.initialize(expandedSteps, duration);

          if (widget.autoStart) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed) {
                playbackController.play();
              }
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

      // Fallback to default pattern
      final defaultPattern = await ref.read(defaultPatternProvider.future);
      if (_isDisposed) return;

      if (defaultPattern != null) {
        selectedPatternNotifier.state = defaultPattern;
        final expandedSteps = await ref.read(expandedStepsProvider.future);
        if (_isDisposed) return;

        final duration = ref.read(selectedDurationProvider);
        if (_isDisposed) return;

        if (expandedSteps.isNotEmpty) {
          playbackController.initialize(expandedSteps, duration);
        }
      }

      if (!_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing pattern: $e');
      if (!_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  void _setDefaultAudioSelections() {
    if (_isDisposed) return;

    try {
      // Only set defaults if nothing is currently selected - don't override existing selections
      final currentVoice =
          ref.read(selectedAudioProvider(AudioType.guidingVoice));
      if (currentVoice == null || currentVoice.isEmpty) {
        ref
            .read(selectedAudioProvider(AudioType.guidingVoice).notifier)
            .selectTrack('manu');
      }

      final currentMusic =
          ref.read(selectedAudioProvider(AudioType.backgroundMusic));
      if (currentMusic == null || currentMusic.isEmpty) {
        ref
            .read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
            .selectTrack('river');
      }

      final currentInstrument = ref.read(persistentInstrumentCueProvider);
      if (currentInstrument == null || currentInstrument.isEmpty) {
        ref
            .read(selectedAudioProvider(AudioType.instrumentCue).notifier)
            .selectTrack('gong');
      } else {
        // Just update the provider state without playing anything
        ref
            .read(selectedAudioProvider(AudioType.instrumentCue).notifier)
            .updateStateOnly(currentInstrument);
      }
    } catch (e) {
      debugPrint('Error setting default audio: $e');
    }
  }

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

  Future<void> _updateBreathingController() async {
    if (_isDisposed) return;

    try {
      final controller = ref.read(breathingPlaybackControllerProvider.notifier);
      final wasPlaying =
          ref.read(breathingPlaybackControllerProvider).isPlaying;

      // Stop current playback but preserve audio selections
      if (wasPlaying) {
        controller.pause();
      }

      // Only reset instrument cue playback, not the selections
      _audioService?.resetInstrumentCueState();

      final expandedSteps = await ref.read(expandedStepsProvider.future);
      if (_isDisposed) return;

      final duration = ref.read(selectedDurationProvider);
      if (_isDisposed) return;

      if (expandedSteps.isNotEmpty) {
        controller.initialize(expandedSteps, duration);

        if (wasPlaying) {
          controller.play();
        }
      }
    } catch (e) {
      debugPrint('Error updating breathing controller: $e');
    }
  }

  void showGoalPatternSheet(BuildContext context) {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GoalPatternSheet(),
    ).then((_) {
      if (!_isDisposed) {
        _updateBreathingController();
      }
    });
  }

  void _navigateToJourney() {
    context.go('/journey');
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(breathingPlaybackControllerProvider);
    final cs = Theme.of(context).colorScheme;

    // Setup listeners only once
    ref.listen(selectedPatternProvider, (previous, next) {
      if (_isDisposed || next == null) return;
      if (_isInitialized) {
        _updateBreathingController();
      }
    });

    ref.listen(selectedDurationProvider, (previous, next) {
      if (_isDisposed) return;
      if (_isInitialized) {
        _updateBreathingController();
      }
    });

    // Show loading while initializing
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: cs.surface,
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
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: cs.surface,
              elevation: 0,
              leadingWidth: 56,
              leading: IconButton(
                icon: Icon(Icons.music_note, color: cs.onSurface, size: 24),
                onPressed: () => _showAudioSelectionSheet(context),
                tooltip: 'Audio settings',
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: cs.onSurface, size: 24),
                  onPressed: _navigateToJourney,
                  tooltip: 'Back to journey',
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: cs.onSurface, size: 24),
                  onPressed: () => context.go('/settings'),
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
                      _buildTimerDisplay(playbackState),
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

  Widget _buildControlsLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildPlayPauseButton(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPatternButton(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildDurationButton(),
          ),
        ],
      ),
    );
  }

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

  Widget _buildPatternButton() {
    final pattern = ref.watch(selectedPatternProvider);
    final patternName = pattern?.name ?? 'Seleccionar patrón';
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: isSmallScreen ? 280 : 350),
      child: TextButton.icon(
        onPressed: () => showGoalPatternSheet(context),
        style: Theme.of(context).outlinedButtonTheme.style,
        icon: const Icon(Icons.air, size: 24),
        label: Text(
          patternName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildDurationButton() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: isSmallScreen ? 280 : 350),
      child: const DurationSelectorButton(),
    );
  }

  void _toggleBreathing() {
    if (_isDisposed) return;

    try {
      final controller = ref.read(breathingPlaybackControllerProvider.notifier);
      final playbackState = ref.read(breathingPlaybackControllerProvider);
      final isPlaying = playbackState.isPlaying;
      final expandedSteps = ref.read(expandedStepsProvider).value ?? [];
      final hasExistingSession = playbackState.currentActivityId != null;
      final duration = ref.read(selectedDurationProvider);

      if (isPlaying) {
        controller.pause();
        // Stop all audio when pausing
        _audioService?.stopAllAudio();
      } else {
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

        // Initialize controller if needed
        if (!hasExistingSession) {
          controller.initialize(expandedSteps, duration);
        }

        // Start playing
        controller.play();
      }
    } catch (e) {
      debugPrint('Error toggling breathing: $e');
    }
  }
}
