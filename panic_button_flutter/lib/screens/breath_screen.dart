// REFACTORED: Enhanced breath screen with robust pause/resume and state persistence
// Changes:
// - Fixed navigation lifecycle: pause audio and save state on dispose, restore on return
// - Added automatic restoration of audio settings and session state
// - Enhanced audio control: pause on navigation away, resume on return to screen
// - Added proper session state management to prevent re-initialization
// - Improved logging for debugging navigation and state issues

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
import 'package:panic_button_flutter/services/breathing_state_persistence_service.dart';

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

  // Cache providers in `initState` to safely use in `dispose`.
  late final AudioService _audioService;
  late final BreathingPlaybackController _playbackController;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    _playbackController =
        ref.read(breathingPlaybackControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  @override
  void dispose() {
    debugPrint('🔄 BreathScreen: Disposing screen');
    if (_playbackController.state.isPlaying) {
      _playbackController.pause();
    }
    _audioService.pauseAllAudio();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      debugPrint('🔄 BreathScreen: Initializing screen');

      await _restoreAudioSettings();

      bool stateRestored = false;
      if (widget.patternSlug == null && !widget.autoStart) {
        stateRestored = await _playbackController.restoreSessionState();
      } else {
        await _playbackController.clearSavedState();
      }

      if (stateRestored) {
        debugPrint('✅ Session state restored, UI updated.');
      } else {
        debugPrint('🔄 No session state, initializing new pattern.');
        await _initializeNewPattern();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing screen: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _initializeNewPattern() async {
    if (widget.patternSlug != null) {
      await ref
          .read(selectedPatternProvider.notifier)
          .selectPatternBySlug(widget.patternSlug!);
    } else {
      final defaultPattern = await ref.read(defaultPatternProvider.future);
      if (defaultPattern != null) {
        ref.read(selectedPatternProvider.notifier).state = defaultPattern;
      }
    }

    if (!mounted) return;

    final expandedSteps = await ref.read(expandedStepsProvider.future);
    final duration = ref.read(selectedDurationProvider);

    if (expandedSteps.isNotEmpty) {
      _playbackController.initialize(expandedSteps, duration, forceReset: true);
      if (widget.autoStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _playbackController.play();
        });
      }
    }
  }

  Future<void> _restoreAudioSettings() async {
    final settings = await BreathingStatePersistenceService.loadAudioSettings();
    if (settings == null) {
      _setDefaultAudioIfNeeded();
      return;
    }

    try {
      debugPrint('📂 Restoring saved audio settings: $settings');
      final musicId = settings['musicTrackId'] as String?;
      final voiceId = settings['voiceTrackId'] as String?;
      final instrumentName = settings['instrument'] as String?;

      if (musicId != null)
        ref
            .read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
            .state = musicId;
      if (voiceId != null)
        ref.read(selectedAudioProvider(AudioType.guidingVoice).notifier).state =
            voiceId;
      if (instrumentName != null) {
        final instrument = Instrument.values.firstWhere(
            (i) => i.name == instrumentName,
            orElse: () => Instrument.gong);
        ref.read(selectedInstrumentProvider.notifier).state = instrument;
      }
    } catch (e) {
      debugPrint(
          '❌ Error restoring audio settings: $e, falling back to defaults.');
      _setDefaultAudioIfNeeded();
    }
  }

  void _setDefaultAudioIfNeeded() {
    if (!mounted) return;

    try {
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

  void _showAudioSelectionSheet(BuildContext context) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AudioSelectionSheet(),
    );
  }

  Future<void> _updateBreathingController() async {
    if (!mounted) return;

    final wasPlaying = _playbackController.state.isPlaying;

    // If a session was in progress, finish it before starting a new one.
    if (_playbackController.state.elapsedSeconds > 0) {
      await _playbackController.finish();
    }

    try {
      final expandedSteps = await ref.read(expandedStepsProvider.future);
      if (!mounted) return;

      if (expandedSteps.isNotEmpty) {
        _playbackController.initialize(
          expandedSteps,
          ref.read(selectedDurationProvider),
          forceReset: true,
        );
        // If it was playing before, automatically start the new pattern.
        if (wasPlaying) {
          _playbackController.play();
        }
      }
    } catch (e) {
      debugPrint('Error updating breathing controller: $e');
    }
  }

  void showGoalPatternSheet(BuildContext context) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            height: MediaQuery.of(context).size.height * 0.85,
            child: const GoalPatternSheet(),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        _updateBreathingController();
      }
    });
  }

  void _navigateToJourney() {
    context.go('/journey');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedPatternProvider, (previous, next) {
      if (next != null && _isInitialized) {
        _updateBreathingController();
      }
    });

    ref.listen(selectedDurationProvider, (previous, next) {
      if (_isInitialized) {
        _updateBreathingController();
      }
    });

    ref.listen(breathingPlaybackControllerProvider.select((s) => s.isPlaying),
        (wasPlaying, isPlaying) {
      if (wasPlaying == isPlaying) return;

      if (isPlaying) {
        _audioService.resumeAllAudio();
      } else {
        _audioService.pauseAllAudio();
      }
    });

    final playbackState = ref.watch(breathingPlaybackControllerProvider);
    final cs = Theme.of(context).colorScheme;

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
    final playbackState = ref.watch(breathingPlaybackControllerProvider);
    final hasActiveSession =
        playbackState.isPlaying || playbackState.elapsedSeconds > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildPlayPauseButton(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPatternButton(),
              if (hasActiveSession) ...[
                const SizedBox(width: 16),
                _buildFinishButton(),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
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

  Widget _buildPatternButton() {
    final pattern = ref.watch(selectedPatternProvider);
    final patternName = pattern?.name ?? 'Seleccionar patrón';
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final buttonWidth = hasActiveSession(ref)
        ? (isSmallScreen ? 140.0 : 160.0)
        : (isSmallScreen ? 240.0 : 280.0);

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

  Widget _buildFinishButton() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final buttonWidth = isSmallScreen ? 140.0 : 160.0;

    return Container(
      width: buttonWidth,
      constraints: BoxConstraints(maxWidth: buttonWidth),
      child: TextButton(
        onPressed: () async {
          await _playbackController.finish();
        },
        style: TextButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        ),
        child: const Text(
          'Terminar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool hasActiveSession(WidgetRef ref) {
    final playbackState = ref.watch(breathingPlaybackControllerProvider);
    return playbackState.isPlaying || playbackState.elapsedSeconds > 0;
  }

  Widget _buildDurationButton() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final buttonWidth = isSmallScreen ? 180.0 : 220.0;
    return Container(
      width: buttonWidth,
      constraints: BoxConstraints(
        maxWidth: buttonWidth,
      ),
      child: const DurationSelectorButton(),
    );
  }

  Future<void> _toggleBreathing() async {
    if (!mounted) return;

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
      if (!mounted) return;
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

        showGoalPatternSheet(context);
        return;
      }

      _audioService.resumeAllAudio();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;

        if (!hasExistingSession) {
          controller.initialize(expandedSteps, duration);
        }

        controller.play();
      });
    }
  }
}
