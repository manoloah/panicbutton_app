# Environment Configuration for PanicButton App

This guide explains how to configure Supabase credentials for different environments and development workflows.

## Overview

The app now supports multiple ways to load Supabase credentials:

1. **Production builds**: Use `--dart-define` command-line arguments during build
2. **VS Code debugging**: Use the `.env` file or custom launch configurations
3. **Command-line development**: Use the new helper script that supports both `.env` and arguments

## Setup Instructions

### 1. Create a .env file (for VS Code default debugging)

- Copy `.env.example` to `.env` in the project root
- Fill in your Supabase development credentials:
  ```
  SUPABASE_URL=https://your-project.supabase.co
  SUPABASE_ANON_KEY=your-anon-key
  ```
- Make sure this file is in `.gitignore` to prevent committing credentials

### 2. VS Code Launch Configurations

The project includes several VS Code launch configurations:

- **Flutter (default)**: Uses the `.env` file for credentials
- **Flutter (production)**: Uses credentials provided via `--dart-define`
- **Flutter (chrome)**: Launches in Chrome browser using `.env` file
- **Flutter (chrome production)**: Launches in Chrome with defined credentials

### 3. Command-line Development

Use the `scripts/dev_run.sh` helper script for convenient command-line development:

```bash
# Run on default device using .env file
./scripts/dev_run.sh

# Run on Chrome browser
./scripts/dev_run.sh -d chrome

# Run on specific iPhone simulator
./scripts/dev_run.sh -d "iPhone" 

# Run with explicit Supabase credentials
./scripts/dev_run.sh --url https://your-project.supabase.co --key your-anon-key
```

### 4. Building for Production

For production builds, use the `scripts/build_ios.sh` script:

```bash
# For TestFlight distribution
./scripts/build_ios.sh --distribution=testflight

# For App Store distribution
./scripts/build_ios.sh --distribution=appstore
```

For Android production builds:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

## How Environment Configuration Works

The app uses a centralized environment configuration system in `lib/config/env_config.dart`:

1. **Priority Loading**: 
   - First tries to use `--dart-define` values (for production)
   - Falls back to `.env` file values (for development)
   - Provides appropriate console warnings if credentials are missing

2. **Initialization Process**:
   - In `main.dart`, the `EnvConfig.load()` method is called during startup
   - This loads the `.env` file if running in debug mode
   - The app then uses getters from `EnvConfig` to access credentials

3. **Security Best Practices**:
   - Credentials are never hardcoded in the source
   - `.env` files are excluded from git
   - Production builds use `--dart-define` to inject credentials at build time
   - The values are compiled into binary, not stored as plain text

## Troubleshooting

### Missing Credentials

If you see this warning in the console:
```
⚠️ SUPABASE_URL missing. Use --dart-define or .env
```

Solutions:
1. Check that your `.env` file exists and contains the correct variables
2. Make sure the `.env` file is included in your assets in `pubspec.yaml`
3. For production builds, verify you're using the `--dart-define` flags

### VS Code Debug Issues

If VS Code debugging doesn't load credentials:

1. Check that you're using the correct launch configuration
2. Verify that `.env` is in the correct location (root of the project)
3. Try using the `scripts/dev_run.sh` script as an alternative

## Testing Your Configuration

To verify your environment configuration is working correctly:

1. **Test .env file loading**:
   - Run app with `./scripts/dev_run.sh` or "Flutter (default)" VS Code profile
   - You should see `🔑 Environment loaded from .env file` in the console
   - The app should connect to Supabase successfully

2. **Test dart-define values**:
   - Run app with explicit values:
     ```
     flutter run --dart-define=SUPABASE_URL=test-url --dart-define=SUPABASE_ANON_KEY=test-key
     ```
   - Check the console - it should NOT attempt to load the `.env` file for these values

## Behavior

- In production builds, it always uses Dart-define values
- In VS Code debug mode with the default configuration, it uses .env file credentials
- If neither is available, you'll see warning messages in the console, but the app won't crash
- In any environment, Dart-define values always take precedence over .env file values
- The credentials are loaded before Supabase is initialized, ensuring no crashes due to missing configuration

## Technical Details

The environment configuration is managed by two classes:

1. `EnvConfig` (new) - General-purpose environment loader
   - Provides methods to load and validate environment variables
   - Falls back from Dart-define to .env
   - Issues warnings for missing variables
   
2. `SupabaseConfig` (existing) - Legacy provider of Supabase credentials
   - Has been integrated with the new environment system
   - Will be deprecated in favor of using EnvConfig directly 