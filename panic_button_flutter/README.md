# PanicButton Flutter App

A calming app for anxiety and panic relief with breathing exercises.

## Features

- Beautiful and calming UI
- Guided breathing exercises with fluid wave animations
- Customizable breathing patterns (inhale, hold, exhale, rest)
- Pattern selection by breathing goals (calming, energizing, etc.)
- Progressive breathing journey with level unlocking based on BOLT scores
- Animated breathing circle with wave visualization
- Voice guidance system with multiple character options
- Background music and breath guide tones 
- Session tracking and detailed breathing activity statistics
- BOLT score measurement for tracking anxiety levels
- Step-by-step instruction screens with smooth transitions
- Cross-platform (iOS, Android, Web)
- Secure credential storage with keychain integration
- iOS App Store compliant implementation

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

4. Configure Environment Variables:
   - Create a `.env` file in the root directory with your Supabase credentials:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```
   - IMPORTANT: Never commit this file to version control
   - The app uses a centralized environment system in `lib/config/env_config.dart`
   - For CI/CD environments, use `--dart-define` flags in your build commands

5. Development Workflow Options:

   a. Using VS Code:
   ```bash
   # Open project in VS Code and use one of the launch configurations:
   # - "Flutter (default)" - Uses .env file
   # - "Flutter (chrome)" - Runs on Chrome browser
   # - "Flutter (production)" - Uses dart-define values
   ```

   b. Using command line with helper scripts:
   ```bash
   # Run on default iOS device using .env file
   ./scripts/dev_run.sh
   
   # Run on Chrome browser
   ./scripts/dev_run.sh -d chrome
   
   # Run on specific iPhone simulator
   ./scripts/dev_run.sh -d "iPhone"
   
   # Run with explicit credentials
   ./scripts/dev_run.sh --url https://your-project.supabase.co --key your-anon-key
   ```

6. Building for Production:
   ```bash
   # For TestFlight distribution
   ./scripts/build_ios.sh --distribution=testflight
   
   # For App Store distribution
   ./scripts/build_ios.sh --distribution=appstore
   
   # For Android APK with credentials
   flutter build apk --release \
     --dart-define=SUPABASE_URL=your_supabase_url \
     --dart-define=SUPABASE_ANON_KEY=your_anon_key
   ```

## App Identity Management

The app uses a centralized configuration system for managing app identity (name, bundle ID, etc.):

1. **Centralized Configuration**
   - All app identity values are defined in `lib/config/app_config.dart`
   - This serves as the single source of truth for app name, bundle ID, etc.

2. **Updating App Identity**
   - To change the app name or bundle ID, use the provided script:
     ```bash
     # Change app name and bundle ID
     ./scripts/update_app_name.sh "NewAppName" "com.company.newbundleid"
     ```
   - The script updates all necessary files automatically:
     - Updates `AppConfig` class
     - Updates iOS Info.plist
     - Updates Android manifest and build.gradle
     - Updates health descriptions in Info.plist

3. **Manual Verification**
   - After running the script, verify changes in:
     - `lib/config/app_config.dart`
     - `ios/Runner/Info.plist`
     - `android/app/src/main/AndroidManifest.xml`
     - `android/app/build.gradle.kts`
   - Run a build to confirm changes: `flutter build ios --debug`

4. **App Identity Locations**
   - Refer to `APP_IDENTITY_LOCATIONS.md` for a comprehensive list of all files containing app identity information

## Secure Setup for Production

For production deployments, follow these additional security steps:

1. **Secure Environment Variables**:
   - Development: Use `.env` file (git-ignored)
   - CI/CD: Use secrets management in your build system
   - Production: Use build-time environment configuration

2. **Secure Storage**:
   - The app uses `flutter_secure_storage` for sensitive data
   - iOS: Credentials stored in Keychain
   - Android: Credentials stored in KeyStore
   - Implementation in `lib/services/secure_storage_service.dart`

3. **iOS Deployment Preparation**:
   - Update Info.plist with required privacy descriptions
   - Configure Runner.entitlements for keychain access
   - Set minimum iOS version to 14.0
   - Disable Bitcode (Apple removed support)
   - Enable code obfuscation for release builds:
     ```bash
     flutter build ios --release --obfuscate --split-debug-info=build/ios/obfuscation
     ```

4. **Debugging Securely**:
   - Sensitive data is not logged in production builds
   - User IDs are truncated in debug logs
   - App uses conditional logging based on build mode (`kDebugMode`)

## Project Structure

```
lib/
  ├── constants/        # App constants including image paths
  ├── data/             # Data repositories and API classes
  │   └── breath_repository.dart  # Repository for breathing patterns
  │   └── metric_repository.dart  # Base repository for metric scores
  ├── models/           # Data models
  │   ├── breath_models.dart      # Models for breathing patterns and steps
  │   ├── journey_level.dart      # Models for breathing journey levels
  │   ├── metric_config.dart      # Configuration model for breathing metrics
  │   └── metric_score.dart       # Models for metric scores and aggregation
  ├── providers/        # State management 
  │   ├── breathing_providers.dart        # Providers for breath state
  │   ├── breathing_playback_controller.dart  # Controller for animations
  │   └── journey_provider.dart   # Provider for journey progress and unlocking
  ├── screens/          # App screens
  │   ├── breath_screen.dart      # Main breathing exercise screen
  │   ├── journey_screen.dart     # Breathing journey progression screen
  │   └── metric_screen.dart      # Generic screen for metric measurements
  ├── widgets/          # Reusable widgets
  │   ├── breath_circle.dart        # Circular breathing animation container
  │   ├── duration_selector_button.dart  # Duration selection UI
  │   ├── goal_pattern_sheet.dart   # Pattern selection bottom sheet
  │   ├── wave_animation.dart       # Fluid wave animation using CustomPainter
  │   ├── phase_indicator.dart      # Shows breathing phase and countdown
  │   ├── remaining_time_display.dart # Formatted time remaining display
  │   ├── custom_nav_bar.dart       # App navigation bar
  │   ├── metric_instructions_card.dart # Instruction card for metrics
  │   ├── metric_measurement_ui.dart    # UI for metric measurement
  │   ├── metric_instruction_overlay.dart # Overlay for guided instructions
  │   ├── metric_score_info_dialog.dart  # Dialog explaining score zones
  │   └── score_chart.dart          # Chart for metric score visualization
  ├── migrations/       # Database migrations
  │   ├── 20250511_simplify_breathing_schema.sql  # Breathing schema
  │   ├── 20240701_create_breathing_activity_table.sql  # Activity tracking
  │   └── 20240702_add_cumulative_seconds.sql  # Activity stats enhancements
  ├── services/         # Services (Supabase, etc.)
  │   └── secure_storage_service.dart  # Secure storage implementation
  ├── utils/            # Utility functions
  ├── theme/            # App theme and styling
  │   └── app_theme.dart           # Theme configuration with extensions
  └── config/           # Configuration files
      └── supabase_config.dart     # Environment-based Supabase configuration
  └── main.dart         # App entry point with Go Router configuration
