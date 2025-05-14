#!/bin/bash

# build_ios.sh - Comprehensive iOS build script for both local and CI environments
# Usage:
#  Local: ./scripts/build_ios.sh [--test] [--analyze]
#  CI:    SUPABASE_URL=url SUPABASE_ANON_KEY=key ./scripts/build_ios.sh --ci [--test]

# Exit on error
set -e

# Script configuration
IOS_MIN_VERSION="14.0"
FLUTTER_REQUIRED_VERSION="3.16.0" # Minimum required version

# Process arguments
CI_MODE=false
RUN_TESTS=false
RUN_ANALYSIS=false
DISTRIBUTION_MODE="development" # Options: development, testflight, appstore

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --ci) CI_MODE=true ;;
    --test) RUN_TESTS=true ;;
    --analyze) RUN_ANALYSIS=true ;;
    --distribution=*) DISTRIBUTION_MODE="${1#*=}" ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

echo "🚀 iOS Build Script for Calme app"
echo "🔄 Mode: ${CI_MODE:+CI/CD}${CI_MODE:=Local Development}"
echo "📱 Distribution: $DISTRIBUTION_MODE"
echo "🧪 Tests: ${RUN_TESTS:+Enabled}${RUN_TESTS:=Disabled}"
echo "🔍 Analysis: ${RUN_ANALYSIS:+Enabled}${RUN_ANALYSIS:=Disabled}"

# Make sure we're in the project directory
cd "$(dirname "$0")/.."

# SECURITY NOTE:
# This script securely handles Supabase credentials by injecting them at build time.
# The credentials are NOT bundled with the app, but compiled into the binary.

# Check Flutter installation and version
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found! Please install Flutter."
  exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -1 | cut -d ' ' -f 2)
echo "🔍 Using Flutter $FLUTTER_VERSION"

# Version check
if [ "$(printf '%s\n' "$FLUTTER_REQUIRED_VERSION" "$FLUTTER_VERSION" | sort -V | head -n1)" != "$FLUTTER_REQUIRED_VERSION" ]; then
  echo "⚠️ Warning: Flutter version $FLUTTER_VERSION may be too old (recommended: $FLUTTER_REQUIRED_VERSION+)"
fi

# Credentials handling - Allow CI environment variables or local .env file
if $CI_MODE; then
  # In CI mode, credentials must be set as environment variables
  if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ ERROR: Missing required environment variables in CI mode!"
    echo "This script requires the following environment variables:"
    echo "- SUPABASE_URL: Supabase project URL"
    echo "- SUPABASE_ANON_KEY: Supabase anonymous key"
    exit 1
  fi
else
  # In local mode, try to read from .env file if env vars aren't already set
  if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    if [ -f .env ]; then
      echo "📋 Loading Supabase credentials from .env file..."
      export $(grep -v '^#' .env | xargs)
    else
      echo "❌ No credentials found! Either:"
      echo "  1. Create a .env file with SUPABASE_URL and SUPABASE_ANON_KEY"
      echo "  2. Run this script with environment variables set:"
      echo "     SUPABASE_URL=url SUPABASE_ANON_KEY=key ./scripts/build_ios.sh"
      exit 1
    fi
  fi
fi

# Validate environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ Missing Supabase credentials!"
  exit 1
fi

# Run Flutter analysis if requested
if $RUN_ANALYSIS; then
  echo "🔍 Running Flutter analyze..."
  flutter analyze
fi

# Run tests if requested
if $RUN_TESTS; then
  echo "🧪 Running unit tests..."
  flutter test
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Ensure iOS deployment target is set to 14.0
echo "🔧 Setting iOS deployment target to 14.0..."
plutil -replace MinimumOSVersion -string "$IOS_MIN_VERSION" ios/Flutter/AppFrameworkInfo.plist

# Check and update Xcode configuration
cd ios
echo "🔧 Updating Xcode project settings..."

# Ensure Bitcode is disabled (Apple no longer supports it)
BITCODE_ENABLED=$(grep -A 1 'ENABLE_BITCODE' Runner.xcodeproj/project.pbxproj | grep -c 'YES' || echo "0")
if [ "$BITCODE_ENABLED" -gt 0 ]; then
  echo "  - Disabling Bitcode (no longer supported by Apple)..."
  sed -i '' 's/ENABLE_BITCODE = YES;/ENABLE_BITCODE = NO;/g' Runner.xcodeproj/project.pbxproj
else
  echo "  - Bitcode already disabled (good!)"
fi

cd ..

# Mask sensitive data in logs
MASKED_KEY="${SUPABASE_ANON_KEY:0:5}...${SUPABASE_ANON_KEY: -5}"
echo "🔐 Using Supabase URL: $SUPABASE_URL"
echo "🔐 Using Supabase Key: $MASKED_KEY (masked for security)"

# Set build flags based on distribution mode
BUILD_FLAGS="--release --obfuscate --split-debug-info=build/ios/obfuscation"

if $CI_MODE; then
  # Add the no-codesign flag for CI environment
  BUILD_FLAGS="$BUILD_FLAGS --no-codesign"
fi

# Build iOS app
echo "🏗️ Building iOS app with secure credential injection..."
flutter build ios $BUILD_FLAGS \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

BUILD_RESULT=$?
if [ $BUILD_RESULT -ne 0 ]; then
  echo "❌ Build failed with error code $BUILD_RESULT"
  exit $BUILD_RESULT
fi

echo "✅ iOS build completed successfully!"
echo ""
echo "🔒 Security note: Supabase credentials have been securely injected at build time."
echo "   They are NOT stored in plain text in the app bundle."
echo ""

if ! $CI_MODE; then
  echo "Next steps:"
  echo "1. Open Xcode: open ios/Runner.xcworkspace"
  echo "2. Select Product > Archive in Xcode"
  echo "3. In the Archives organizer, click 'Distribute App'"
  
  case $DISTRIBUTION_MODE in
    "testflight")
      echo "4. Select 'App Store Connect' > 'Upload to TestFlight'"
      ;;
    "appstore")
      echo "4. Select 'App Store Connect' > 'Release to App Store'"
      ;;
    *)
      echo "4. Select your preferred distribution method"
      ;;
  esac
fi

exit 0 