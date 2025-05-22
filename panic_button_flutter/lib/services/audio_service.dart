import 'package:flutter/material.dart';
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
  ambientSound,
}

/// Service for managing audio playback in the app
class AudioService {
  // Audio players for different audio types
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _breathGuidePlayer = AudioPlayer();
  final AudioPlayer _ambientSoundPlayer = AudioPlayer();

  // Track currently playing for each type
  AudioTrack? _currentMusic;
  AudioTrack? _currentBreathGuide;
  AudioTrack? _currentAmbientSound;

  // Available audio tracks
  final List<AudioTrack> _musicTracks = [
    const AudioTrack(
      id: 'calm_ocean',
      name: 'Océano Tranquilo',
      path: 'assets/sounds/music/calm_ocean.mp3',
      icon: Icons.water,
    ),
    const AudioTrack(
      id: 'forest_ambience',
      name: 'Bosque',
      path: 'assets/sounds/music/forest_ambience.mp3',
      icon: Icons.forest,
    ),
    const AudioTrack(
      id: 'meditation_bells',
      name: 'Campanas',
      path: 'assets/sounds/music/meditation_bells.mp3',
      icon: Icons.notifications,
    ),
    const AudioTrack(
      id: 'off',
      name: 'Apagado',
      path: '',
      icon: Icons.volume_off,
    ),
  ];

  // Breath guide audio tracks (stub for future implementation)
  final List<AudioTrack> _breathGuideTracks = [
    const AudioTrack(
      id: 'off',
      name: 'Apagado',
      path: '',
      icon: Icons.volume_off,
    ),
  ];

  // Ambient sound tracks (stub for future implementation)
  final List<AudioTrack> _ambientSoundTracks = [
    const AudioTrack(
      id: 'off',
      name: 'Apagado',
      path: '',
      icon: Icons.volume_off,
    ),
  ];

  AudioService() {
    _initAudioSession();
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

  /// Get the list of available tracks by audio type
  List<AudioTrack> getTracksByType(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _musicTracks;
      case AudioType.breathGuide:
        return _breathGuideTracks;
      case AudioType.ambientSound:
        return _ambientSoundTracks;
    }
  }

  /// Get the currently playing track by audio type
  AudioTrack? getCurrentTrack(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _currentMusic;
      case AudioType.breathGuide:
        return _currentBreathGuide;
      case AudioType.ambientSound:
        return _currentAmbientSound;
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

      // Set up the audio source
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

      // Update current track
      _setCurrentTrack(type, track);
    } catch (e) {
      debugPrint('General error in audio playback: $e');
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
      await stopAudio(AudioType.ambientSound);
    } catch (e) {
      debugPrint('Error stopping all audio: $e');
    }
  }

  /// Dispose all players to free resources
  Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
      await _breathGuidePlayer.dispose();
      await _ambientSoundPlayer.dispose();
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
      case AudioType.ambientSound:
        return _ambientSoundPlayer;
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
      case AudioType.ambientSound:
        _currentAmbientSound = track;
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
