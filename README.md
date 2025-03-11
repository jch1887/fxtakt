# fxtakt

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Remove old dependencies   
rm -rf Pods Podfile.lock

# Reinstall CocoaPods (iOS/macOS dependencies)
pod install --verbose

# Go back to project root
cd ..

# Rebuild and run the app on macOS
flutter run -d macos

