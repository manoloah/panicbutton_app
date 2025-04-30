# PanicButton Flutter App

A calming app for anxiety relief with breathing exercises, built with Flutter.

## Features

- Beautiful and calming UI
- Guided breathing exercises with fluid wave animations
- Customizable breathing patterns (inhale, hold, exhale, rest)
- Session tracking
- User statistics
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
  ├── screens/          # App screens
  ├── widgets/          # Reusable widgets
  │   ├── breathing_circle.dart     # Circular container for breathing exercise
  │   ├── wave_animation.dart       # Fluid wave animation using CustomPainter
  │   ├── phase_indicator.dart      # Shows breathing phase and countdown
  │   ├── remaining_time_display.dart # Formatted time remaining display
  │   ├── add_time_button.dart      # Button to add more time to session
  │   └── custom_nav_bar.dart       # App navigation bar
  ├── services/         # Services (Supabase, etc.)
  ├── models/           # Data models
  ├── utils/            # Utility functions
  ├── theme/            # App theme and styling
  │   └── app_theme.dart           # Theme configuration with extensions
  └── main.dart         # App entry point
```

## Architecture

The app follows a component-based architecture where UI elements are broken down into small, reusable widgets:

### Breathwork Screen Components

The breathing exercise screen demonstrates this approach by breaking down a complex UI into focused components:

1. **BreathingCircle**: Container that handles the circle shape, styling, and tap gestures
2. **WaveAnimation**: Manages the wave animation with CustomPainter for fluid movement
3. **PhaseIndicator**: Displays the current breathing phase text and countdown
4. **RemainingTimeDisplay**: Shows formatted remaining time
5. **AddTimeButton**: Button to add more time to the session

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
- google_fonts: Typography
- lottie: Animation support

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
