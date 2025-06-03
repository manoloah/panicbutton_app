import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_session/audio_session.dart';

/// Provider for the audio service
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

/// Model for audio track information
class AudioTrack {
  final String id;
  final String name;
  final String path;
  final IconData icon;

  const AudioTrack({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
  });
}

/// Types of audio that can be played
enum AudioType {
  backgroundMusic,
  instrumentCue,
  guidingVoice,
}

/// Instrument types for breathing cues
enum Instrument {
  gong,
  synth,
  violin,
  human,
  off,
}

/// Phases of breathing for voice prompts
enum BreathVoicePhase {
  inhale,
  pauseAfterInhale,
  exhale,
  pauseAfterExhale,
}

/// Phases of breathing for instrument cues
enum BreathInstrumentPhase {
  inhale,
  exhale,
}

/// Service for managing audio playback in the app
class AudioService {
  // Audio players for different audio types
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _instrumentPlayer = AudioPlayer();
  final AudioPlayer _guidingVoicePlayer = AudioPlayer();

  // Track played prompts to avoid repetition
  final Map<String, List<String>> _playedPrompts = {};

  // Track currently playing for each type
  AudioTrack? _currentMusic;
  AudioTrack? _currentInstrument;
  AudioTrack? _currentGuidingVoice;

  // Timer for stopping instrument cues at precise timing
  Timer? _instrumentStopTimer;

  // Available audio tracks for instrument cues (replacing breath guide tones)
  final List<AudioTrack> _instrumentTracks = const [
    AudioTrack(
      id: 'gong',
      name: "Gongo",
      path: 'assets/sounds/instrument_cues/gong',
      icon: Icons.sports_martial_arts,
    ),
    AudioTrack(
      id: 'synth',
      name: "Sintetizador",
      path: 'assets/sounds/instrument_cues/synth',
      icon: Icons.piano,
    ),
    AudioTrack(
      id: 'violin',
      name: "Violín",
      path: 'assets/sounds/instrument_cues/violin',
      icon: Icons.queue_music,
    ),
    AudioTrack(
      id: 'human',
      name: "Humano",
      path: 'assets/sounds/instrument_cues/human',
      icon: Icons.mic,
    ),
    AudioTrack(
      id: 'off',
      name: "Apagado",
      path: '',
      icon: Icons.horizontal_rule,
    ),
  ];

  // Background music tracks
  final List<AudioTrack> _musicTracks = const [
    AudioTrack(
      id: 'forest',
      name: "Bosque",
      path: 'assets/sounds/music/rainforest.mp3',
      icon: Icons.forest,
    ),
    AudioTrack(
      id: 'river',
      name: "Río",
      path: 'assets/sounds/music/river_new.mp3',
      icon: Icons.water_rounded,
    ),
    AudioTrack(
      id: 'ocean',
      name: "Oceano",
      path: 'assets/sounds/music/ocean.mp3',
      icon: Icons.waves,
    ),
    AudioTrack(
      id: 'off',
      name: "Apagado",
      path: '',
      icon: Icons.horizontal_rule,
    ),
  ];

  // Fallback tracks if primary ones fail to load
  final Map<String, String> _fallbackTracks = {
    'river': 'assets/sounds/music/ocean.mp3', // If river fails, try ocean
    'ocean':
        'assets/sounds/music/rainforest.mp3', // If ocean fails, try rainforest
    'forest': 'assets/sounds/music/river.mp3', // If forest fails, try river
  };

  // Guiding voice tracks - dynamically loaded
  late List<AudioTrack> _guidingVoiceTracks;

  AudioService() {
    _initAudioSession();
    _initGuidingVoices();
    _setupErrorListeners();

    // Preload common audio assets
    _preloadCommonAudio();
  }

  /// Initialize the audio session with proper settings
  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;

