#!/bin/bash
# Generate Freezed and JsonSerializable files

echo "🔧 Generating Freezed files for Core package..."

cd packages/core

# Clean old generated files
echo "Cleaning old generated files..."
find . -name "*.freezed.dart" -type f -delete
find . -name "*.g.dart" -type f -delete

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Run build_runner
echo "Running build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Generation complete!"

# Return to root
cd ../..

echo "📦 Generated files created successfully!"
