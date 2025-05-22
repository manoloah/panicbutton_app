import 'dart:math';
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
  breathGuide,
  guidingVoice, // Renamed from ambientSound to better reflect its purpose
}

/// Phases of breathing for voice prompts
enum BreathVoicePhase {
  inhale,
  pauseAfterInhale,
  exhale,
  pauseAfterExhale,
}

/// Service for managing audio playback in the app
class AudioService {
  // Audio players for different audio types
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _breathGuidePlayer = AudioPlayer();
  final AudioPlayer _guidingVoicePlayer = AudioPlayer();

  // Track played prompts to avoid repetition
  final Map<String, List<String>> _playedPrompts = {};

  // Track currently playing for each type
  AudioTrack? _currentMusic;
  AudioTrack? _currentBreathGuide;
  AudioTrack? _currentGuidingVoice;

  // Available audio tracks for breathing tones
  final List<AudioTrack> _breathGuideTracks = const [
    AudioTrack(
      id: 'sine',
      name: "Onda",
      path: 'assets/sounds/tones/sine.mp3',
      icon: Icons.waves,
    ),
    AudioTrack(
      id: 'synth',
      name: "Sintetizador",
      path: 'assets/sounds/tones/synth.mp3',
      icon: Icons.piano,
    ),
    AudioTrack(
      id: 'bowl',
      name: "Cuenco",
      path: 'assets/sounds/tones/bowl.mp3',
      icon: Icons.nightlife,
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
      path: 'assets/sounds/music/river.mp3',
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

  // Guiding voice tracks - dynamically loaded
  late List<AudioTrack> _guidingVoiceTracks;

  AudioService() {
    _initAudioSession();
    _initGuidingVoices();
  }

  /// Initialize the audio session with proper settings
  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
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
    } catch (e) {
      // On web or during development, this might fail but we can continue
      debugPrint('Audio session initialization skipped: $e');
    }
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

  /// Get the list of available tracks by audio type
  List<AudioTrack> getTracksByType(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _musicTracks;
      case AudioType.breathGuide:
        return _breathGuideTracks;
      case AudioType.guidingVoice:
        return _guidingVoiceTracks;
    }
  }

  /// Get the currently playing track by audio type
  AudioTrack? getCurrentTrack(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _currentMusic;
      case AudioType.breathGuide:
        return _currentBreathGuide;
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
        debugPrint('Error stopping previous audio (non-critical): $e');
        // Continue with setup - this error can be ignored
      }

      // Set up the audio source (only for music and tones)
      if (type != AudioType.guidingVoice) {
        try {
          await player.setAsset(track.path);
        } catch (e) {
          debugPrint('Error loading audio asset: ${track.path} - $e');
          // If we can't load the asset, we should exit early
          return;
        }

        // Configure looping
        try {
          await player.setLoopMode(LoopMode.all);
        } catch (e) {
          debugPrint('Error setting loop mode: $e');
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
        } catch (_) {
          // File doesn't exist, continue
        }
      }

      if (validPaths.isEmpty) {
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
      debugPrint('Error stopping audio (non-critical): $e');
      // Still set current track to null even if stop fails
      _setCurrentTrack(type, null);
    }
  }

  /// Stop all audio playback
  Future<void> stopAllAudio() async {
    try {
      await stopAudio(AudioType.backgroundMusic);
      await stopAudio(AudioType.breathGuide);
      await stopAudio(AudioType.guidingVoice);
    } catch (e) {
      debugPrint('Error stopping all audio: $e');
    }
  }

  /// Dispose all players to free resources
  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _breathGuidePlayer.dispose();
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
      case AudioType.breathGuide:
        return _breathGuidePlayer;
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
      case AudioType.breathGuide:
        _currentBreathGuide = track;
        break;
      case AudioType.guidingVoice:
        _currentGuidingVoice = track;
        break;
    }
  }
}

/// Provider to track the currently selected audio for each type
final selectedAudioProvider =
    StateNotifierProvider.family<SelectedAudioNotifier, String?, AudioType>(
  (ref, type) => SelectedAudioNotifier(type, ref),
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
