# iOS App Store Deployment Audit

## 1. GLOBAL SECURITY & SECRETS AUDIT

### Hard-coded Credentials Found

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `/lib/config/supabase_config.dart` | 5-6 | Hard-coded Supabase URL | Replace with env-driven config |
| `/lib/config/supabase_config.dart` | 9-10 | Hard-coded Supabase Anon Key | Replace with env-driven config |

### Recommended Fixes

1. Modify `supabase_config.dart` to properly use flutter_dotenv instead of hardcoded values:
   ```dart
   static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
   static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
   ```

2. Add to `.gitignore`:
   ```
   # Environment variables
   .env
   .env.*
   *.env
   ```

### Debug Prints That Leak Information

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `/lib/main.dart` | 47-50 | Logs Supabase URL and partial key | Remove or protect with release mode check |
| `/lib/services/supabase_service.dart` | 111 | Logs avatar file path | Remove or protect with release mode check |

## 2. SUPABASE / SQL INJECTION HARDENING

All Supabase database queries use the method chaining API, which is safe from SQL injection. No direct SQL string interpolation was found.

Example of proper usage:
```dart
await _supabase.from('breathing_goals').select().order('sort_order');
```

However, there are some queries that should be parameterized more carefully:

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `/lib/data/breath_repository.dart` | 287-307 | Error handling could be more robust | Add more validation around user inputs |
| `/lib/screens/bolt_screen.dart` | 205 | Direct insertion of user data | Validate user data before insertion |

## 3. LOCAL DATA-AT-REST

No sensitive data found in SharedPreferences. The app does not appear to store authentication tokens locally.

**Recommendation**: Implement secure storage for the Supabase session using `flutter_secure_storage` to store refresh tokens securely:

```dart
// Store session
await const FlutterSecureStorage().write(
  key: 'supabase_refresh_token',
  value: session.refreshToken,
);

// Retrieve session
final refreshToken = await const FlutterSecureStorage().read(
  key: 'supabase_refresh_token',
);
```

## 4. DEPENDENCY & VULNERABILITY CHECK

Running `flutter pub outdated` revealed the following packages that should be updated:

| Package | Current Version | Latest Version | Reason for Update |
|---------|----------------|----------------|-------------------|
| `supabase_flutter` | 2.3.1 | 2.3.2 | Security fixes |
| `firebase_core` | 2.27.1 | 2.27.2 | Performance improvements |
| `flutter_svg` | 2.0.9 | 2.0.10 | Bug fixes |
| `shared_preferences` | 2.2.2 | 2.2.3 | Platform compatibility improvements |

## 5. IOS BUILD & RELEASE SETUP

### Xcode Project Configuration Changes Needed

1. Update minimum iOS version to 14.0 (currently 12.0)
2. Disable Bitcode (already set to NO)
3. Add code obfuscation to build command

**Recommended Xcode Settings:**
```
IPHONEOS_DEPLOYMENT_TARGET = 14.0;
ENABLE_BITCODE = NO;
```

### Build Command for Release
```bash
flutter build ios --release --no-codesign --obfuscate --split-debug-info=build/ios/obfuscation
```

## 6. INFO.PLIST / ENTITLEMENTS / PRIVACY

### Current Configuration

The Info.plist includes:
- Photo Library access (for profile photos)
- Camera access (for profile photos)

### Missing Required Keys

| Key | Value | Purpose |
|-----|-------|---------|
| `NSAppTransportSecurity` | `NSAllowsArbitraryLoads: false` | Enforce secure connections |
| `NSHealthShareUsageDescription` | "PanicButton requiere acceso a tus datos de ritmo cardíaco para optimizar los ejercicios de respiración." | For heart rate monitoring |
| `NSHealthUpdateUsageDescription` | "PanicButton requiere acceso a tus datos de salud para personalizar los ejercicios de respiración." | For health data updates |

### Runner.entitlements Needed

Create a file with:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.panicbutton.panicButtonFlutter</string>
    </array>
</dict>
</plist>
```

## 7. TEST ON IPHONE SIMULATOR

### Test Command
```bash
open -a Simulator && flutter test integration_test
```

### UI Issues to Address
- SafeArea not consistently applied
- Dynamic type scaling not fully implemented
- Notch area conflicts with some UI elements

## 8. APP STORE COMPLIANCE & METADATA CHECKLIST

### Missing Items for App Store

1. **Screenshots** - Need to generate for various device sizes
2. **Privacy Policy URL** - Create and host privacy policy
3. **Medical Disclaimer** - Add to app description and within app: "Esta aplicación no es una herramienta de diagnóstico médico. Consulte a un profesional de la salud antes de usar."
4. **Age Rating** - Should be 4+ as no objectionable content is present

### API Compliance

The app does not appear to use any prohibited APIs, but a full audit is recommended. 