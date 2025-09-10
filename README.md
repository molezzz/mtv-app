# mtv_app

A Flutter-based multimedia application with comprehensive casting support.

## Features

### Video Playback
- Multiple video format support
- Adaptive streaming with quality selection
- Full-screen playback with custom controls
- Playback speed adjustment

### Casting Support
The application supports multiple casting protocols:
- **Chromecast**: Native Google Cast SDK integration
- **DLNA**: UPnP-based media streaming
- **Miracast**: WiFi Direct screen mirroring

### Multi-platform Support
- Android (primary target)
- iOS
- Web
- Windows/Linux/macOS desktop

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Development and Build Scripts

This project includes a batch script (`run.bat`) to simplify common development and build tasks.

### Prerequisites

- Flutter SDK installed and configured in your PATH.
- An Android device or emulator connected for running/building the app.

### Usage

Open a command prompt or terminal in the project root directory and use the following commands:

**Start Development Server:**
```shell
run.bat dev
```

**Build Android APK:**
```shell
run.bat build-apk
```
The output will be located in `build\app\outputs\flutter-apk\app-release.apk`.

**Build Android App Bundle:**
```shell
run.bat build-appbundle
```
The output will be located in `build\app\outputs\bundle\release\app-release.aab`.