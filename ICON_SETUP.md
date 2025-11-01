# App Icon Setup Guide

## Steps to Set Up Your App Icon

### 1. Save Your Icon Image
Place your app icon image file in the following location:
```
mra_app/assets/images/icon.png
```

**Requirements:**
- File name must be `icon.png`
- Recommended size: **1024x1024 pixels** (square)
- Format: PNG with transparency support
- The image will be automatically resized for different platforms

### 2. Generate Icons
After saving the icon file, run the following command in the `mra_app` directory:

```bash
cd /home/singason/Desktop/code/med-app/mra_app
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for:
- Android (all density buckets: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- iOS (if configured)

### 3. Verify the Icons
After generation, you can verify the icons were created by checking:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- The icons should be automatically generated in all required sizes

### 4. Rebuild the App
After generating the icons, rebuild your app:

```bash
flutter clean
flutter build apk --release
```

Or for development:
```bash
flutter run
```

## Current Configuration

The `pubspec.yaml` is already configured with:
- `flutter_launcher_icons` package
- Icon path: `assets/images/icon.png`
- Android support enabled
- Minimum SDK: 23

## Notes

- The icon image should have a square aspect ratio
- Transparent backgrounds are supported
- The tool will automatically create adaptive icons for Android
- Make sure your icon looks good at small sizes (it will be displayed at various sizes on devices)

