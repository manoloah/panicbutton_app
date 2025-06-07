# App Identity Locations

This document tracks all places in the project where app identity information (name, bundle ID, etc.) is defined.
When changing the app name or other identity information, update the centralized `AppConfig` class first,
then update these locations as needed.

## Centralized Configuration

The single source of truth for app identity is:
- `lib/config/app_config.dart`

## Files containing app identity information

### Flutter Configuration

- `pubspec.yaml`
  - `name`: Package name (does not appear to users)
  - `description`: App description
  - `version`: App version number

### iOS Configuration

- `ios/Runner/Info.plist`
  - `CFBundleDisplayName`: App name shown on iOS home screen
  - `CFBundleName`: Short app name
  - `CFBundleIdentifier`: Bundle ID (controlled by Xcode project)
  - `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`: Contains app name in usage descriptions

- `ios/Runner.xcodeproj/project.pbxproj`
  - `PRODUCT_BUNDLE_IDENTIFIER`: Bundle ID for app

### Android Configuration

- `android/app/src/main/AndroidManifest.xml`
  - `android:label`: App name shown on Android home screen

- `android/app/build.gradle.kts`
  - `applicationId`: Bundle ID for app
  - `namespace`: Package namespace

### Dart/Flutter Code

- `lib/main.dart`
  - App title in MaterialApp

## Future Improvements

In future phases, we should:

1. Use variables in iOS Info.plist that reference xcconfig files
2. Set up product flavors in Android build.gradle
3. Automate the update process with scripts or CI/CD pipelines

## Process for Updating App Identity

1. Update `lib/config/app_config.dart` with new values
2. Run the following command to update iOS Info.plist:
   ```bash
   plutil -replace CFBundleDisplayName -string "NEW_NAME" ios/Runner/Info.plist
   plutil -replace CFBundleName -string "new_name" ios/Runner/Info.plist
   ```
3. Update Android manifest and build.gradle manually
4. Update other references in usage descriptions 