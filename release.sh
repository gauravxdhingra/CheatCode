#!/bin/bash
set -e

BASE_URL="https://cheatcode-production-498b.up.railway.app"

if [ ! -f ".env.release" ]; then
  echo "❌ .env.release not found. Run: bash setup_release.sh"
  exit 1
fi
source .env.release

# Build type: apk (default) or aab
BUILD=${1:-apk}

CURRENT=$(grep '^version:' cheatcode-ui/pubspec.yaml | awk '{print $2}')
echo "Version: $CURRENT  |  Build: $BUILD"

cd cheatcode-ui
flutter clean && flutter pub get

if [ "$BUILD" = "aab" ]; then
  flutter build appbundle --release \
    --dart-define=BASE_URL="$BASE_URL" \
    --dart-define=API_KEY="$API_KEY" \
    --target-platform android-arm64
  OUT="build/app/outputs/bundle/release/app-release.aab"
else
  flutter build apk --release \
    --dart-define=BASE_URL="$BASE_URL" \
    --dart-define=API_KEY="$API_KEY" \
    --target-platform android-arm64
  OUT="build/app/outputs/flutter-apk/app-release.apk"
fi

echo ""
echo "✅ $(du -sh $OUT | cut -f1)  →  cheatcode-ui/$OUT"