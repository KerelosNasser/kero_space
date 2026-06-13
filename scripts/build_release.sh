#!/bin/bash
set -e

echo "Cleaning..."
flutter clean
flutter pub get

echo "Building obfuscated Release APK..."
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

echo "Copying APK to dist/..."
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/kero_space_release.apk

echo "Done! APK available at dist/kero_space_release.apk"
