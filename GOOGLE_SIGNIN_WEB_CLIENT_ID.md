# Google Sign-In Web Client ID Setup

## Issue
Google Sign-In on Android requires a `serverClientId` which is the **Web Client ID** from Firebase Console, not the Android client ID.

## Error Message
```
GoogleSignInException(code GoogleSignInExceptionCode.clientConfigurationError, 
serverClientId must be provided on Android, null)
```

## Solution

### Step 1: Get the Web Client ID from Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **mra-app-ca665**
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Google** provider
5. Look for **Web SDK configuration** section
6. Copy the **Web client ID** (it should look like: `746414767673-xxxxxxxxxxxxx.apps.googleusercontent.com`)

**Note:** If you don't see a Web client ID, you need to:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your project: **mra-app-ca665**
   - Navigate to **APIs & Services** > **Credentials**
   - Find or create an **OAuth 2.0 Client ID** with type **Web application**
   - Copy the Client ID

### Step 2: Update the Code

1. Open `lib/features/auth/repository/auth_repository.dart`
2. Find the `_googleSignIn` initialization (around line 14)
3. Replace the `serverClientId` value with your Web Client ID:

```dart
late final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);
```

### Step 3: Test

1. Run the app: `flutter run`
2. Try signing in with Google
3. It should work now!

## Important Notes

- **Android Client ID** (from `google-services.json`) ≠ **Web Client ID** (from Firebase Console)
- The Web Client ID is required for Android apps to authenticate with Google Sign-In
- Both client IDs should be from the same Firebase project
- The Web Client ID format is: `PROJECT_NUMBER-xxxxxxxxxxxxx.apps.googleusercontent.com`

## Troubleshooting

If you still get errors:

1. **Verify SHA-1 and SHA-256 fingerprints** are added in Firebase Console:
   - Android app settings > SHA certificate fingerprints
   - Your SHA-1: `8F:77:54:F5:07:1C:1E:7A:D0:B8:BF:A7:87:E6:92:EB:77:37:86:DB`

2. **Check Google Sign-In is enabled** in Firebase Console:
   - Authentication > Sign-in method > Google > Enable

3. **Ensure OAuth consent screen is configured** in Google Cloud Console:
   - APIs & Services > OAuth consent screen

4. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

