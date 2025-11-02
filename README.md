# MRA - Medical Reminder Application

A comprehensive Flutter application for managing medication reminders, tracking adherence, and maintaining medical records.

## Table of Contents

- [System Requirements](#system-requirements)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Project Setup](#project-setup)
- [Firebase Configuration](#firebase-configuration)
- [Running the Application](#running-the-application)
- [Building the Application](#building-the-application)
- [Troubleshooting](#troubleshooting)

## System Requirements

### Operating System
- Windows 10 or later (64-bit)
- Minimum 8 GB RAM (16 GB recommended)
- At least 10 GB free disk space

### Development Tools
- Git for version control
- A code editor (VS Code recommended)

## Prerequisites

Before setting up the project, ensure you have the following installed:

### 1. Flutter SDK

1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract the ZIP file to a location like `C:\src\flutter`
3. Add Flutter to your PATH:
   - Search for "Environment Variables" in Windows
   - Edit the "Path" variable under System Variables
   - Add: `C:\src\flutter\bin`
4. Verify installation:
   ```bash
   flutter doctor
   ```

### 2. Android Studio

1. Download from [developer.android.com/studio](https://developer.android.com/studio)
2. Install Android Studio
3. Open Android Studio and install:
   - Android SDK
   - Android SDK Platform-Tools
   - Android Emulator
4. Configure Android SDK:
   - Open Android Studio
   - Go to File > Settings > Appearance & Behavior > System Settings > Android SDK
   - Ensure SDK Platform Android 13.0 (API level 33) or higher is installed
   - Install Android SDK Build-Tools

### 3. Java Development Kit (JDK)

1. Download JDK 17 or later from [adoptium.net](https://adoptium.net/)
2. Install JDK
3. Set JAVA_HOME environment variable:
   - Create new System Variable: `JAVA_HOME`
   - Set value to: `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot` (adjust path as needed)

### 4. VS Code (Recommended)

1. Download from [code.visualstudio.com](https://code.visualstudio.com/)
2. Install Flutter and Dart extensions:
   - Open VS Code
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "Flutter" and install
   - Search for "Dart" and install

### 5. Google Account

You'll need a Google account to configure Firebase services.

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd med-app/mra_app
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

This will download all required packages defined in `pubspec.yaml`.

### Step 3: Verify Flutter Setup

```bash
flutter doctor -v
```

Resolve any issues reported by Flutter Doctor. Common fixes:
- Accept Android licenses: `flutter doctor --android-licenses`
- Install missing components through Android Studio

## Project Setup

### Directory Structure

```
mra_app/
├── lib/
│   ├── app/              # App configuration, routing, theme
│   ├── core/             # Core models, services, utilities
│   ├── features/         # Feature modules (auth, medication, logs, etc.)
│   ├── widgets/          # Reusable widgets
│   └── main.dart         # Application entry point
├── android/              # Android-specific files
├── ios/                  # iOS-specific files (if applicable)
├── assets/               # Images, fonts, and other assets
└── pubspec.yaml          # Project dependencies
```

### Key Dependencies

- **flutter_riverpod**: State management
- **go_router**: Navigation and routing
- **firebase_core, firebase_auth, cloud_firestore**: Firebase services
- **flutter_local_notifications**: Local notification handling
- **google_sign_in**: Google authentication

## Firebase Configuration

### Step 1: Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name and follow setup wizard
4. Enable Google Analytics (optional)

### Step 2: Add Android App to Firebase

1. In Firebase Console, click "Add app" and select Android
2. Register app:
   - Package name: Check `android/app/build.gradle` for `applicationId`
   - App nickname: MRA
   - Debug signing certificate (optional for development)
3. Download `google-services.json`
4. Place file in: `android/app/google-services.json`

### Step 3: Configure Authentication

1. In Firebase Console, go to Authentication
2. Enable "Google" sign-in method
3. Add your app's package name and SHA-1 certificate fingerprint

### Step 4: Configure Firestore Database

1. Go to Firestore Database in Firebase Console
2. Create database in test mode (for development)
3. Set location closest to your region
4. Update security rules as needed for production

### Step 5: Get Google Sign-In Credentials

1. Go to [console.cloud.google.com](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to APIs & Services > Credentials
4. Create OAuth 2.0 Client ID for Android
5. Note the Client ID for use in the app

## Running the Application

### Option 1: Using Android Emulator

1. Start Android Studio
2. Open AVD Manager (Tools > Device Manager)
3. Create a virtual device:
   - Click "Create Device"
   - Select a device (e.g., Pixel 5)
   - Download and select a system image (API 33 or higher)
   - Finish setup
4. Start the emulator
5. Run the app:
   ```bash
   flutter run
   ```

### Option 2: Using Physical Device

1. Enable Developer Options on your Android device:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Settings > Developer Options > USB Debugging
3. Connect device via USB
4. Verify connection:
   ```bash
   flutter devices
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Building the Application

### Debug Build

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release Build

```bash
flutter build apk --release --no-tree-shake-icons
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### App Bundle (for Play Store)

```bash
flutter build appbundle --release --no-tree-shake-icons
```

Output: `build/app/outputs/bundle/release/app-release.aab`

**Note:** The `--no-tree-shake-icons` flag prevents Flutter from removing unused icons, ensuring all app icons are included in the build.

## Common Issues and Solutions

### Issue: "SDK location not found"

**Solution:**
1. Create `local.properties` in `android/` directory
2. Add:
   ```
   sdk.dir=C:\\Users\\YourUsername\\AppData\\Local\\Android\\Sdk
   ```
   (Adjust path to your Android SDK location)

### Issue: "Gradle build failed"

**Solution:**
1. Check Java version: `java -version` (should be 17+)
2. Update `android/gradle/wrapper/gradle-wrapper.properties` to use Gradle 7.5+
3. Clear cache: `flutter clean` then `flutter pub get`

### Issue: "Firebase not configured"

**Solution:**
1. Ensure `google-services.json` is in `android/app/`
2. Check `android/app/build.gradle` has:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
3. Verify package name matches Firebase project

### Issue: "Google Sign-In not working"

**Solution:**
1. Verify SHA-1 fingerprint is added in Firebase Console
2. Get SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
3. Add SHA-1 to Firebase project settings

### Issue: "Dependencies conflict"

**Solution:**
1. Update Flutter: `flutter upgrade`
2. Clean project: `flutter clean`
3. Get dependencies: `flutter pub get`
4. If issues persist, check `pubspec.yaml` for version conflicts

## Testing

Run tests:

```bash
flutter test
```

Run with coverage:

```bash
flutter test --coverage
```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Guide](https://dart.dev/guides)

## Getting Help

If you encounter issues:
1. Check Flutter Doctor: `flutter doctor -v`
2. Review error messages in terminal
3. Check Firebase Console for service status
4. Verify all prerequisites are installed correctly

## License

This project is for educational/personal use. Ensure compliance with healthcare data regulations when handling medical information.

