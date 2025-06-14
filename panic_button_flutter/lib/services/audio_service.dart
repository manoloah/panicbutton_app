import 'dart:math';
import 'dart:async';
import 'dart:convert';
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
    'forest': 'assets/sounds/music/river_new.mp3', // If forest fails, try river
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

      // Configure the session with iOS-optimized settings
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
        androidWillPauseWhenDucked:
            false, // Changed to false for better iOS compatibility
      ));

      // Ensure session is active
      await session.setActive(true);

      // Add interruption handling for iOS
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          // Interruption began, pause all audio
          debugPrint('🔇 Audio session interrupted, pausing all audio');
          _handleAudioInterruption();
        } else {
          // Interruption ended, can resume if needed
          debugPrint('🎵 Audio session interruption ended');
        }
      });
    } catch (e) {
      // On web or during development, this might fail but we can continue
      debugPrint('Audio session initialization issue: $e');
    }
  }

  /// Handle audio session interruptions (iOS specific)
  void _handleAudioInterruption() {
    try {
      _musicPlayer.pause();
      _instrumentPlayer.stop();
      _guidingVoicePlayer.stop();
      _instrumentStopTimer?.cancel();
    } catch (e) {
      debugPrint('Error handling audio interruption: $e');
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

  /// Play an instrument cue for the specified phase with iOS error handling
  Future<void> playInstrumentCue(
    Instrument instrument,
    BreathInstrumentPhase phase,
    int phaseDurationSeconds,
  ) async {
    if (instrument.name == 'off' || instrument.name.toLowerCase() == 'off')
      return;

    try {
      // Stop any current instrument playback first to prevent conflicts
      _instrumentStopTimer?.cancel();
      try {
        await _instrumentPlayer.stop();
      } catch (e) {
        // Ignore stop errors, continue with setup
      }

      // Small delay to let the player reset (iOS specific)
      await Future.delayed(const Duration(milliseconds: 50));

      // Build the asset path (no leading 'assets/' prefix needed for setAsset)
      final phaseName =
          phase == BreathInstrumentPhase.inhale ? 'inhale' : 'exhale';
      final instrumentName = instrument.name.toLowerCase();
      final assetPath =
          'assets/sounds/instrument_cues/$instrumentName/${phaseName}_$instrumentName.mp3';

      // Retry logic for iOS "Operation Stopped" errors
      bool success = false;
      int attempts = 0;
      const maxAttempts = 3;

      while (!success && attempts < maxAttempts) {
        attempts++;
        try {
          await _instrumentPlayer.setAsset(assetPath);
          await _instrumentPlayer.setVolume(0.7);
          await _instrumentPlayer.play();
          success = true;
          debugPrint('🎵 Playing instrument cue: $assetPath');

          // Set timer to stop the cue after the phase duration
          _instrumentStopTimer = Timer(
            Duration(seconds: phaseDurationSeconds),
            () async {
              try {
                await _instrumentPlayer.stop();
              } catch (e) {
                debugPrint('Error stopping instrument cue: $e');
              }
            },
          );
        } catch (e) {
          if (e.toString().contains('Operation Stopped') &&
              attempts < maxAttempts) {
            debugPrint('🔄 Instrument cue retry $attempts: Operation Stopped');
            await Future.delayed(const Duration(milliseconds: 200));
            continue;
          } else {
            debugPrint('❌ Error playing instrument cue: $e');
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error in instrument cue setup: $e');
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
    if (track.path.isEmpty) {
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

        while (!loaded && attempts < maxAttempts) {
          attempts++;
          try {
            // Small delay before retry to let resources free up
            if (attempts > 1) {
              debugPrint('Retry attempt $attempts for $track.path');
              await Future.delayed(const Duration(milliseconds: 300));
            }

            // Special handling for river.mp3 which often has issues on iOS
            if (track.id == 'river' && attempts > 1) {
              // Try loading the asset as a byte array first
              try {
                final data = await rootBundle.load(track.path);
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

            await player.setAsset(track.path);
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
                  'Failed to load audio asset after $attempts attempts: $track.path - $e');
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

  /// Play a voice prompt for the specified phase with iOS error handling
  Future<void> playVoicePrompt(String voiceId, BreathVoicePhase phase) async {
    if (voiceId.isEmpty) return;

    try {
      // Stop any current voice playback first to prevent conflicts
      try {
        await _guidingVoicePlayer.stop();
      } catch (e) {
        // Ignore stop errors, continue with setup
      }

      // Small delay to let the player reset (iOS specific)
      await Future.delayed(const Duration(milliseconds: 50));

      // Convert phase name to directory structure format
      String phaseName = phase.toString().split('.').last;
      // Convert camelCase to snake_case for directory names
      phaseName = phaseName.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)!.toLowerCase()}',
      );
      // Remove leading underscore if present
      if (phaseName.startsWith('_')) {
        phaseName = phaseName.substring(1);
      }

      // Build the asset path with correct directory structure
      final assetPath = 'assets/sounds/guiding_voices/$voiceId/$phaseName';

      // Define available files based on what actually exists in assets for each voice
      final availableFiles = <String>[];

      if (voiceId == 'manu') {
        // Manu voice files
        if (phaseName == 'inhale') {
          availableFiles.addAll(['$assetPath/1.mp3', '$assetPath/2.mp3']);
        } else if (phaseName == 'exhale') {
          availableFiles.addAll(
              ['$assetPath/1.mp3', '$assetPath/2.mp3', '$assetPath/3.mp3']);
        } else if (phaseName == 'pause_after_inhale') {
          // Manu pause_after_inhale: has 1.mp3, 2.mp3, 3.mp3, 4.mp3
          availableFiles.addAll([
            '$assetPath/1.mp3',
            '$assetPath/2.mp3',
            '$assetPath/3.mp3',
            '$assetPath/4.mp3'
          ]);
        } else if (phaseName == 'pause_after_exhale') {
          // Manu pause_after_exhale: has 1.mp3, 2.mp3, 3.mp3, 4.mp3
          availableFiles.addAll([
            '$assetPath/1.mp3',
            '$assetPath/2.mp3',
            '$assetPath/3.mp3',
            '$assetPath/4.mp3'
          ]);
        } else {
          // For any other phases, try 1.mp3 and 2.mp3 as fallback
          availableFiles.addAll(['$assetPath/1.mp3', '$assetPath/2.mp3']);
        }
      } else if (voiceId == 'andrea') {
        // Andrea voice files
        if (phaseName == 'inhale') {
          availableFiles.addAll(['$assetPath/1.mp3', '$assetPath/2.mp3']);
        } else if (phaseName == 'exhale') {
          availableFiles.add('$assetPath/1.mp3');
        } else if (phaseName == 'pause_after_inhale') {
          // Andrea pause_after_inhale: has 1.mp3, 2.mp3, 3.mp3, 4.mp3
          availableFiles.addAll([
            '$assetPath/1.mp3',
            '$assetPath/2.mp3',
            '$assetPath/3.mp3',
            '$assetPath/4.mp3'
          ]);
        } else if (phaseName == 'pause_after_exhale') {
          // Andrea pause_after_exhale: has 1.mp3, 2.mp3, 3.mp3, 4.mp3
          availableFiles.addAll([
            '$assetPath/1.mp3',
            '$assetPath/2.mp3',
            '$assetPath/3.mp3',
            '$assetPath/4.mp3'
          ]);
        } else {
          // For any other phases, try 1.mp3 as fallback
          availableFiles.add('$assetPath/1.mp3');
        }
      } else {
        // For other voices (future), try common files
        availableFiles.addAll(['$assetPath/1.mp3', '$assetPath/2.mp3']);
      }

      if (availableFiles.isNotEmpty) {
        // Randomly select from available files
        final random = Random();
        final selectedFile =
            availableFiles[random.nextInt(availableFiles.length)];

        // Retry logic for iOS "Operation Stopped" errors
        bool success = false;
        int attempts = 0;
        const maxAttempts = 3;

        while (!success && attempts < maxAttempts) {
          attempts++;
          try {
            await _guidingVoicePlayer.setAsset(selectedFile);
            await _guidingVoicePlayer.setVolume(0.8);
            await _guidingVoicePlayer.play();
            success = true;
            debugPrint('🎵 Playing voice prompt: $selectedFile');
          } catch (e) {
            if (e.toString().contains('Operation Stopped') &&
                attempts < maxAttempts) {
              debugPrint('🔄 Voice prompt retry $attempts: Operation Stopped');
              await Future.delayed(const Duration(milliseconds: 200));
              continue;
            } else {
              debugPrint('❌ Error playing voice prompt: $e');
              break;
            }
          }
        }
      } else {
        debugPrint('⚠️ No valid voice files found for $voiceId/$phaseName');
      }
    } catch (e) {
      debugPrint('❌ Error in voice prompt setup: $e');
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

  /// Stop all audio streams immediately with iOS-safe handling.
  /// This is useful for when the user leaves the breathing screen.
  Future<void> stopAllAudio() async {
    try {
      // Cancel any pending timers first
      _instrumentStopTimer?.cancel();

      // Stop all players individually with error handling (iOS safe)
      final stopTasks = <Future>[];

      // Stop music player
      stopTasks.add(_stopPlayerSafely(_musicPlayer, 'music'));

      // Stop instrument player
      stopTasks.add(_stopPlayerSafely(_instrumentPlayer, 'instrument'));

      // Stop voice player
      stopTasks.add(_stopPlayerSafely(_guidingVoicePlayer, 'voice'));

      // Wait for all stops to complete (with timeout for safety)
      await Future.wait(stopTasks).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚠️ Audio stop timeout, continuing anyway');
          return [];
        },
      );

      // Reset current tracks
      _setCurrentTrack(AudioType.backgroundMusic, null);
      _setCurrentTrack(AudioType.instrumentCue, null);
      _setCurrentTrack(AudioType.guidingVoice, null);

      debugPrint('🔇 All audio stopped');
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Safely stop a player with error handling
  Future<void> _stopPlayerSafely(AudioPlayer player, String playerName) async {
    try {
      await player.stop();
    } catch (e) {
      // Ignore stop errors on iOS - they're often harmless
      debugPrint('ℹ️ Stop $playerName player: $e');
    }
  }

  // Note: dispose() method removed to prevent web compatibility issues.
  // Use stopAllAudio() instead when cleaning up.

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

  /// Load and play a music track with iOS error handling
  Future<void> playMusic(AudioTrack track) async {
    try {
      // If "Off" is selected, stop playback
      if (track.path.isEmpty) {
        await stopAudio(AudioType.backgroundMusic);
        _setCurrentTrack(AudioType.backgroundMusic, null);
        return;
      }

      // Stop any current music playback first to prevent conflicts
      try {
        await _musicPlayer.stop();
      } catch (e) {
        // Ignore stop errors, continue with setup
      }

      // Small delay to let the player reset (iOS specific)
      await Future.delayed(const Duration(milliseconds: 100));

      // Use the track path directly since it already includes the assets prefix
      final assetPath = track.path;

      // Retry logic for iOS "Operation Stopped" errors
      bool success = false;
      int attempts = 0;
      const maxAttempts =
          3; // More attempts for music since it's longer-running

      while (!success && attempts < maxAttempts) {
        attempts++;
        try {
          await _musicPlayer.setAsset(assetPath);
          await _musicPlayer.setLoopMode(LoopMode.all);
          await _musicPlayer
              .setVolume(0.6); // Slightly lower volume for better mixing
          await _musicPlayer.play();
          success = true;

          _setCurrentTrack(AudioType.backgroundMusic, track);
          debugPrint('🎵 Playing music: ${track.name}');
        } catch (e) {
          if (e.toString().contains('Operation Stopped') &&
              attempts < maxAttempts) {
            debugPrint('🔄 Music retry $attempts: Operation Stopped');
            await Future.delayed(
                Duration(milliseconds: 200 * attempts)); // Increasing delay
            continue;
          } else {
            debugPrint('❌ Error playing music: $e');
            _setCurrentTrack(AudioType.backgroundMusic, null);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error in music setup: $e');
      _setCurrentTrack(AudioType.backgroundMusic, null);
    }
  }

  /// Stop only breathing-related audio (voice and instrument cues)
  /// while preserving background music. This is used when stopping a
  /// breathing exercise but wanting to keep background music playing.
  Future<void> stopBreathingAudio() async {
    try {
      // Cancel any pending timers first
      _instrumentStopTimer?.cancel();

      // Stop only instrument and voice players, keep music playing
      final stopTasks = <Future>[];

      // Stop instrument player
      stopTasks.add(_stopPlayerSafely(_instrumentPlayer, 'instrument'));

      // Stop voice player
      stopTasks.add(_stopPlayerSafely(_guidingVoicePlayer, 'voice'));

      // Wait for stops to complete (with timeout for safety)
      await Future.wait(stopTasks).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('⚠️ Breathing audio stop timeout, continuing anyway');
          return [];
        },
      );

      // Reset only instrument and voice current tracks, keep music track
      _setCurrentTrack(AudioType.instrumentCue, null);
      _setCurrentTrack(AudioType.guidingVoice, null);

      debugPrint('🔇 Breathing audio stopped (background music preserved)');
    } catch (e) {
      debugPrint('Error stopping breathing audio: $e');
    }
  }

  /// Restore background music if a track is selected but not currently playing
  /// This is useful when returning from a stopped state to resume music
  Future<void> restoreBackgroundMusicIfNeeded() async {
    try {
      // Check if background music should be playing but isn't
      if (_currentMusic != null && _currentMusic!.path.isNotEmpty) {
        // Check if the music player is actually playing
        final isPlaying = _musicPlayer.playing;

        if (!isPlaying) {
          // Restart the background music
          await playMusic(_currentMusic!);
          debugPrint('🎵 Restored background music: ${_currentMusic!.name}');
        }
      }
    } catch (e) {
      debugPrint('Error restoring background music: $e');
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
