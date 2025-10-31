# Testing Guide - Medical Reminder App

## ✅ What's Working (MVP Core Features)

### 1. Authentication
- **Sign Up**: Create account with email/password
- **Sign In**: Login with existing credentials
- **Auto-login**: App remembers logged-in state
- **Sign Out**: Logout from dashboard/profile

**Test Steps:**
1. First launch → Should show splash → Login screen
2. Tap "Sign Up" → Create account
3. After signup → Redirected to dashboard
4. Close app → Reopen → Should auto-login

### 2. Medication Management
- **Add Medication**: 
  - Name, dosage, multiple times per day
  - Start/end dates, notes
- **View Medications**: List all medications
- **Edit Medication**: Update details
- **Delete Medication**: Remove medication

**Test Steps:**
1. Dashboard → Tap "Add Medication" FAB
2. Fill form → Add 2-3 dose times
3. Save → Should appear in list
4. Long press or menu → Edit/Delete

### 3. Dashboard
- Shows welcome message with user name
- Displays upcoming medications
- Quick navigation to all features

**Test Steps:**
1. Login → Should see dashboard
2. Add medication → Should appear in "Upcoming Medications"
3. Tap "View All" → Should show medication list

### 4. Notifications
- **Scheduled**: Notifications scheduled when medication added
- **Reminders**: Should appear at scheduled times

**Test Steps:**
1. Add medication with time 1-2 minutes from now
2. Wait for notification
3. Check if notification appears (may need to grant permission on first launch)

**Note**: Notification actions (Take/Snooze/Skip) are scheduled but not yet connected to logging (Phase 2)

### 5. Profile
- View and edit profile
- Update name, age, gender, emergency contact

**Test Steps:**
1. Dashboard → Tap profile icon
2. Edit fields → Save
3. Return to dashboard → Should see updated name

### 6. Health Tips
- View tips from Firestore (if collection exists)

**Test Steps:**
1. Dashboard → Tap lightbulb icon
2. Should show tips screen (empty if no tips in Firestore)

## ⚠️ Known Limitations (To Complete MVP)

### 1. Medication Logging UI
- Logging repository exists but no UI screen yet
- Need: Screen to mark doses as Taken/Snoozed/Skipped
- Need: History view showing past logs

### 2. Notification Actions
- Actions defined but not connected to logging
- Need: Wire Take/Snooze/Skip buttons to log events

### 3. Settings Screen
- Profile screen exists but no settings for:
  - Language selection (English/Swahili)
  - Font size adjustment
  - High contrast mode
  - Notification preferences

### 4. Adherence Analytics
- Stats calculation exists but no visualization
- Need: Charts showing adherence percentage
- Need: Weekly/monthly views

## 🐛 Common Issues & Solutions

### Issue: "FirebaseApp not initialized"
**Solution**: Make sure `google-services.json` is in `android/app/`

### Issue: Notifications not appearing
**Solutions**:
- Check app notification permissions in device settings
- Verify notification channel was created (check logs)
- For testing, schedule notification 1-2 minutes ahead

### Issue: "Permission denied" on Firestore
**Solution**: 
- Check Firestore security rules are deployed
- Verify user is authenticated
- Check Firebase Console → Firestore → Rules

### Issue: Tips screen shows empty
**Solution**: 
- This is expected if `healthTips` collection doesn't exist
- Add tips via Firebase Console or leave empty for now

### Issue: App crashes on launch
**Solution**:
- Check `flutter run -v` for detailed errors
- Verify Firebase project configuration
- Check if minSdk version is compatible with device

## 📋 Testing Checklist

- [ ] Can sign up new account
- [ ] Can sign in with existing account
- [ ] Auto-login works after app restart
- [ ] Can add medication with multiple times
- [ ] Medication appears in dashboard
- [ ] Can edit medication
- [ ] Can delete medication
- [ ] Notifications appear at scheduled time
- [ ] Can update profile
- [ ] Profile changes reflect in dashboard
- [ ] Tips screen loads (even if empty)
- [ ] Logout works correctly

## 🔍 Firestore Data Check

After testing, check Firebase Console → Firestore:
- `users/{uid}/profile` - Should have user profile
- `users/{uid}/medications/{medId}` - Should have medications
- `users/{uid}/medLogs` - Empty for now (logging UI pending)

## Next Steps After Testing

1. **If everything works**: 
   - Consider adding logging UI screen
   - Wire up notification actions
   - Add settings screen

2. **If issues found**:
   - Check `flutter logs` for errors
   - Verify Firebase configuration
   - Test on different Android versions

3. **Before production**:
   - Add error handling polish
   - Test on multiple devices
   - Add localization strings
   - Create app icons/splash screens

