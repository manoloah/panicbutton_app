// NEW: Breathing state persistence service for robust session and settings management
// Purpose:
// - Save/restore breathing session state (pattern, progress, phase, timing)
// - Save/restore audio settings (music, voice, instrument selections)
// - Automatric cleanup of old session data (older than 1 hour)
// - Lightweight persistence using SharedPreferences for cross-navigation state

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:panic_button_flutter/services/audio_service.dart';

/// Service for persisting breathing session state across navigation
class BreathingStatePersistenceService {
  static const String _keySessionState = 'breathing_session_state';
  static const String _keyAudioSettings = 'breathing_audio_settings';

  /// Save current session state
  static Future<void> saveSessionState({
    required String? patternId,
    required int duration,
    required int currentStepIndex,
    required double secondsRemaining,
    required int elapsedSeconds,
    required String currentPhase,
    required double phaseSecondsRemaining,
  }) async {
    try {
      debugPrint('💾 Saving breathing session state');

      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'patternId': patternId,
        'duration': duration,
        'currentStepIndex': currentStepIndex,
        'secondsRemaining': secondsRemaining,
        'elapsedSeconds': elapsedSeconds,
        'currentPhase': currentPhase,
        'phaseSecondsRemaining': phaseSecondsRemaining,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_keySessionState, json.encode(sessionData));
      debugPrint('💾 Session state saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving session state: $e');
    }
  }

  /// Load saved session state
  static Future<Map<String, dynamic>?> loadSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionDataJson = prefs.getString(_keySessionState);

      if (sessionDataJson == null) return null;

      final sessionData = json.decode(sessionDataJson) as Map<String, dynamic>;

      // Check if saved state is recent (within last hour)
      final timestamp = sessionData['timestamp'] as int?;
      if (timestamp != null) {
        final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(savedTime);

        if (difference.inHours > 1) {
          debugPrint('🗑️ Session state too old, clearing');
          await clearSessionState();
          return null;
        }
      }

      debugPrint('📂 Loaded breathing session state');
      return sessionData;
    } catch (e) {
      debugPrint('❌ Error loading session state: $e');
      return null;
    }
  }

  /// Clear saved session state
  static Future<void> clearSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySessionState);
      debugPrint('🗑️ Session state cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session state: $e');
    }
  }

  /// Save audio settings (music, voice, instrument selections)
  static Future<void> saveAudioSettings({
    required String? musicTrackId,
    required String? voiceTrackId,
    required Instrument instrument,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioData = {
        'musicTrackId': musicTrackId,
        'voiceTrackId': voiceTrackId,
        'instrument': instrument.name,
      };

      await prefs.setString(_keyAudioSettings, json.encode(audioData));
      debugPrint('💾 Audio settings saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving audio settings: $e');
    }
  }

  /// Load saved audio settings
  static Future<Map<String, dynamic>?> loadAudioSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioDataJson = prefs.getString(_keyAudioSettings);

      if (audioDataJson == null) return null;

      final audioData = json.decode(audioDataJson) as Map<String, dynamic>;
      debugPrint('📂 Loaded audio settings');
      return audioData;
    } catch (e) {
      debugPrint('❌ Error loading audio settings: $e');
      return null;
    }
  }
}
