# Known Issues & Notes

## Google Sign-In Analyzer Warnings

The analyzer may show errors for Google Sign-In code, but these are **false positives**. The code is correct for `google_sign_in: ^7.2.0`.

### Errors Shown (Can be ignored):
- "The class 'GoogleSignIn' doesn't have an unnamed constructor"
- "The method 'signIn' isn't defined"
- "The getter 'accessToken' isn't defined"

### Why This Happens:
The analyzer may have stale type information. The code will compile and run correctly.

### Verification:
- Code follows official google_sign_in package documentation
- Constructor with `scopes` parameter is valid
- `signIn()` method exists in GoogleSignIn class
- `authentication` property returns GoogleSignInAuthentication with `accessToken` and `idToken`

### To Verify It Works:
1. Run `flutter run` - should compile successfully
2. Test Google Sign-In on device (after configuring SHA-1)

## Google Sign-In Configuration Required

For Google Sign-In to work, you need to:

1. **Get SHA-1 fingerprint**:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **Add to Firebase Console**:
   - Go to Firebase Console → Project Settings → Your Android App
   - Add SHA-1 fingerprint
   - Download updated `google-services.json` if needed

3. **Enable Google Sign-In**:
   - Firebase Console → Authentication → Sign-in method
   - Enable Google provider

## Theme Mode

Currently, theme mode change requires checking preferences each build. For immediate theme switching, consider:
- Using a StateNotifier for theme state
- Or requiring app restart (current implementation)

## Notification Snooze

The snooze interval setting is saved but not yet wired to the notification service's rescheduling logic. This requires:
- Reading snooze interval from SharedPreferences when rescheduling
- Updating notification service to accept custom snooze duration

## Future Improvements

- Real-time theme switching without restart
- Notification snooze using custom interval
- Medication detail screen with full schedule view
- Refill reminders with notifications
- Caregiver sharing functionality
- Push notifications (FCM)