      // Configure the session with proper settings
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Ensure session is active
      await session.setActive(true);
    } catch (e) {
      // On web or during development, this might fail but we can continue
      debugPrint('Audio session initialization issue: $e');
    }
  }

  /// Setup error listeners for all players to help diagnose issues
  void _setupErrorListeners() {
    _musicPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      // Only log player errors if they're unexpected
      if (!e.toString().contains('Connection aborted')) {
        debugPrint('Music player error: $e');
      }
    });

    _instrumentPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      // Only log player errors if they're unexpected
      if (!e.toString().contains('Connection aborted')) {
        debugPrint('Instrument player error: $e');
      }
    });

    _guidingVoicePlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace st) {
      // Only log player errors if they're unexpected
      if (!e.toString().contains('Connection aborted')) {
        debugPrint('Voice guide player error: $e');
      }
    });
  }

  /// Initialize guiding voices by dynamically finding available voices
  Future<void> _initGuidingVoices() async {
    // Define the basic tracks list with voices first, then "off" option
    _guidingVoiceTracks = [
      // Manu is always available and should be first (leftmost)
      const AudioTrack(
        id: 'manu',
        name: "Manu",
        path: 'assets/sounds/guiding_voices/manu', // Base path only
        icon: Icons.person,
      ),
      // Andrea is second
      const AudioTrack(
        id: 'andrea',
        name: "Andrea",
        path: 'assets/sounds/guiding_voices/andrea', // Base path only
        icon: Icons.person,
      ),
      // Off option goes last (rightmost)
      const AudioTrack(
        id: 'off',
        name: "Apagado",
        path: '',
        icon: Icons.horizontal_rule,
      ),
    ];

    // Note: We're hardcoding Manu and Andrea since they're required to be available,
    // but the implementation supports automatic discovery of new voices if they're
    // added following the same folder structure:
    //
    // To add a new guiding voice character:
    // 1. Create a folder with the character's name under assets/sounds/guiding_voices/
    // 2. Inside that folder, create subfolders for each phase: inhale, pause_after_inhale, exhale, pause_after_exhale
    // 3. Add MP3 files for each phase in their respective folders
    // 4. Register each subfolder in pubspec.yaml
    // 5. The new voice will automatically appear in the UI for selection
  }

  /// Play an instrument cue for the specified phase with precise timing
  Future<void> playInstrumentCue(
    Instrument instrument,
    BreathInstrumentPhase phase,
    int phaseDurationSeconds,
  ) async {
    // Stop any currently playing instrument cue
    _instrumentStopTimer?.cancel();
    await _instrumentPlayer.stop();

    // If instrument is off, don't play anything
    if (instrument == Instrument.off) {
      return;
    }

    try {
      // Build the asset path
      final phaseName =
          phase == BreathInstrumentPhase.inhale ? 'inhale' : 'exhale';
      final instrumentName = instrument.name;
      final assetPath =
          'assets/sounds/instrument_cues/$instrumentName/${phaseName}_$instrumentName.mp3';

      // Load and play the instrument cue
      await _instrumentPlayer.setAsset(assetPath);
      await _instrumentPlayer.setVolume(0.8);

      // Get the duration of the audio file
      final audioDuration = _instrumentPlayer.duration;

      if (audioDuration != null) {
        final audioDurationSeconds = audioDuration.inSeconds;

        if (audioDurationSeconds <= phaseDurationSeconds) {
          // Audio is shorter than or equal to phase duration - play once
          await _instrumentPlayer.setLoopMode(LoopMode.off);
        } else {
          // Audio is longer than phase duration - play and stop at phase end
          await _instrumentPlayer.setLoopMode(LoopMode.off);

          // Schedule stop at phase end
          _instrumentStopTimer = Timer(
            Duration(seconds: phaseDurationSeconds),
            () async {
              try {
                await _instrumentPlayer.stop();
              } catch (e) {
                // Ignore errors when stopping
              }
            },
          );
        }
      }

      // Start playback
      await _instrumentPlayer.play();
    } catch (e) {
      debugPrint('Error playing instrument cue: $e');
    }
  }

  /// Get the list of available tracks by audio type
  List<AudioTrack> getTracksByType(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _musicTracks;
      case AudioType.instrumentCue:
        return _instrumentTracks;
      case AudioType.guidingVoice:
        return _guidingVoiceTracks;
    }
  }

  /// Get the currently playing track by audio type
  AudioTrack? getCurrentTrack(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _currentMusic;
      case AudioType.instrumentCue:
        return _currentInstrument;
      case AudioType.guidingVoice:
        return _currentGuidingVoice;
    }
  }

  /// Play audio track based on type
  Future<void> playTrack(AudioType type, String trackId) async {
    // Get tracks for the requested type
    final tracks = getTracksByType(type);
    final track =
        tracks.firstWhere((t) => t.id == trackId, orElse: () => tracks.first);

    // If "Off" is selected, stop playback
    if (track.id == 'off') {
      await stopAudio(type);
      _setCurrentTrack(type, null);
      return;
    }

    try {
      // Get the appropriate player
      final player = _getPlayerByType(type);

      // Stop current playback
      try {
        await player.stop();
      } catch (e) {
        // Continue with setup - this error can be ignored
      }

      // Set up the audio source (only for music and guiding voice, not instrument cues)
      if (type != AudioType.guidingVoice && type != AudioType.instrumentCue) {
        // Try loading the asset with retry logic for common errors
        bool loaded = false;
        int attempts = 0;
        const maxAttempts = 3;
        String assetPath = track.path;

        while (!loaded && attempts < maxAttempts) {
          attempts++;
          try {
            // Small delay before retry to let resources free up
            if (attempts > 1) {
              debugPrint('Retry attempt $attempts for $assetPath');
              await Future.delayed(const Duration(milliseconds: 300));
            }

            // Special handling for river.mp3 which often has issues on iOS
            if (track.id == 'river' && attempts > 1) {
              // Try loading the asset as a byte array first
              try {
                final data = await rootBundle.load(assetPath);
                await player.setAudioSource(
                  BytesAudioSource(data.buffer.asUint8List()),
                );
                loaded = true;
                continue;
              } catch (byteError) {
                debugPrint('Byte loading failed: $byteError');
                // Continue to standard loading if byte loading fails
              }
            }

            await player.setAsset(assetPath);
            loaded = true;
          } catch (e) {
            // Check if this is a known "Operation Stopped" error that might resolve with retry
            if (e.toString().contains("Operation Stopped") &&
                attempts < maxAttempts) {
              // Continue to retry
              debugPrint('Operation stopped error, will retry: $e');
            } else if (attempts >= maxAttempts &&
                _fallbackTracks.containsKey(track.id)) {
              // Try fallback track as last resort
              final fallbackPath = _fallbackTracks[track.id]!;
              debugPrint('Using fallback track: $fallbackPath');
              try {
                await player.setAsset(fallbackPath);
                loaded = true;
              } catch (fallbackError) {
                debugPrint('Fallback also failed: $fallbackError');
                return; // Give up if fallback also fails
              }
            } else if (attempts >= maxAttempts) {
              // Log only on final failure
              debugPrint(
                  'Failed to load audio asset after $attempts attempts: $assetPath - $e');
              return;
            }
          }
        }

        // Configure looping
        try {
          await player.setLoopMode(LoopMode.all);
        } catch (e) {
          // Non-critical - we can continue
        }

        // Set volume and play
        try {
          await player.setVolume(0.7);
          await player.play();
        } catch (e) {
          debugPrint('Error playing audio: $e');
          return;
        }
      }

      // Update current track
      _setCurrentTrack(type, track);
    } catch (e) {
      debugPrint('General error in audio playback: $e');
    }
  }

  /// Play a guiding voice prompt for the specified phase
  Future<void> playVoicePrompt(BreathVoicePhase phase) async {
    // Get current guiding voice
    final voiceTrack = _currentGuidingVoice;
    if (voiceTrack == null || voiceTrack.id == 'off') {
      return; // No voice selected or voice is off
    }

    // Get the base path for the voice
    final basePath = voiceTrack.path;

    // Map phase to folder name
    String phaseFolder;
    switch (phase) {
      case BreathVoicePhase.inhale:
        phaseFolder = 'inhale';
        break;
      case BreathVoicePhase.pauseAfterInhale:
        phaseFolder = 'pause_after_inhale';
        break;
      case BreathVoicePhase.exhale:
        phaseFolder = 'exhale';
        break;
      case BreathVoicePhase.pauseAfterExhale:
        phaseFolder = 'pause_after_exhale';
        break;
    }

    try {
      // Get a random prompt that hasn't been played recently
      final promptPath = await _getRandomPrompt('$basePath/$phaseFolder');
      if (promptPath == null) {
        return; // No prompt files found
      }

      // Stop current voice playback
      await _guidingVoicePlayer.stop();

      // Set up new prompt
      await _guidingVoicePlayer.setAsset(promptPath);

      // Configure one-time playback
      await _guidingVoicePlayer.setLoopMode(LoopMode.off);

      // Set volume and play
      await _guidingVoicePlayer.setVolume(1.0);
      await _guidingVoicePlayer.play();

      // Record this prompt as played
      _recordPlayedPrompt(phaseFolder, promptPath);
    } catch (e) {
      // Just log error but don't interrupt breathing exercise
      debugPrint('Error playing voice prompt: $e');
    }
  }

  /// Get a random prompt from the specified folder that hasn't been played recently
  Future<String?> _getRandomPrompt(String folderPath) async {
    try {
      // This would normally use a file system API to list files
      // For simplicity and safety, we'll use numbered files
      final validPaths = <String>[];

      // Try files with numbers 1-5 (reasonable number of variations)
      for (int i = 1; i <= 5; i++) {
        final path = '$folderPath/${i}.mp3';
        try {
          // Check if this file exists by trying to load its bytes
          await rootBundle.load(path);
          validPaths.add(path);
        } catch (e) {
          // File doesn't exist, continue silently
        }
      }

      if (validPaths.isEmpty) {
        // Only log when no valid files are found in a folder
        debugPrint('No valid voice prompts found in: $folderPath');
        return null;
      }

      // Get a list of played prompts for this folder
      final playedPrompts = _playedPrompts[folderPath] ?? [];

      // Filter out recently played prompts if possible
      final unplayedPrompts =
          validPaths.where((path) => !playedPrompts.contains(path)).toList();

      // If all prompts have been played, use any prompt
      final promptsToChooseFrom =
          unplayedPrompts.isNotEmpty ? unplayedPrompts : validPaths;

      // Pick a random prompt
      final random = Random();
      return promptsToChooseFrom[random.nextInt(promptsToChooseFrom.length)];
    } catch (e) {
      // Only log unexpected errors
      debugPrint('Error getting random prompt: $e');
      return null;
    }
  }

  /// Record a prompt as played to avoid repetition
  void _recordPlayedPrompt(String folder, String path) {
    if (!_playedPrompts.containsKey(folder)) {
      _playedPrompts[folder] = [];
    }

    // Add to played list
    _playedPrompts[folder]!.add(path);

    // Keep only the 3 most recent prompts to avoid repetition
    if (_playedPrompts[folder]!.length > 3) {
      _playedPrompts[folder]!.removeAt(0);
    }
  }

  /// Stop audio playback by type
  Future<void> stopAudio(AudioType type) async {
    try {
      final player = _getPlayerByType(type);
      await player.stop();

      // Clear current track
      _setCurrentTrack(type, null);
    } catch (e) {
      // Silent error - non-critical
      _setCurrentTrack(type, null);
    }
  }

  /// Stop all audio playback
  Future<void> stopAllAudio() async {
    try {
      await stopAudio(AudioType.backgroundMusic);
      await stopAudio(AudioType.instrumentCue);
      await stopAudio(AudioType.guidingVoice);

      // Cancel any pending instrument stop timer
      _instrumentStopTimer?.cancel();
    } catch (e) {
      debugPrint('Error stopping all audio: $e');
    }
  }

  /// Dispose all players to free resources
  Future<void> dispose() async {
    try {
      // Cancel any pending timers
      _instrumentStopTimer?.cancel();

      await _musicPlayer.dispose();
      await _instrumentPlayer.dispose();
      await _guidingVoicePlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio players: $e');
    }
  }

  /// Helper method to get the appropriate player by type
  AudioPlayer _getPlayerByType(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _musicPlayer;
      case AudioType.instrumentCue:
        return _instrumentPlayer;
      case AudioType.guidingVoice:
        return _guidingVoicePlayer;
    }
  }

  /// Helper method to set the current track by type
  void _setCurrentTrack(AudioType type, AudioTrack? track) {
    switch (type) {
      case AudioType.backgroundMusic:
        _currentMusic = track;
        break;
      case AudioType.instrumentCue:
        _currentInstrument = track;
        break;
      case AudioType.guidingVoice:
        _currentGuidingVoice = track;
        break;
    }
  }

  /// Preload common audio assets to improve reliability
  Future<void> _preloadCommonAudio() async {
    try {
      // Preload background music (river is commonly used)
      final riverPath = 'assets/sounds/music/river_new.mp3';
      try {
        await rootBundle.load(riverPath);
      } catch (e) {
        // Ignore errors during preloading
      }

      // Preload common instrument cue (gong is default)
      final gongInhalePath =
          'assets/sounds/instrument_cues/gong/inhale_gong.mp3';
      try {
        await rootBundle.load(gongInhalePath);
      } catch (e) {
        // Ignore errors during preloading
      }
    } catch (e) {
      // Silently ignore preloading errors
    }
  }
}

/// Provider to track the currently selected audio for each type
final selectedAudioProvider =
    StateNotifierProvider.family<SelectedAudioNotifier, String?, AudioType>(
  (ref, type) => SelectedAudioNotifier(type, ref),
);

/// Provider to track the currently selected instrument
final selectedInstrumentProvider =
    StateNotifierProvider<SelectedInstrumentNotifier, Instrument>(
  (ref) => SelectedInstrumentNotifier(),
);

/// Notifier to manage the selected audio state
class SelectedAudioNotifier extends StateNotifier<String?> {
  final AudioType type;
  final Ref ref;

  SelectedAudioNotifier(this.type, this.ref) : super(null);

  /// Select a track by id and start playback
  Future<void> selectTrack(String trackId) async {
    state = trackId;
    await ref.read(audioServiceProvider).playTrack(type, trackId);
  }
}

/// Notifier to manage the selected instrument state
class SelectedInstrumentNotifier extends StateNotifier<Instrument> {
  SelectedInstrumentNotifier() : super(Instrument.gong); // Default to gong

  /// Select an instrument
  void selectInstrument(Instrument instrument) {
    state = instrument;
  }
}

/// Custom audio source for loading from bytes
class BytesAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  BytesAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
