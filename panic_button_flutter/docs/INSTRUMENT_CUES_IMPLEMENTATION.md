# Instrument Cues Implementation

## Overview

The instrument cues feature provides audio cues during breathing exercises that play at the start of inhale and exhale phases. This implementation replaces the previous "tones" system with a more sophisticated instrument-based approach.

## Key Features

- **Phase-Specific Playback**: Instrument cues play only at the start of inhale and exhale phases
- **Precise Timing Control**: Cues stop exactly when the phase changes, even if the audio file is longer
- **No Hold Phase Audio**: No cues play during hold phases (pause after inhale/exhale)
- **Multiple Instruments**: Support for gong, synth, violin, human, and off options
- **Persistent Preferences**: User's selected instrument persists across sessions
- **Platform Compatibility**: Works on Android, iOS, and Web

## Architecture

### Enums

```dart
enum AudioType {
  backgroundMusic,
  instrumentCue, // Replaced breathGuide
  guidingVoice,
}

enum Instrument {
  gong,
  synth,
  violin,
  human,
  off,
}

enum BreathInstrumentPhase {
  inhale,
  exhale,
}
```

### Audio Service Changes

1. **Replaced `_breathGuidePlayer`** with `_instrumentPlayer`
2. **Added `playInstrumentCue` method** with precise timing control
3. **Added timer management** for stopping cues at phase transitions
4. **Updated track management** for instrument cues

### Key Methods

#### `playInstrumentCue(Instrument, BreathInstrumentPhase, int)`
- Stops any currently playing instrument cue
- Builds asset path based on instrument and phase
- Handles timing: if audio is longer than phase duration, schedules stop at phase end
- If audio is shorter, plays once without looping

#### Asset Path Structure
```
assets/sounds/instrument_cues/{instrument}/{phase}_{instrument}.mp3
```

Examples:
- `assets/sounds/instrument_cues/gong/inhale_gong.mp3`
- `assets/sounds/instrument_cues/synth/exhale_synth.mp3`

### Breathing Playback Controller Integration

The `BreathingPlaybackController` was updated to trigger instrument cues:

1. **Phase Detection**: In `_moveToNextPhase()`, detects when entering inhale/exhale phases
2. **Instrument Triggering**: Calls `_playInstrumentCueForPhase()` for inhale/exhale phases only
3. **Phase Conversion**: Converts `BreathPhase` to `BreathInstrumentPhase`

### UI Changes

#### Audio Selection Sheet
- **Replaced "Tonos" section** with "Instrumentos" section
- **Added `_InstrumentSelectionGrid`** widget for instrument selection
- **Added `_InstrumentOptionButton`** for individual instrument options
- **Visual feedback** for selected instrument with primary color highlighting

#### Default Settings
- **Default instrument**: Gong (if none selected)
- **Automatic selection**: Set in `_setDefaultAudioIfNeeded()` method

### State Management

#### Providers
```dart
// Provider for selected instrument
final selectedInstrumentProvider = StateNotifierProvider<SelectedInstrumentNotifier, Instrument>

// Notifier for instrument state
class SelectedInstrumentNotifier extends StateNotifier<Instrument>
```

### Asset Management

#### Directory Structure
```
assets/sounds/instrument_cues/
├── gong/
│   ├── inhale_gong.mp3
│   └── exhale_gong.mp3
├── synth/
│   ├── inhale_synth.mp3
│   └── exhale_synth.mp3
├── violin/
│   ├── inhale_violin.mp3
│   └── exhale_violin.mp3
└── human/
    ├── inhale_human.mp3
    └── exhale_human.mp3
```

#### pubspec.yaml Registration
```yaml
assets:
  - assets/sounds/instrument_cues/
  - assets/sounds/instrument_cues/gong/
  - assets/sounds/instrument_cues/synth/
  - assets/sounds/instrument_cues/violin/
  - assets/sounds/instrument_cues/human/
```

## Implementation Details

### Timing Control
- **Timer Management**: Uses `Timer` to stop audio at precise phase transitions
- **Duration Handling**: Compares audio file duration with phase duration
- **Cleanup**: Properly cancels timers on disposal and phase changes

### Error Handling
- **Graceful Degradation**: Continues breathing exercise even if audio fails
- **Asset Loading**: Handles missing audio files without crashing
- **Platform Compatibility**: Works across different platforms with fallbacks

### Memory Management
- **Timer Cleanup**: Cancels `_instrumentStopTimer` in dispose methods
- **Player Management**: Properly stops and disposes audio players
- **Resource Cleanup**: Prevents memory leaks during rapid phase changes

## Migration from Tones

### Removed Components
- `AudioType.breathGuide` → `AudioType.instrumentCue`
- `_breathGuidePlayer` → `_instrumentPlayer`
- `_breathGuideTracks` → `_instrumentTracks`
- Tones asset directory and references

### Updated Components
- **Audio Selection UI**: Replaced tones section with instruments
- **Default Settings**: Changed from sine tone to gong instrument
- **State Management**: Added instrument-specific providers
- **Asset Structure**: New directory structure for instrument cues

## Usage

### For Users
1. Open breathing exercise screen
2. Tap music note icon to open audio settings
3. Select preferred instrument from "Instrumentos" section
4. Start breathing exercise - instrument cues will play at inhale/exhale starts

### For Developers
1. **Adding New Instruments**: 
   - Add to `Instrument` enum
   - Create asset directory with inhale/exhale files
   - Register in pubspec.yaml
   - Add to UI instrument list

2. **Customizing Timing**:
   - Modify `playInstrumentCue` method for different timing behaviors
   - Adjust volume levels in the method

## Testing

The implementation has been tested for:
- ✅ Compilation success (Flutter build web)
- ✅ Static analysis (Flutter analyze)
- ✅ Asset loading (placeholder files created)
- ✅ UI integration (instrument selection works)
- ✅ State persistence (instrument selection persists)

## Future Enhancements

1. **Custom Audio Upload**: Allow users to upload their own instrument sounds
2. **Volume Control**: Individual volume control for instrument cues
3. **Fade Effects**: Add fade in/out effects for smoother transitions
4. **Multiple Cues**: Support for different cues per breathing pattern
5. **Haptic Feedback**: Add vibration cues alongside audio cues 