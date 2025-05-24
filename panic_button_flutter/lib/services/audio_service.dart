import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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

/// Available instruments for breathing cues
enum Instrument {
  gong,
  synth,
  violin,
  human,
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
  holdIn, // Retention - no sound
  holdOut, // Retention - no sound
}

/// Simplified audio service with single responsibility
class AudioService {
  // Single audio player per audio type - much simpler
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _instrumentPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();

  // Simple state tracking
  bool _disposed = false;
  String? _currentInstrument;
  String? _currentVoice;
  String? _currentMusic;
  Timer? _instrumentTimer;

  // Track configurations
  late final List<AudioTrack> _musicTracks;
  late final List<AudioTrack> _instrumentTracks;
  late final List<AudioTrack> _voiceTracks;

  // Cache available voice files to avoid repeated asset loading attempts
  final Map<String, List<int>> _availableVoiceFiles = {};

  AudioService() {
    _initializeTracks();
    _setupAudioSession();
    _setupErrorHandling();
    _preloadAvailableVoiceFiles();
  }

  /// Initialize track configurations
  void _initializeTracks() {
    _musicTracks = [
      const AudioTrack(
        id: 'river',
        name: 'Río',
        path: 'assets/sounds/music/river.mp3',
        icon: Icons.water_rounded,
      ),
      const AudioTrack(
        id: 'forest',
        name: 'Bosque',
        path: 'assets/sounds/music/rainforest.mp3',
        icon: Icons.forest,
      ),
      const AudioTrack(
        id: 'ocean',
        name: 'Océano',
        path: 'assets/sounds/music/ocean.mp3',
        icon: Icons.waves,
      ),
      const AudioTrack(
        id: 'off',
        name: 'Apagado',
        path: '',
        icon: Icons.horizontal_rule,
      ),
    ];

    _instrumentTracks = [
      const AudioTrack(
        id: 'gong',
        name: 'Gong',
        path: 'assets/sounds/instrument_cues/gong',
        icon: Icons.water_drop,
      ),
      const AudioTrack(
        id: 'synth',
        name: 'Sintetizador',
        path: 'assets/sounds/instrument_cues/synth',
        icon: Icons.piano,
      ),
      const AudioTrack(
        id: 'violin',
        name: 'Violín',
        path: 'assets/sounds/instrument_cues/violin',
        icon: Icons.music_note,
      ),
      const AudioTrack(
        id: 'human',
        name: 'Humano',
        path: 'assets/sounds/instrument_cues/human',
        icon: Icons.mic,
      ),
      const AudioTrack(
        id: 'off',
        name: 'Apagado',
        path: '',
        icon: Icons.horizontal_rule,
      ),
    ];

    _voiceTracks = [
      const AudioTrack(
        id: 'manu',
        name: 'Manu',
        path: 'assets/sounds/guiding_voices/manu',
        icon: Icons.person,
      ),
      const AudioTrack(
        id: 'andrea',
        name: 'Andrea',
        path: 'assets/sounds/guiding_voices/andrea',
        icon: Icons.person,
      ),
      const AudioTrack(
        id: 'off',
        name: 'Apagado',
        path: '',
        icon: Icons.horizontal_rule,
      ),
    ];
  }

