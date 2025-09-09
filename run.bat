@echo off
setlocal

REM Get the command argument
set "command=%1"

if "%command%"=="" (
    goto help
)

if /I "%command%"=="dev" (
    echo "Starting development environment..."
    flutter run
    goto:eof
)

if /I "%command%"=="build-apk" (
    echo "Building Android APK (release)..."
    flutter build apk --release
    goto:eof
)

if /I "%command%"=="build-appbundle" (
    echo "Building Android App Bundle (release)..."
    flutter build appbundle --release
    goto:eof
)

echo "Invalid command: %command%"
:help
echo "Usage: run.bat [command]"
echo ""
echo "Available commands:"
echo "  dev              - Runs the app in development mode."
echo "  build-apk        - Builds the Android APK in release mode."
echo "  build-appbundle  - Builds the Android App Bundle in release mode."

endlocal
