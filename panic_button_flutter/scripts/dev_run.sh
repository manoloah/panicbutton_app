#!/bin/bash
# Script to run the app with Supabase credentials from .env or command line args

# Default device (can be overridden by -d argument)
DEVICE="chrome"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      DEVICE="$2"
      shift 2
      ;;
    --url)
      SUPABASE_URL="$2"
      shift 2
      ;;
    --key)
      SUPABASE_ANON_KEY="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Check if SUPABASE_URL and SUPABASE_ANON_KEY are set from command line
# If not, try to load from .env file
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  if [ -f ".env" ]; then
    echo "Loading Supabase credentials from .env file"
    export $(grep -v '^#' .env | xargs)
  else
    echo "No .env file found. Create one or provide credentials via --url and --key"
    echo "Example: ./scripts/dev_run.sh --url https://your-project.supabase.co --key your-anon-key"
    exit 1
  fi
fi

# Print configuration (mask the key for security)
echo "Running with: "
echo "- Device: $DEVICE"
echo "- Supabase URL: $SUPABASE_URL"
echo "- Supabase Key: ${SUPABASE_ANON_KEY:0:5}...${SUPABASE_ANON_KEY: -5}"

# Run the app with the credentials
flutter run -d $DEVICE \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY 