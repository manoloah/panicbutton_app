#!/bin/bash

# Exit on error
set -e

# Function to display usage
usage() {
  echo "Usage: $0 [option]"
  echo "Options:"
  echo "  patch   - Increment patch version (1.0.x)"
  echo "  minor   - Increment minor version (1.x.0)"
  echo "  major   - Increment major version (x.0.0)"
  echo "  build   - Increment only build number (+x)"
  echo "  info    - Display current version"
  exit 1
}

# Ensure we're in the correct directory
cd "$(dirname "$0")/.."

# Get current version
PUBSPEC="pubspec.yaml"
CURRENT_VERSION=$(grep -E "^version: " $PUBSPEC | awk '{print $2}')
VERSION_PARTS=(${CURRENT_VERSION/+/ })
VERSION=${VERSION_PARTS[0]}
BUILD=${VERSION_PARTS[1]}

# Split semantic version
IFS='.' read -ra VERSION_NUMBERS <<< "$VERSION"
MAJOR=${VERSION_NUMBERS[0]}
MINOR=${VERSION_NUMBERS[1]}
PATCH=${VERSION_NUMBERS[2]}

# Display current version
echo "Current version: $CURRENT_VERSION"
echo "  - Major: $MAJOR"
echo "  - Minor: $MINOR"
echo "  - Patch: $PATCH"
echo "  - Build: $BUILD"
echo ""

if [ "$1" == "info" ]; then
  exit 0
fi

# Increment version based on argument
case "$1" in
  "major")
    NEW_MAJOR=$((MAJOR + 1))
    NEW_VERSION="$NEW_MAJOR.0.0"
    MESSAGE="Bumped major version: $VERSION -> $NEW_VERSION"
    ;;
  "minor")
    NEW_MINOR=$((MINOR + 1))
    NEW_VERSION="$MAJOR.$NEW_MINOR.0"
    MESSAGE="Bumped minor version: $VERSION -> $NEW_VERSION"
    ;;
  "patch")
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"
    MESSAGE="Bumped patch version: $VERSION -> $NEW_VERSION"
    ;;
  "build")
    NEW_BUILD=$((BUILD + 1))
    NEW_VERSION="$VERSION"
    MESSAGE="Bumped build number: $BUILD -> $NEW_BUILD"
    ;;
  *)
    usage
    ;;
esac

# Update build number always for App Store submission
if [ "$1" != "build" ]; then
  NEW_BUILD=$((BUILD + 1))
fi

# Update pubspec.yaml
NEW_FULL_VERSION="$NEW_VERSION+$NEW_BUILD"
sed -i.bak "s/^version: $CURRENT_VERSION/version: $NEW_FULL_VERSION/" $PUBSPEC && rm ${PUBSPEC}.bak

echo "$MESSAGE"
echo "New version: $NEW_FULL_VERSION"
echo ""
echo "✅ Updated $PUBSPEC with new version"
echo "Don't forget to commit these changes!" 