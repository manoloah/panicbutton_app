# PanicButton Flutter App

A calming app for anxiety relief with breathing exercises, built with Flutter.

## Features

- Beautiful and calming UI
- Guided breathing exercises with fluid wave animations
- Customizable breathing patterns (inhale, hold, exhale, rest)
- Pattern selection by breathing goals (calming, energizing, etc.)
- Progressive breathing journey with level unlocking based on BOLT scores
- Animated breathing circle with wave visualization
- Session tracking and detailed breathing activity statistics
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
  │   └── journey_level.dart      # Models for breathing journey levels
  ├── providers/        # State management 
  │   ├── breathing_providers.dart        # Providers for breath state
  │   ├── breathing_playback_controller.dart  # Controller for animations
  │   └── journey_provider.dart   # Provider for journey progress and unlocking
  ├── screens/          # App screens
  │   ├── breath_screen.dart      # Main breathing exercise screen
  │   └── journey_screen.dart     # Breathing journey progression screen
  ├── widgets/          # Reusable widgets
  │   ├── breath_circle.dart        # Circular breathing animation container
  │   ├── duration_selector_button.dart  # Duration selection UI
  │   ├── goal_pattern_sheet.dart   # Pattern selection bottom sheet
  │   ├── wave_animation.dart       # Fluid wave animation using CustomPainter
  │   ├── phase_indicator.dart      # Shows breathing phase and countdown
  │   ├── remaining_time_display.dart # Formatted time remaining display
  │   └── custom_nav_bar.dart       # App navigation bar
  ├── migrations/       # Database migrations
  │   ├── 20250511_simplify_breathing_schema.sql  # Breathing schema
  │   ├── 20240701_create_breathing_activity_table.sql  # Activity tracking
  │   └── 20240702_add_cumulative_seconds.sql  # Activity stats enhancements
  ├── services/         # Services (Supabase, etc.)
  ├── utils/            # Utility functions
  ├── theme/            # App theme and styling
  │   └── app_theme.dart           # Theme configuration with extensions
  └── main.dart         # App entry point with Go Router configuration
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
   - Records completed patterns with accurate duration tracking
   - Supports pause and resume functionality
   - Maintains detailed statistics including total breathing time
   - Tracks cumulative practice across patterns

## Breathing Activity Tracking

The app includes a comprehensive system for tracking breathing activities:

1. **Detailed Session Records**:
   - Start and end times of each breathing session
   - Actual duration of practice (in seconds)
   - Which pattern was used
   - Completion status

2. **Aggregated Statistics**:
   - Total number of sessions per pattern
   - Cumulative breathing time per pattern
   - Overall breathing minutes

3. **Database Integration**:
   - Records stored in Supabase
   - Automatic sync with user accounts
   - Row-level security for data protection
   - Only sessions longer than 10 seconds are counted toward stats

4. **Pause/Resume Support**:
   - Users can pause and resume sessions
   - Time tracking continues accurately across pauses
   - Single activity record maintained per complete session

## Breathing Journey Feature

The app includes a progressive breathing journey that allows users to unlock new breathing techniques as they improve:

1. **Level-Based Progression**:
   - 12 levels with increasingly advanced breathing techniques
   - Each level unlocks new breathing patterns

2. **Unlock Requirements**:
   - Based on BOLT score achievements
   - Weekly breathing practice minutes
   - Visual progress indicators

3. **Pattern Integration**:
   - Each level links to specific breathing patterns by slug
   - Seamless navigation to breathing exercises
   - Progress tracking across sessions

4. **Database Integration**:
   - Journey levels stored in JSON configuration
   - Progress tracked in Supabase
   - Pattern slugs connect journey levels to breathing patterns

## Navigation

The app uses Go Router for navigation, with these key features:

1. **URL-Based Routing**:
   - Clean URLs reflect current screen (/journey, /breath, etc.)
   - Pattern-specific routes with parameters (/breath/:patternSlug)
   - Consistent back navigation

2. **Deep Linking Support**:
   - Direct navigation to specific breathing patterns
   - Preserved navigation state during app lifecycle
   - Direct linking from Journey levels to specific patterns

3. **Authentication Protection**:
   - Routes protected based on authentication state
   - Automatic redirects to login when needed

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
- go_router: Navigation and deep linking
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