```

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

4. **Voice Guidance**:
   - Verbal prompts synchronized with breathing phases
   - Multiple voice characters to choose from (Manu, Andrea)
   - Random selection of prompts to avoid repetition
   - Option to turn voice guidance off

5. **Audio Customization**:
   - Background music options (river, forest, ocean, etc.)
   - Breathing guide tones (sine wave, bowl, etc.)
   - Independent volume control for each audio layer
   - All audio settings are preserved between sessions

6. **Session Tracking**:
   - Records completed patterns with accurate duration tracking
   - Supports pause and resume functionality
   - Maintains detailed statistics including total breathing time
   - Tracks cumulative practice across patterns

7. **Auto-Start Behavior**:
   - Breathing exercise auto-starts ONLY when initiated from the home screen panic button
   - When accessed from other parts of the app (journey, navbar), manual start is required
   - This prevents accidental exercise starts when navigating the app

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

4. **Context-Aware Navigation**:
   - Routes pass context information via the `extra` parameter
   - The home screen panic button passes `fromHome: true` to trigger auto-start
   - Other navigation paths maintain appropriate behavior for their context
   - Example:
     ```dart
     // Auto-start when coming from home screen
     context.go('/breath/coherent_4_6', extra: {'fromHome': true});
     
     // Regular navigation without auto-start
     context.go('/breath/coherent_4_6');
     ```

## Router and Auto-Start Configuration

The app employs a targeted auto-start feature for breathing exercises, carefully controlling when exercises begin automatically:

### Router Configuration

```dart
final _router = GoRouter(
  // ... other routes ...
  GoRoute(
    path: '/breath/:patternSlug',
    builder: (context, state) {
      final patternSlug = state.pathParameters['patternSlug'];
      // Only auto-start if we came from the home screen
      final fromHomePage = state.extra is Map && 
          (state.extra as Map)['fromHome'] == true;
      return BreathScreen(
        patternSlug: patternSlug, 
        autoStart: fromHomePage
      );
    },
  ),
  // ... other routes ...
);
```

### Navigation Context Passing

When navigating from the panic button on the home screen:

```dart
void _handlePress() {
  // ... handle press state ...
  
  // Pass fromHome flag to indicate we're coming from home
  context.go('/breath/coherent_4_6', extra: {'fromHome': true});
  
  // ... cleanup ...
}
```

### Behavior in BreathScreen

The BreathScreen respects the autoStart parameter:

```dart
Future<void> _initializePattern() async {
  // ... initialization code ...
  
  // Auto-start only if explicitly requested (coming from home screen)
  if (widget.autoStart) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(breathingPlaybackControllerProvider.notifier).play();
    });
  }
  
  // ... more code ...
}
```

This implementation ensures:
1. The panic button works as expected - immediately starting a calming exercise
2. Other navigation paths (journey, navbar) don't unexpectedly start exercises
3. The context of navigation is properly maintained between screens

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

## Metric Measurement Framework

The app includes a reusable framework for implementing different breathing metrics measurements while maintaining consistent UI and functionality:

### Architecture Overview

The Metric Measurement framework was built to allow for easy replication of measurement screens (like BOLT) for various breathing metrics. It uses a modular, configuration-based approach to:

1. **Maintain Consistent UI Across Metrics**
   - Identical 3-step instruction cards with "COMENZAR" button
   - Same measurement interface with timer and results
   - Consistent historical data visualization
   - Standardized instruction overlays for guided steps

2. **Enable Easy Configuration**
   - Simple definition of new metrics through configuration objects
   - Zone-based scoring interpretation (low, medium, high)
   - Customizable instructions and guidance
   - Configurable scoring units and visualization

3. **Core Components**
   - `MetricConfig`: Model for defining a metric with zones and instructions
   - `MetricScore`: Models for handling score data and aggregation
   - `MetricScreen`: Configurable screen that adapts to any metric
   - `ScoreChart`: Reusable chart for visualizing historical scores
   - Support components for instructions, overlays, and information dialogs

### Implementing a New Metric

To add a new breathing metric measurement to the app:

1. **Create the Metric Configuration**
   ```dart
   final myNewMetricConfig = MetricConfig(
     name: 'New Metric Name',
     description: 'Description of what this metric measures',
     instructions: [
       'First instruction step in Spanish',
       'Second instruction step in Spanish',
       'Third instruction step in Spanish',
     ],
     zones: [
       MetricZone(min: 0, max: 10, label: 'Bajo', color: Colors.red),
       MetricZone(min: 10, max: 20, label: 'Medio', color: Colors.amber),
       MetricZone(min: 20, max: double.infinity, label: 'Alto', color: Colors.green),
     ],
     unitLabel: 'units',
   );
   ```

2. **Create a Repository Provider**
   ```dart
   final myNewMetricRepositoryProvider = Provider<MetricRepository>((ref) {
     return MetricRepository(
       supabase: ref.watch(supabaseProvider),
       tableName: 'my_new_metric_scores',
     );
   });
   ```

3. **Add the Screen to Navigation**
   ```dart
   GoRoute(
     path: '/my-new-metric',
     builder: (context, state) => MetricScreen(
       metricConfig: myNewMetricConfig,
       repository: ref.read(myNewMetricRepositoryProvider),
     ),
   ),
   ```

4. **Setup the Database Table**
   ```sql
   CREATE TABLE my_new_metric_scores (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID REFERENCES auth.users(id) NOT NULL,
     score NUMERIC NOT NULL,
     created_at TIMESTAMPTZ DEFAULT now() NOT NULL
   );
   ```

The framework handles all the UI presentation, state management, animations, and data visualization, allowing for rapid implementation of new breathing metric measurements while maintaining a consistent user experience.

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

## Applying Database Migrations

### Setting Default Breathing Pattern and Goal Order

We've implemented a database migration that:
1. Adds a `sort_order` column to the `breathing_goals` table
2. Sets goal order to: 1. Calma, 2. Equilibrio, 3. Enfoque, 4. Energía
3. Adds an `is_default` column to `breathing_patterns` 
4. Makes 'coherent_4_6' the default breathing pattern

This migration has been applied to the production database and no additional action is needed for these specific changes.

For future migrations, you can:

1. Create a `.env` file in the project root with:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_SERVICE_KEY=your_service_role_key
   ```

