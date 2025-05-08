#!/bin/bash

# ci_ios_build.sh
# CI/CD script for building and testing PanicButton Flutter iOS app

set -e # Exit on error

# Configuration
FLUTTER_VERSION="3.16.9" # Specify Flutter version
IOS_MIN_VERSION="14.0"   # iOS minimum version
ENABLE_OBFUSCATION=true  # Enable code obfuscation

# Print script configuration
echo "🔄 Starting iOS build with Flutter $FLUTTER_VERSION"
echo "🔒 Minimum iOS version: $IOS_MIN_VERSION"
echo "🔐 Obfuscation enabled: $ENABLE_OBFUSCATION"

# Check if running on CI or locally
if [ -z "$CI" ]; then
  echo "🖥️ Running in local environment"
else
  echo "🤖 Running in CI environment"
fi

# Setup environment
echo "🔧 Setting up environment..."

# Check Flutter is installed
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found! Please install Flutter first."
  exit 1
fi

# Verify correct Flutter version
CURRENT_FLUTTER=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
echo "📊 Current Flutter version: $CURRENT_FLUTTER"

# Ensure .env file exists for local development
if [ -z "$CI" ] && [ ! -f ".env" ]; then
  echo "❌ .env file not found! Please create it with SUPABASE_URL and SUPABASE_ANON_KEY."
  exit 1
fi

# In CI, create .env from environment variables
if [ ! -z "$CI" ]; then
  echo "📝 Creating .env file from environment variables..."
  echo "SUPABASE_URL=$SUPABASE_URL" > .env
  echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
fi

# Update Xcode project configuration
echo "🔧 Updating iOS configuration..."

# Update minimum iOS version to 14.0 if needed
cd ios
CURRENT_IOS_VERSION=$(grep -A 2 'IPHONEOS_DEPLOYMENT_TARGET' Runner.xcodeproj/project.pbxproj | grep -oE "[0-9]+\.[0-9]+")
echo "📊 Current iOS minimum version: $CURRENT_IOS_VERSION"

if [ "$CURRENT_IOS_VERSION" != "$IOS_MIN_VERSION" ]; then
  echo "🔄 Updating iOS minimum version to $IOS_MIN_VERSION..."
  sed -i '' "s/IPHONEOS_DEPLOYMENT_TARGET = $CURRENT_IOS_VERSION;/IPHONEOS_DEPLOYMENT_TARGET = $IOS_MIN_VERSION;/g" Runner.xcodeproj/project.pbxproj
fi

# Ensure Bitcode is disabled
BITCODE_ENABLED=$(grep -A 1 'ENABLE_BITCODE' Runner.xcodeproj/project.pbxproj | grep -c 'YES')
if [ "$BITCODE_ENABLED" -gt 0 ]; then
  echo "🔄 Disabling Bitcode..."
  sed -i '' 's/ENABLE_BITCODE = YES;/ENABLE_BITCODE = NO;/g' Runner.xcodeproj/project.pbxproj
fi

# Return to project root
cd ..

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Run static analysis
echo "🔍 Running Flutter analyze..."
flutter analyze

# Run tests
echo "🧪 Running unit tests..."
flutter test

# Build iOS app
echo "🏗️ Building iOS app..."

BUILD_COMMAND="flutter build ios --release --no-codesign"

# Add obfuscation if enabled
if [ "$ENABLE_OBFUSCATION" = true ]; then
  BUILD_COMMAND="$BUILD_COMMAND --obfuscate --split-debug-info=build/ios/obfuscation"
fi

# Execute build
echo "🚀 Executing: $BUILD_COMMAND"
eval "$BUILD_COMMAND"

# Build succeeded
echo "✅ iOS build completed successfully!"
echo "📱 You can find the build in build/ios/iphoneos/"

# Integration tests (if not in CI or if explicitly enabled in CI)
if [ -z "$CI" ] || [ "$CI_RUN_INTEGRATION_TESTS" = "true" ]; then
  echo "🧪 Running integration tests..."
  if [ -z "$CI" ]; then
    # For local, launch simulator
    open -a Simulator
    flutter test integration_test
  else
    # For CI, assuming a device is already configured
    flutter test integration_test
  fi
fi

exit 0 