# PanicButton Flutter App

A calming app for anxiety relief with breathing exercises, built with Flutter.

## Features

- Beautiful and calming UI
- Guided breathing exercises
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

## Project Structure

```
lib/
  ├── screens/          # App screens
  ├── widgets/          # Reusable widgets
  ├── services/         # Services (Supabase, etc.)
  ├── models/           # Data models
  ├── utils/            # Utility functions
  └── theme/            # App theme and styling
```

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
