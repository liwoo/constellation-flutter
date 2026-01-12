#!/bin/sh

# Xcode Cloud CI script to set up Flutter before building
# This script runs automatically after Xcode Cloud clones the repository

set -e

echo "=== Setting up Flutter for Xcode Cloud ==="

# Navigate to repository root
cd $CI_PRIMARY_REPOSITORY_PATH

# Install Flutter using git
echo "Cloning Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter

# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

# Disable analytics
flutter config --no-analytics

# Run Flutter doctor
echo "Running flutter doctor..."
flutter doctor -v

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Build iOS (generates SPM packages)
echo "Building iOS configuration..."
flutter build ios --config-only --release --no-codesign

echo "=== Flutter setup complete ==="
