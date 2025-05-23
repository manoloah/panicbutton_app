# Guiding Voices for Breathing Exercises

This directory contains voice prompts for the breathing exercises in the app. For complete implementation details, see the "Guiding Voice Implementation" section in `DEVELOPMENT_GUIDELINES.md`.

## Structure

Each character has their own folder with specific subfolders for different breathing phases:

```
guiding_voices/
  |
  ├── manu/
  │   ├── inhale/              # Prompts for inhale phase
  │   ├── pause_after_inhale/  # Prompts for hold after inhaling
  │   ├── exhale/              # Prompts for exhale phase
  │   └── pause_after_exhale/  # Prompts for hold after exhaling
  │
  └── andrea/
      ├── inhale/
      ├── pause_after_inhale/
      ├── exhale/
      └── pause_after_exhale/
```

## File Naming Convention

Files in each phase folder should be named with a number followed by `.mp3`:

```
1.mp3, 2.mp3, 3.mp3, etc.
```

The app will choose randomly from available prompts in each phase folder to avoid repetition.

## Adding a New Voice Character

To add a new guiding voice:

1. Create a new folder with the character's name (e.g., `carlos/`)
2. Inside, create the four phase subfolders:
   - `inhale/`
   - `pause_after_inhale/`
   - `exhale/`
   - `pause_after_exhale/`
3. Add MP3 files to each phase folder, using the naming convention above
4. Register all new folders in `pubspec.yaml` under the `assets` section:
   ```yaml
   - assets/sounds/guiding_voices/carlos/
   - assets/sounds/guiding_voices/carlos/inhale/
   - assets/sounds/guiding_voices/carlos/pause_after_inhale/
   - assets/sounds/guiding_voices/carlos/exhale/
   - assets/sounds/guiding_voices/carlos/pause_after_exhale/
   ```

The character will automatically appear in the audio selection UI.

## Guidelines for Voice Recordings

- Keep prompts short (2-5 seconds)
- Use clear, calming voice tone
- Record in a quiet environment
- Normalize audio levels before adding
- Use MP3 format at 128kbps for good quality and reasonable file size 

## Voice Prompt Suggestions

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

## Troubleshooting

- If prompts don't play, check that files exist in the correct folders
- Verify the folder structure matches exactly what's described above
- Ensure all folders are registered in pubspec.yaml
- Test with simple placeholder files first, then replace with real recordings
- Enable debugging in the AudioService class for more detailed error messages 