# PanicButton Flutter App

A calming app for anxiety relief with breathing exercises, built with Flutter.

## Features

- Beautiful and calming UI
- Guided breathing exercises with fluid wave animations
- Customizable breathing patterns (inhale, hold, exhale, rest)
- Pattern selection by breathing goals (calming, energizing, etc.)
- Animated breathing circle with wave visualization
- Session tracking and statistics
- BOLT score measurement for tracking anxiety levels
- Step-by-step instruction screens with smooth transitions
- Cross-platform (iOS, Android, Web)

## Setup

1. Install Flutter:
   ```bash
   # Follow the official Flutter installation guide for your platform
   # https://flutter.dev/docs/get-started/install
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/panic-button-flutter.git
   cd panic-button-flutter
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Configure Supabase:
   - Create a new project in Supabase
   - Copy your Supabase URL and anon key
   - Create a `.env` file in the root directory with:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

5. Run the app:
   ```bash
   flutter run
   ```
   or for running on chrome
   ```bash
   flutter run -d chrome
   ```
   

## Project Structure

```
lib/
  ├── constants/        # App constants including image paths
  ├── data/             # Data repositories and API classes
  │   └── breath_repository.dart  # Repository for breathing patterns
  ├── models/           # Data models
  │   └── breath_models.dart      # Models for breathing patterns and steps
  ├── providers/        # State management 
  │   ├── breathing_providers.dart        # Providers for breath state
  │   └── breathing_playback_controller.dart  # Controller for animations
  ├── screens/          # App screens
  │   └── breath_screen.dart      # Main breathing exercise screen
  ├── widgets/          # Reusable widgets
  │   ├── breath_circle.dart        # Circular breathing animation container
  │   ├── duration_selector_button.dart  # Duration selection UI
  │   ├── goal_pattern_sheet.dart   # Pattern selection bottom sheet
  │   ├── wave_animation.dart       # Fluid wave animation using CustomPainter
  │   ├── phase_indicator.dart      # Shows breathing phase and countdown
  │   ├── remaining_time_display.dart # Formatted time remaining display
  │   └── custom_nav_bar.dart       # App navigation bar
  ├── migrations/       # Database migrations
  │   └── 20250511_simplify_breathing_schema.sql  # Breathing schema
  ├── services/         # Services (Supabase, etc.)
  ├── utils/            # Utility functions
  ├── theme/            # App theme and styling
  │   └── app_theme.dart           # Theme configuration with extensions
  └── main.dart         # App entry point
```

## Breathing Exercise Feature

The app's breathing exercise feature provides a guided breathing experience with:

1. **Pattern Selection**: 
   - Choose from various breathing patterns based on goals (calming, focus, energy)
   - Each pattern has specific inhale, hold, exhale, and relax timings

2. **Duration Selection**:
   - Choose from 3, 5, or 10 minutes (or pattern-recommended duration)
   - Sessions automatically calculate required breathing cycles

3. **Visual Guidance**:
   - Animated circle expands and contracts with your breath
   - Beautiful wave animation represents lung capacity
   - Clear phase indicators (Inhale, Hold, Exhale, Relax)
   - Countdown timers for each phase

4. **Session Tracking**:
   - Records completed patterns
   - Tracks usage statistics over time

## Image Asset Management

The app follows a structured approach to image asset management:

1. **Image Organization**
   - All images are stored in `assets/images/`
   - Images are named using snake_case (e.g., `pinch_nose.png`)
   
2. **Centralized Image References**
   - Image paths are defined in `lib/constants/images.dart`
   - The `Images` class uses a private constructor to prevent instantiation
   - Static constants provide type-safe access to image paths

Example:
```dart
class Images {
  Images._(); // Private constructor to prevent instantiation
  
  // BOLT Screen Images
  static const String pinchNose = 'assets/images/pinch_nose.png';
  static const String breathCalm = 'assets/images/breath_calm.png';
}
```

3. **Usage in widgets**
```dart
Image.asset(
  Images.pinchNose,
  width: 120,
  height: 120,
)
```

## BOLT Measurement Feature

The Body Oxygen Level Test (BOLT) feature allows users to measure their CO2 tolerance:

1. **Step-by-step Instructions**
   - Clear visual guidance through multiple breathing phases
   - Manual progression via "SIGUIENTE" button for initial breathing phase
   - Automatic countdown timers for inhale/exhale phases
   
2. **Smooth Transitions**
   - Uses the `animations` package with `PageTransitionSwitcher`
   - Implements `FadeThroughTransition` for professional-looking screen transitions
   - Consistent container sizes to prevent layout jumps

3. **Results Tracking**
   - Saves BOLT scores to Supabase database
   - Displays historical data with various aggregation options (day, week, month, etc.)
   - Visual progress chart using `fl_chart`

## Architecture

The app follows a component-based architecture where UI elements are broken down into small, reusable widgets:

### Breathwork Screen Components

The breathing exercise screen demonstrates this approach by breaking down a complex UI into focused components:

1. **BreathCircle**: Container that handles animated circle shape, sizing, and tap gestures
2. **WaveAnimation**: Manages the wave animation with CustomPainter for fluid movement
3. **PhaseCountdownDisplay**: Shows current phase text and countdown timer
4. **DurationSelectorButton**: Toggle between different session durations
5. **GoalPatternSheet**: Bottom sheet for selecting breathing patterns by goal

This approach provides:
- Better separation of concerns
- Improved testability for each component
- Enhanced performance through optimized rebuilds
- Greater code maintainability

## Dependencies

- flutter_riverpod: State management
- go_router: Navigation
- supabase_flutter: Backend integration
- flutter_animate: Animations
- animations: Page transitions
- google_fonts: Typography
- lottie: Animation support
- fl_chart: Data visualization

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