2. Use the Supabase MCP tools to apply migrations:
   ```
   MIGRATION_NAME="your_migration_name"
   SQL_QUERY="-- Your SQL query here"
   npx supabase functions invoke mcp_supabase_apply_migration \
     --body '{"project_id":"your_project_id","name":"$MIGRATION_NAME","query":"$SQL_QUERY"}'
   ```

3. Or use direct SQL in the Supabase dashboard's SQL Editor to make changes.

## Code Modernization & Best Practices

As Flutter evolves, we've updated our codebase to follow modern best practices:

### Recent Refactors

1. **Color Opacity Handling**:
   - ✅ Use `.withAlpha((x * 255).toInt())` instead of deprecated `.withOpacity(x)`
   - Example: `color.withAlpha((0.5 * 255).toInt())` instead of `color.withOpacity(0.5)`

2. **Theme Color Scheme Updates**:
   - ✅ Use `cs.onSurface` instead of deprecated `cs.onBackground`
   - The `onBackground` property is deprecated in newer Flutter versions

3. **Type Casting Best Practices**:
   - ✅ Avoid unnecessary casts when types are already inferred
   - ✅ Use `Map<String, dynamic>.from()` for safer type conversion when needed
   - Example: `Map<String, dynamic>.from(jsonData)` instead of `jsonData as Map<String, dynamic>`

4. **Logging Best Practices**:
   - ✅ Use `debugPrint()` instead of `print()` for better performance in Flutter
   - Debug output is properly truncated and doesn't block the main thread

5. **Code Cleanup**:
   - Regular removal of unused imports and methods to maintain a clean codebase
   - Proper layout structuring for responsiveness across device sizes

Following these practices ensures the app remains compatible with the latest Flutter versions and maintains high code quality.
