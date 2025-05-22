# panicbutton_app
An app that helps you stop a panic attack and build resilience to stop it from occurring again with breathwork and other mind and body exercises. 

## Recent UI Improvements

The app has undergone several UI enhancements to improve usability across different device sizes:

### Home Screen
- Optimized the main "EMPEZAR" button size for different screen dimensions
- Added responsive scaling for the button based on device width
- Improved text alignment and spacing for the headline text
- Added bottom padding to prevent content overlap with the navbar

### Breathing Exercise Screen
- Redesigned the breathing circle with responsive sizing
- Removed redundant title text for a cleaner, more focused interface
- Repositioned the play/pause button for better visibility
- Implemented a clean, minimal app bar design

### Breathing Pattern Selection
- Reorganized goal categories into a two-row grid layout
- Implemented custom sorting order for breathing goals (Calma, Equilibrio, Enfoque, Energia)
- Improved sheet height constraints for better visibility
- Enhanced card layout for breathing patterns with clearer visual hierarchy

These improvements ensure the app provides a consistent, user-friendly experience across various iOS and Android devices, with special attention to smaller screens like the iPhone SE. 

## Breathing Exercise Feature

The app's breathing exercise feature provides a guided breathing experience with:

1. **Pattern Selection**: 
   - Choose from various breathing patterns based on goals (calming, focus, energy)
   - Each pattern has specific inhale, hold, exhale, and relax timings
   - The coherent_4_6 pattern is set as the default pattern

2. **Duration Selection**:
   - Choose from 3, 5, or 10 minutes (or pattern-recommended duration)
   - Sessions automatically calculate required breathing cycles

3. **Visual Guidance**:
   - Animated circle expands and contracts with your breath
   - Beautiful wave animation represents lung capacity
   - Clear phase indicators (Inhale, Hold, Exhale, Relax)
   - Countdown timers for each phase

4. **Audio Experience**:
   - Multi-layered audio guidance with three customizable sound types:
     - Background music: Ambient sounds like river, rain, forest
     - Breath guide tones: Subtle sounds that indicate breathing phases
     - Voice guidance: Calming voice instructions for each phase
   - Default sounds automatically applied (river, sine tone, davi)
   - Accessible audio controls via the music icon in the app bar
   - Sounds synchronized with breathing phases for immersive experience
   - Safe audio management that prevents memory leaks during navigation

5. **Session Tracking**:
   - Records completed patterns with accurate duration tracking
   - Supports pause and resume functionality
   - Maintains detailed statistics including total breathing time
   - Tracks cumulative practice across patterns

6. **Auto-Start Behavior**:
   - Breathing exercise auto-starts ONLY when initiated from the home screen panic button
   - When accessed from other parts of the app (journey, navbar), manual start is required
   - This prevents accidental exercise starts when navigating the app