  /// Preload information about available voice files to avoid runtime errors
  Future<void> _preloadAvailableVoiceFiles() async {
    try {
      for (final voice in ['manu', 'andrea']) {
        for (final phase in [
          'inhale',
          'exhale',
          'pause_after_inhale',
          'pause_after_exhale'
        ]) {
          final List<int> availableFiles = [];

          // Check files 1-10 to be safe (though we know the current structure)
          for (int i = 1; i <= 10; i++) {
            final path = 'assets/sounds/guiding_voices/$voice/$phase/$i.mp3';
            try {
              await rootBundle.load(path);
              availableFiles.add(i);
            } catch (e) {
              // File doesn't exist, skip
              break; // Stop checking higher numbers if this one doesn't exist
            }
          }

          if (availableFiles.isNotEmpty) {
            _availableVoiceFiles['$voice:$phase'] = availableFiles;
            debugPrint(
                '🔍 Found ${availableFiles.length} voice files for $voice/$phase: $availableFiles');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error preloading voice files: $e');
    }
  }

  /// Setup audio session for iOS compatibility
  Future<void> _setupAudioSession() async {
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
      await session.setActive(true);
      debugPrint('🔊 Audio session configured');
    } catch (e) {
      debugPrint('⚠️ Audio session setup failed: $e');
    }
  }

  /// Simple error handling setup
  void _setupErrorHandling() {
    _musicPlayer.playbackEventStream.listen(
      (event) {},
      onError: (e, stackTrace) => debugPrint('Music player error: $e'),
    );

    _instrumentPlayer.playbackEventStream.listen(
      (event) {},
      onError: (e, stackTrace) => debugPrint('Instrument player error: $e'),
    );

    _voicePlayer.playbackEventStream.listen(
      (event) {},
      onError: (e, stackTrace) => debugPrint('Voice player error: $e'),
    );
  }

  /// Get tracks by audio type
  List<AudioTrack> getTracksByType(AudioType type) {
    switch (type) {
      case AudioType.backgroundMusic:
        return _musicTracks;
      case AudioType.instrumentCue:
        return _instrumentTracks;
      case AudioType.guidingVoice:
        return _voiceTracks;
    }
  }

  /// Play a track by type and ID
  Future<void> playTrack(AudioType type, String trackId) async {
    if (_disposed) return;

    final tracks = getTracksByType(type);
    final track =
        tracks.firstWhere((t) => t.id == trackId, orElse: () => tracks.first);

    // Handle "off" selection
    if (track.id == 'off') {
      await stopAudio(type);
      // Update current track state for "off"
      switch (type) {
        case AudioType.backgroundMusic:
          _currentMusic = 'off';
          break;
        case AudioType.instrumentCue:
          _currentInstrument = 'off';
          break;
        case AudioType.guidingVoice:
          _currentVoice = 'off';
          break;
      }
      return;
    }

    try {
      // Only set up audio source for background music (not instrument cues or voices)
      if (type == AudioType.backgroundMusic) {
        await _musicPlayer.stop();
        await _musicPlayer.setAsset(track.path);
        await _musicPlayer.setLoopMode(LoopMode.all);
        await _musicPlayer.setVolume(0.7);
        await _musicPlayer.play();
        _currentMusic = trackId;
        debugPrint('🎵 Playing ${track.name}');
      }

      // For instrument cues, just store the selection
      if (type == AudioType.instrumentCue) {
        _currentInstrument = trackId;
        debugPrint('🎼 Selected instrument: ${track.name}');
      }

      // For voice tracks, just store the selection
      if (type == AudioType.guidingVoice) {
        _currentVoice = trackId;
        debugPrint('🗣️ Selected voice: ${track.name}');
      }
    } catch (e) {
      debugPrint('❌ Error playing track ${track.name}: $e');
    }
  }

  /// Play instrument cue for breathing phase - IMPROVED
  Future<void> playInstrumentCue({
    required Instrument instrument,
    required BreathInstrumentPhase phase,
    required int durationSeconds,
  }) async {
    if (_disposed || _currentInstrument == 'off') return;

    // Stop audio for retention phases
    if (phase == BreathInstrumentPhase.holdIn ||
        phase == BreathInstrumentPhase.holdOut) {
      await _stopInstrumentAudio();
      return;
    }

    try {
      // Cancel any existing timer
      _instrumentTimer?.cancel();

      // Build file path
      final phaseName =
          phase == BreathInstrumentPhase.inhale ? 'inhale' : 'exhale';
      final instrumentName = instrument.name;
      final filePath =
          'assets/sounds/instrument_cues/$instrumentName/${phaseName}_$instrumentName.mp3';

      debugPrint(
          '🎵 Playing instrument cue: $filePath for ${durationSeconds}s');

      // Use asset-based loading instead of BytesAudioSource to avoid platform conflicts
      await _instrumentPlayer.stop();
      await _instrumentPlayer.setAsset(filePath);

      // Get audio duration to decide on looping
      await _instrumentPlayer.load();
      final audioDuration = _instrumentPlayer.duration?.inSeconds ?? 1;

      // Loop if audio is shorter than needed duration
      if (audioDuration < durationSeconds) {
        await _instrumentPlayer.setLoopMode(LoopMode.all);
      } else {
        await _instrumentPlayer.setLoopMode(LoopMode.off);
      }

      await _instrumentPlayer.setVolume(0.8);
      await _instrumentPlayer.play();

      // Set timer to stop after duration
      _instrumentTimer = Timer(Duration(seconds: durationSeconds), () async {
        await _stopInstrumentAudio();
      });
    } catch (e) {
      debugPrint('❌ Error playing instrument cue: $e');
      // Don't rethrow - let the breathing continue
    }
  }

  /// Play voice prompt - COMPLETELY FIXED
  Future<void> playVoicePrompt(BreathVoicePhase phase) async {
    if (_disposed || _currentVoice == 'off' || _currentVoice == null) return;

    try {
      // Get phase folder name
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

      // Get available files for this voice and phase
      final cacheKey = '$_currentVoice:$phaseFolder';
      final availableFiles = _availableVoiceFiles[cacheKey];

      if (availableFiles == null || availableFiles.isEmpty) {
        debugPrint(
            '⚠️ No voice files available for $_currentVoice/$phaseFolder');
        return;
      }

      // Select random file from available files
      final randomIndex = Random().nextInt(availableFiles.length);
      final selectedFile = availableFiles[randomIndex];

      final voiceTrack = _voiceTracks.firstWhere(
        (track) => track.id == _currentVoice,
        orElse: () => _voiceTracks.first,
      );

      if (voiceTrack.id == 'off') return;

      final filePath = '${voiceTrack.path}/$phaseFolder/$selectedFile.mp3';

      // Stop previous voice prompt gently (to avoid Operation Stopped errors)
      if (_voicePlayer.playing) {
        await _voicePlayer.stop();
        // Small delay to let the previous operation complete
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await _voicePlayer.setAsset(filePath);
      await _voicePlayer.setLoopMode(LoopMode.off);
      await _voicePlayer.setVolume(1.0);
      await _voicePlayer.play();

      debugPrint(
          '🗣️ Playing voice prompt: $filePath (file $selectedFile of ${availableFiles.length} available)');
    } catch (e) {
      debugPrint('⚠️ Voice prompt error (non-critical): $e');
      // Don't rethrow - voice prompts are non-critical
    }
  }

  /// Stop instrument audio
  Future<void> _stopInstrumentAudio() async {
    try {
      _instrumentTimer?.cancel();
      _instrumentTimer = null;
      await _instrumentPlayer.stop();
      await _instrumentPlayer.setLoopMode(LoopMode.off);
      debugPrint('⏹️ Stopped instrument audio');
    } catch (e) {
      debugPrint('⚠️ Error stopping instrument audio: $e');
    }
  }

  /// Stop all instrument cues (public method)
  Future<void> stopInstrumentCues() async {
    await _stopInstrumentAudio();
  }

  /// Stop audio by type
  Future<void> stopAudio(AudioType type) async {
    if (_disposed) return;

    try {
      switch (type) {
        case AudioType.backgroundMusic:
          await _musicPlayer.stop();
          break;
        case AudioType.instrumentCue:
          await _stopInstrumentAudio();
          break;
        case AudioType.guidingVoice:
          await _voicePlayer.stop();
          break;
      }
      debugPrint('⏹️ Stopped ${type.name} audio');
    } catch (e) {
      debugPrint('⚠️ Error stopping ${type.name}: $e');
    }
  }

  /// Stop all audio
  Future<void> stopAllAudio() async {
    if (_disposed) return;

    await Future.wait([
      _musicPlayer.stop().catchError((e) => debugPrint('Music stop error: $e')),
      _stopInstrumentAudio(),
      _voicePlayer.stop().catchError((e) => debugPrint('Voice stop error: $e')),
    ]);

    debugPrint('⏹️ Stopped all audio');
  }

  /// Reset instrument state (for exercise changes) - but preserve selections
  Future<void> resetInstrumentCueState() async {
    await _stopInstrumentAudio();
    debugPrint('🔄 Reset instrument cue state (preserving selections)');
  }

  /// Get current track for a type - FIXED IMPLEMENTATION
  AudioTrack? getCurrentTrack(AudioType type) {
    String? currentId;
    List<AudioTrack> tracks;

    switch (type) {
      case AudioType.backgroundMusic:
        currentId = _currentMusic;
        tracks = _musicTracks;
        break;
      case AudioType.instrumentCue:
        currentId = _currentInstrument;
        tracks = _instrumentTracks;
        break;
      case AudioType.guidingVoice:
        currentId = _currentVoice;
        tracks = _voiceTracks;
        break;
    }

    if (currentId == null) return null;

    try {
      return tracks.firstWhere((track) => track.id == currentId);
    } catch (e) {
      return null;
    }
  }

  /// Dispose all resources
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _instrumentTimer?.cancel();

    await Future.wait([
      _musicPlayer
          .dispose()
          .catchError((e) => debugPrint('Music dispose error: $e')),
      _instrumentPlayer
          .dispose()
          .catchError((e) => debugPrint('Instrument dispose error: $e')),
      _voicePlayer
          .dispose()
          .catchError((e) => debugPrint('Voice dispose error: $e')),
    ]);

    debugPrint('🗑️ Audio service disposed');
  }
}

/// Provider to track selected audio for each type
final selectedAudioProvider =
    StateNotifierProvider.family<SelectedAudioNotifier, String?, AudioType>(
  (ref, type) => SelectedAudioNotifier(type, ref),
);

/// Provider for persistent instrument cue state
final persistentInstrumentCueProvider = StateProvider<String?>((ref) => 'gong');

/// Notifier to manage selected audio state
class SelectedAudioNotifier extends StateNotifier<String?> {
  final AudioType type;
  final Ref ref;

  SelectedAudioNotifier(this.type, this.ref) : super(null) {
    if (type == AudioType.instrumentCue) {
      state = ref.read(persistentInstrumentCueProvider);
    }
  }

  Future<void> selectTrack(String trackId) async {
    state = trackId;

    if (type == AudioType.instrumentCue) {
      ref.read(persistentInstrumentCueProvider.notifier).state = trackId;
    }

    await ref.read(audioServiceProvider).playTrack(type, trackId);
  }

  void updateStateOnly(String trackId) {
    state = trackId;

    if (type == AudioType.instrumentCue) {
      ref.read(persistentInstrumentCueProvider.notifier).state = trackId;
    }
  }
}
