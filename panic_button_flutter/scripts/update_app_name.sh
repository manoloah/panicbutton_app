#!/bin/bash
# Script to update app name and bundle ID across all platforms

# Check if arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 NEW_APP_NAME NEW_BUNDLE_ID"
    echo "Example: $0 \"Calme\" \"com.breathmanu.calme\""
    exit 1
fi

NEW_APP_NAME=$1
NEW_BUNDLE_ID=$2
NEW_APP_NAME_LOWERCASE=$(echo "$NEW_APP_NAME" | tr '[:upper:]' '[:lower:]')

echo "Updating app name to: $NEW_APP_NAME"
echo "Updating bundle ID to: $NEW_BUNDLE_ID"

# Update AppConfig.dart
echo "Updating AppConfig.dart..."
sed -i '' "s/static const String appDisplayName = \".*\"/static const String appDisplayName = \"$NEW_APP_NAME\"/" lib/config/app_config.dart
sed -i '' "s/static const String appName = \".*\"/static const String appName = \"$NEW_APP_NAME\"/" lib/config/app_config.dart
sed -i '' "s/static const String bundleId = \".*\"/static const String bundleId = \"$NEW_BUNDLE_ID\"/" lib/config/app_config.dart

# Update iOS Info.plist
echo "Updating iOS Info.plist..."
plutil -replace CFBundleDisplayName -string "$NEW_APP_NAME" ios/Runner/Info.plist
plutil -replace CFBundleName -string "$NEW_APP_NAME_LOWERCASE" ios/Runner/Info.plist

# Update health descriptions in Info.plist
plutil -replace NSHealthShareUsageDescription -string "$NEW_APP_NAME requiere acceso a tus datos de ritmo cardíaco para optimizar los ejercicios de respiración." ios/Runner/Info.plist
plutil -replace NSHealthUpdateUsageDescription -string "$NEW_APP_NAME requiere acceso a tus datos de salud para personalizar los ejercicios de respiración." ios/Runner/Info.plist

# Update Android Manifest
echo "Updating AndroidManifest.xml..."
sed -i '' "s/android:label=\".*\"/android:label=\"$NEW_APP_NAME\"/" android/app/src/main/AndroidManifest.xml

# Update Android build.gradle
echo "Updating build.gradle.kts..."
sed -i '' "s/namespace = \".*\"/namespace = \"$NEW_BUNDLE_ID\"/" android/app/build.gradle.kts
sed -i '' "s/applicationId = \".*\"/applicationId = \"$NEW_BUNDLE_ID\"/" android/app/build.gradle.kts

echo "App identity updated. Please review changes and rebuild your app."
echo "You may need to update the bundle ID in Xcode project manually." 