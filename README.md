# Medical Reminder App (MRA)

A Flutter-based mobile health app that helps patients adhere to their prescribed medications through timely reminders, tracking, and smart notifications.

## Features (MVP)

- ✅ **Authentication**: Email/Password authentication with Firebase Auth
- ✅ **Medication Management**: Add, edit, delete medications with custom schedules
- ✅ **Smart Reminders**: Local notifications for medication doses
- ✅ **Medication Tracking**: Log medication events (Taken, Snoozed, Skipped)
- ✅ **Dashboard**: View upcoming medications and daily summary
- ✅ **Health Tips**: View health tips from Firestore
- ✅ **User Profile**: Manage user profile and settings
- ✅ **Modern UI**: Material 3 design with clean, accessible interface

## Tech Stack

- **Frontend**: Flutter 3+ (Dart)
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore)
- **Notifications**: flutter_local_notifications
- **Routing**: go_router
- **Analytics**: Firebase Analytics + Crashlytics

## Setup Instructions

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Android SDK
- Firebase account

### Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or select existing
3. Add Android app:
   - Package name: `com.mra.mra_app`
   - Download `google-services.json`
   - Place it at: `android/app/google-services.json`

4. Enable Authentication:
   - Go to Authentication > Sign-in method
   - Enable Email/Password provider

5. Set up Firestore:
   - Go to Firestore Database
   - Create database in production mode (or test mode for development)
   - Add security rules (see `firestore.rules` template)

6. Create Firestore collections:
   - `healthTips` - for health tips (optional, can add later)
   - Structure:
     ```json
     {
       "title": "Tip title",
       "content": "Tip content",
       "category": "General",
       "createdAt": <timestamp>
     }
     ```

### Installation

1. Clone the repository:
   ```bash
   cd mra_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── app/
│   ├── app_bootstrap.dart      # App initialization
│   ├── routing/
│   │   └── app_router.dart     # Navigation routes
│   └── theme/
│       └── app_theme.dart      # App theming
├── core/
│   ├── models/                  # Data models
│   └── services/                # Core services
├── features/
│   ├── auth/                    # Authentication
│   ├── dashboard/               # Dashboard screen
│   ├── medication/               # Medication CRUD
│   ├── logs/                    # Medication logging
│   ├── tips/                    # Health tips
│   └── profile/                 # User profile
└── di/
    └── providers.dart           # Riverpod providers
```

## Firestore Schema

### Users Collection
```
users/{uid}/
  ├── profile: {
  │     name: string
  │     age: number?
  │     gender: string?
  │     conditions: string[]
  │     emergencyContact: string?
  │     caregiverIds: string[]
  │   }
  ├── medications/{medId}: {
  │     name: string
  │     dosage: string
  │     timesPerDay: string[]
  │     frequency: string
  │     startDate: number (timestamp)
  │     endDate: number? (timestamp)
  │     notes: string?
  │     refillThreshold: number?
  │   }
  └── medLogs/{logId}: {
        medicationId: string
        timestamp: number (timestamp)
        status: string (taken|snoozed|skipped)
        scheduledDoseTime: number (timestamp)
        notes: string?
      }
```

### Health Tips Collection
```
healthTips/{tipId}: {
  title: string
  content: string
  category: string?
  createdAt: timestamp
}
```

## Security Rules Template

See `firestore.rules` for security rules that ensure users can only access their own data.

## Development Notes

- The app requires Android SDK 23+ (Android 6.0+)
- Notifications require POST_NOTIFICATIONS permission (Android 13+)
- All user data is stored in Firestore with user-based security rules
- Local notifications are scheduled using flutter_local_notifications

## Future Enhancements (Phase 2)

- Google Sign-In
- Charts and analytics visualization
- Dark mode polish
- Snooze interval customization
- Medication export (CSV/PDF)
- Caregiver monitoring
- Push notifications (FCM)

## License

This project is for educational purposes.
# mra_app
# mra_app
