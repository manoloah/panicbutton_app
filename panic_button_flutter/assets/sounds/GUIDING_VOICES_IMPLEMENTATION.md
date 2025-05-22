# Guiding Voices Implementation

## Overview

The guiding voices feature provides verbal guidance during breathing exercises, with:

- Support for multiple voice characters (Manu, Andrea, etc.)
- Phase-specific voice prompts (inhale, exhale, etc.)
- Random selection of prompts to avoid repetition
- Easy extensibility for adding new voice characters

## Architecture

### Folder Structure

```
assets/sounds/guiding_voices/
  ├── manu/
  │   ├── inhale/
  │   ├── pause_after_inhale/
  │   ├── exhale/
  │   └── pause_after_exhale/
  └── andrea/
      ├── inhale/
      ├── pause_after_inhale/
      ├── exhale/
      └── pause_after_exhale/
```

### Implementation Components

1. **AudioService Class**
   - Handles loading and playing of all audio types
   - Maintains separate players for background music, tones, and voice prompts
   - Provides methods for selecting random prompts
   - Avoids repetition with prompt tracking

2. **BreathingPlaybackController**
   - Triggers voice prompts at phase transitions
   - Converts BreathPhase to BreathVoicePhase for correct prompt selection

3. **Audio Selection UI**
   - Displays available guiding voices in a dedicated section
   - Allows users to select their preferred voice character

## How Voice Prompt Playback Works

1. When a breathing phase changes (e.g., inhale → hold), the `_moveToNextPhase()` method in `BreathingPlaybackController` triggers
2. It calls `_playVoicePromptForPhase()` with the new phase
3. This converts the breathing phase to the appropriate voice phase
4. The `playVoicePrompt()` method in `AudioService` is called
5. The system looks for MP3 files in the appropriate character's folder and phase subfolder
6. A random prompt is selected (avoiding recently played ones)
7. The prompt plays over any background music or tones

## Default Voice Settings

By default, **Manu** is set as the guiding voice when a user first starts the app. This is defined in two places:

1. **Voice Order in UI**: The order of voices in the UI is determined in `AudioService._initGuidingVoices()`:
   ```dart
   _guidingVoiceTracks = [
     // Manu is first (leftmost)
     const AudioTrack(
       id: 'manu',
       name: "Manu",
       path: 'assets/sounds/guiding_voices/manu',
       icon: Icons.person,
     ),
     // Andrea is second
     const AudioTrack(
       id: 'andrea',
       name: "Andrea",
       path: 'assets/sounds/guiding_voices/andrea',
       icon: Icons.person,
     ),
     // Off option last (rightmost)
     const AudioTrack(
       id: 'off',
       name: "Apagado",
       path: '',
       icon: Icons.horizontal_rule,
     ),
   ];
   ```

2. **Default Selection**: The default voice is set in `BreathScreen._initializeAudio()`:
   ```dart
   // Set default guiding voice if none is playing
   final currentVoice = _audioService?.getCurrentTrack(AudioType.guidingVoice);
   if (currentVoice == null) {
     // Start manu as default voice
     ref
         .read(selectedAudioProvider(AudioType.guidingVoice).notifier)
         .selectTrack('manu');
   }
   ```

### Changing the Default Voice

To change the default voice character:

1. Locate `BreathScreen._initializeAudio()` in `lib/screens/breath_screen.dart`
2. Change the `selectTrack('manu')` line to your preferred default voice ID:
   ```dart
   .selectTrack('andrea'); // Change to 'andrea' or another voice ID
   ```

To add a new voice character, follow the process in the next section.

## Adding a New Voice Character

1. **Create the folder structure:**
   ```
   assets/sounds/guiding_voices/[character_name]/
     ├── inhale/
     ├── pause_after_inhale/
     ├── exhale/
     └── pause_after_exhale/
   ```

2. **Add MP3 prompts to each phase folder:**
   - Name files `1.mp3`, `2.mp3`, etc.
   - Keep prompts short (2-5 seconds)
   - Normalize audio and use 128kbps MP3 format

3. **Register folders in pubspec.yaml:**
   ```yaml
   assets:
     - assets/sounds/guiding_voices/[character_name]/
     - assets/sounds/guiding_voices/[character_name]/inhale/
     - assets/sounds/guiding_voices/[character_name]/pause_after_inhale/
     - assets/sounds/guiding_voices/[character_name]/exhale/
     - assets/sounds/guiding_voices/[character_name]/pause_after_exhale/
   ```

4. **That's it!** The character will automatically appear in the audio selection UI.

## File Naming and Format

- Use simple numeric names: `1.mp3`, `2.mp3`, etc.
- The system will randomly select from available files
- Ensure files are properly normalized and compressed
- Keep file sizes small (< 100KB per prompt)

## Voice Recording Guidelines

- Use a clear, calm voice with appropriate pacing
- Record in a quiet environment with good acoustics
- Use simple, direct language for prompts
- Process audio to normalize levels and remove background noise

## Troubleshooting

- If prompts don't play, check that files exist in the correct folders
- Verify the folder structure matches exactly what's described above
- Ensure all folders are registered in pubspec.yaml
- Test with simple placeholder files first, then replace with real recordings

## Prompt Suggestions

### Inhale
- "Inhala profundamente"
- "Respira hondo"
- "Toma aire lentamente"

### Pause After Inhale
- "Mantén el aire"
- "Retén la respiración"
- "Sostén unos segundos"

### Exhale
- "Exhala suavemente"
- "Suelta el aire"
- "Deja salir la respiración"

### Pause After Exhale
- "Relájate"
- "Descansa un momento"
- "Pausa brevemente" 