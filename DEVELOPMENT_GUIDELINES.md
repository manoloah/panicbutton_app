---

### Audio Integration Best Practices

The app includes a comprehensive audio system for breathing exercises that follows these guidelines:

1. **Audio Layer Architecture**
   - The audio system uses a three-layer approach:
     - **Background Music**: Ambient sounds for relaxation (river, rain, forest)
     - **Breath Guide Tones**: Subtle audio cues for each breathing phase
     - **Voice Guidance**: Verbal instructions synchronized with breathing

2. **File Format & Organization**
   - **File Format**: Use MP3 over WAV for several advantages:
     - Significantly smaller file size (often 10x smaller)
     - Excellent quality-to-size ratio for voice and ambient sounds
     - Universal platform compatibility
     - Lower memory and CPU usage during playback
   - **Directory Structure**:
     ```
     assets/
     └── sounds/
         ├── music/      # Background ambient sounds
         ├── tones/      # Breathing phase indicator sounds
         └── voice/      # Voice guidance recordings
     ```
   - Register sound directories in `pubspec.yaml`:
     ```yaml
     assets:
       - assets/sounds/music/
       - assets/sounds/tones/
       - assets/sounds/voice/
     ```

3. **Safe Audio Management**
   - **Memory Leak Prevention**:
     - Store audio service references early in widget lifecycle:
       ```dart
       // In initState
       _audioService = ref.read(audioServiceProvider);
       ```
     - Add disposal flag to prevent accessing disposed widgets:
       ```dart
       bool _isDisposed = false;
       
       @override
       void dispose() {
         _isDisposed = true;
         super.dispose();
         // Use stored references instead of accessing providers
         if (_audioService != null) {
           _audioService!.stopAllAudio();
         }
       }
       ```
     - Always check disposal state before operations:
       ```dart
       if (_isDisposed) return;
       ```

   - **Provider Access Safety**:
     - Get all provider references upfront before async operations
     - Store references locally instead of accessing providers after async gaps
     - Add disposal checks after every await

4. **UI Integration**
   - Provide clear audio controls with proper labeling
   - Use bottom sheets for audio selection interfaces
   - Include visual feedback when audio tracks are playing
   - Initialize default tracks when none are selected

5. **Default Audio Selection Logic**
   ```dart
   void _initializeAudio() {
     if (_isDisposed) return;
     if (!_isAudioInitialized) {
       // Check if music is already playing
       final currentMusic = _audioService?.getCurrentTrack(AudioType.backgroundMusic);
       if (currentMusic == null) {
         // Start default background music
         ref.read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
            .selectTrack('river');
       }
       
       // Similar checks for tones and voice
       _isAudioInitialized = true;
     }
   }
   ```

6. **Audio Performance**
   - Preload audio files for key interactions
   - Handle audio focus changes (e.g., phone calls interrupting)
   - Add progressive volume transitions for smoother experience

7. **Testing Audio Integration**
   - Test navigation between screens multiple times to verify no leaks
   - Test device sleep/wake behavior with active audio
   - Test with different audio output devices (speaker, headphones)

Following these guidelines ensures audio integration that enhances the user experience while maintaining app stability and performance.

---

### Adding or Updating Sound Assets - Step by Step Guide

This guide explains the complete process for adding new sound files or replacing existing ones in the app.

#### 1. Prepare Your Sound Files

- **Format Requirements**:
  - Use MP3 format (preferred over WAV for size and performance)
  - Recommended bitrate: 192kbps for music, 128kbps for voice and tones
  - Maximum file size: Keep background music under 2MB, tones/voice under 500KB
  - Recommended duration:
    - Background music: 1-3 minutes (will loop automatically)
    - Tones: 1-3 seconds
    - Voice: Short phrases (2-5 seconds)
  
- **Audio Processing Tips**:
  - Normalize audio to -3dB peak level
  - Apply gentle compression (2:1 ratio) for voice recordings
  - Remove background noise and hiss
  - Add a short fade-in/fade-out (50-100ms) to prevent clicks
  - For looping music, ensure seamless loop points

#### 2. Add Sound Files to the Project

- **File Placement**:
  Place your prepared audio files in the appropriate directory based on type:
  
  ```
  panic_button_flutter/
  └── assets/
      └── sounds/
          ├── music/      # Place background music files here
          ├── tones/      # Place breath guide tone files here
          └── voice/      # Place voice guidance files here
  ```

- **File Naming Conventions**:
  - Use lowercase letters and underscores only
  - Use simple, descriptive names (e.g., `gentle_river.mp3`, `deep_tone.mp3`)
  - Avoid spaces, special characters, or version numbers in filenames
  
