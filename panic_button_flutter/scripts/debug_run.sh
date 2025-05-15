#!/bin/bash

# Exit on error
set -e

echo "🚀 Running Calme app in debug mode with environment variables..."

# Make sure we're in the project directory
cd "$(dirname "$0")/.."

# Load environment variables from .env
if [ -f .env ]; then
    echo "📋 Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ No .env file found!"
    echo "Create a .env file with the following variables:"
    echo "SUPABASE_URL=your_supabase_url"
    echo "SUPABASE_ANON_KEY=your_supabase_anon_key"
    echo ""
    echo "For security, never commit this file to version control."
    exit 1
fi

# Validate environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Missing Supabase credentials in .env file!"
    echo "Please ensure your .env file contains:"
    echo "SUPABASE_URL=your_supabase_url"
    echo "SUPABASE_ANON_KEY=your_supabase_anon_key"
    exit 1
fi

# Get list of available devices
echo "📱 Available iOS devices:"
flutter devices | grep "iOS" || echo "No iOS devices found"

# Ask for device ID or use default simulator
echo ""
echo "Enter the device ID or leave blank for default simulator:"
read DEVICE_ID

if [ -z "$DEVICE_ID" ]; then
    DEVICE_PARAM=""
    echo "Using default simulator device"
else
    DEVICE_PARAM="-d $DEVICE_ID"
    echo "Using device: $DEVICE_ID"
fi

# Show masked credentials for confirmation
MASKED_URL="${SUPABASE_URL}"
MASKED_KEY="${SUPABASE_ANON_KEY:0:5}...${SUPABASE_ANON_KEY: -5}"
echo "🔐 Using Supabase URL: $MASKED_URL"
echo "🔐 Using Supabase Key: $MASKED_KEY (masked for security)"

# Run the app with environment variables injected
echo "▶️ Running app with environment variables..."
flutter run $DEVICE_PARAM \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY 