# Secure Handling of Supabase Credentials

This document explains how Supabase credentials are securely handled in the Calme app.

## The Problem with Environment Files

Many projects use `.env` files to store API keys and credentials. However, this approach has significant drawbacks when building mobile applications:

1. **Not included in production:** If your app relies on a `.env` file at runtime but that file isn't included in the production bundle, the app will crash.

2. **Security risks if included:** If you do include a `.env` file in your production bundle, the credentials could be extracted from the app package.

## Our Secure Approach

The Calme app uses a more secure approach that injects credentials at build time:

### Development Environment

During development, we:
- Store credentials in a local `.env` file (git-ignored)
- Load these using `flutter_dotenv` for easy local development
- Use the `debug_run.sh` script to simplify running the app with proper credentials

### Production Builds

For production (TestFlight/App Store), we:
- **Do not include** the `.env` file in the app bundle
- **Inject credentials at build time** using Dart's compile-time environment variables
- Use the `--dart-define=KEY=VALUE` flags to pass credentials securely

This means:
- No credentials stored in the app bundle or source code
- Credentials only ever exist on the build machine
- Significantly reduced attack surface

## How It Works

Our `SupabaseConfig` class in `lib/config/supabase_config.dart` handles this elegantly:

```dart
static const String _envSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: '',
);

static String get supabaseUrl {
  // First check build-time environment variables (production approach)
  if (_envSupabaseUrl.isNotEmpty) {
    return _envSupabaseUrl;
  }
  
  // Then try to get from .env file (development approach)
  final envValue = dotenv.env['SUPABASE_URL'];
  if (envValue != null && envValue.isNotEmpty) {
    return envValue;
  }
  
  return '';
}
```

## Building for Production

Use our consolidated build script that handles both local development and CI/CD environments:

```bash
# Standard local build using .env file
./scripts/build_ios.sh

# Local build with testing and analysis
./scripts/build_ios.sh --test --analyze

# TestFlight-specific build
./scripts/build_ios.sh --distribution=testflight

# CI/CD build with credentials passed via environment variables
SUPABASE_URL=your-url SUPABASE_ANON_KEY=your-key ./scripts/build_ios.sh --ci
```

The script automatically:
1. Detects whether it's running in local or CI mode
2. Reads credentials from appropriate sources
3. Validates Flutter version and Xcode settings
4. Allows optional testing and static analysis
5. Creates a production-ready build with credentials securely embedded

## Security Best Practices

1. **NEVER commit the `.env` file** to version control
2. **NEVER hardcode credentials** in the source code
3. Keep credentials in a secure password manager or secrets vault
4. Rotate credentials periodically
5. Use the minimum required permissions for the anonymous key

By following this approach, we maintain both convenience during development and security for production releases. 