- **Example**:
  ```bash
  # Example command to copy a new music file to the correct location
  cp ~/Downloads/gentle_forest.mp3 panic_button_flutter/assets/sounds/music/
  ```

#### 3. Register New Files in the Audio Service

- **Update Track Lists**:
  Open `lib/services/audio_service.dart` and locate the appropriate track list constants:
  
  ```dart
  // For background music
  static const List<AudioTrackInfo> _backgroundMusicTracks = [
    AudioTrackInfo(id: 'river', name: 'Río', fileName: 'river.mp3'),
    AudioTrackInfo(id: 'forest', name: 'Bosque', fileName: 'forest_ambience.mp3'),
    // Add your new track here:
    AudioTrackInfo(id: 'gentle_forest', name: 'Bosque Suave', fileName: 'gentle_forest.mp3'),
  ];
  
  // For breath guide tones
  static const List<AudioTrackInfo> _breathGuideTracks = [
    AudioTrackInfo(id: 'sine', name: 'Suave', fileName: 'sine.mp3'),
    AudioTrackInfo(id: 'bowl', name: 'Cuenco', fileName: 'bowl.mp3'),
    // Add your new track here
  ];
  
  // For voice guidance
  static const List<AudioTrackInfo> _ambientSoundTracks = [
    AudioTrackInfo(id: 'davi', name: 'Davi', fileName: 'davi.mp3'),
    AudioTrackInfo(id: 'bryan', name: 'Bryan', fileName: 'bryan.mp3'),
    // Add your new track here
  ];
  ```

- **Important Properties**:
  - `id`: Unique identifier used in code (lowercase, no spaces)
  - `name`: Display name shown to users (use Spanish for user-facing text)
  - `fileName`: Exact filename including extension, must match file in assets folder

#### 4. Update Default Sound Selection (Optional)

If you want to change the default sounds that play when the breathing exercise starts:

- Open `lib/screens/breath_screen.dart`
- Locate the `_initializeAudio()` method
- Update the default track IDs:

```dart
void _initializeAudio() {
  if (_isDisposed) return;
  if (!_isAudioInitialized) {
    // Check if music is already playing
    final currentMusic = _audioService?.getCurrentTrack(AudioType.backgroundMusic);
    if (currentMusic == null) {
      // Change 'river' to your new default music ID
      ref.read(selectedAudioProvider(AudioType.backgroundMusic).notifier)
          .selectTrack('gentle_forest');
    }
    
    // Similar changes for tones and voice if needed
    final currentTone = _audioService?.getCurrentTrack(AudioType.breathGuide);
    if (currentTone == null) {
      ref.read(selectedAudioProvider(AudioType.breathGuide).notifier)
          .selectTrack('sine');
    }
    
    final currentVoice = _audioService?.getCurrentTrack(AudioType.ambientSound);
    if (currentVoice == null) {
      ref.read(selectedAudioProvider(AudioType.ambientSound).notifier)
          .selectTrack('davi');
    }
    
    _isAudioInitialized = true;
  }
}
```

#### 5. Verify Asset Registration in pubspec.yaml

Ensure the sound directories are properly registered in your `pubspec.yaml` file:

```yaml
flutter:
  assets:
    - assets/sounds/music/
    - assets/sounds/tones/
    - assets/sounds/voice/
```

#### 6. Replacing Existing Sound Files

To replace an existing sound while keeping the same name and functionality:

1. Prepare your new sound file following the format guidelines above
2. Name the file exactly the same as the file you're replacing
3. Copy the new file to the appropriate directory, overwriting the existing file:

```bash
# Example: Replacing the river.mp3 background music
cp ~/Downloads/new_river_sound.mp3 panic_button_flutter/assets/sounds/music/river.mp3
```

This approach requires no code changes since the filename stays the same.

#### 7. Testing Your Sound Changes

After adding or replacing sound files:

1. **Clean and rebuild the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test all audio features**:
   - Verify that new sounds appear in the audio selection sheet
   - Test playback of all new and modified sound files
   - Check that audio controls work correctly for new sounds
   - Verify that default sounds play when starting a breathing exercise

#### 8. Troubleshooting Common Issues

- **Sound not playing**:
  - Verify the file is in the correct directory
  - Check that the filename in code exactly matches the actual file (case-sensitive)
  - Ensure the MP3 file is valid and playable on other devices
  - Run `flutter clean` and rebuild

- **Sound not appearing in selection sheet**:
  - Verify the track is added to the correct track list in `audio_service.dart`
  - Check that the ID, name, and filename are all properly specified

- **Sound plays but cuts off or sounds distorted**:
  - Verify the audio quality of the source file
  - Check that normalization and processing were done correctly
  - Ensure file is not corrupted during copying

By following these steps, you can easily add new sounds or replace existing ones in the app's breathing exercise feature.

--- 