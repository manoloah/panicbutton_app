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