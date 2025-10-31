import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../app/routing/app_router.dart';
import '../core/services/local_storage.dart';
import '../core/services/analytics_service.dart';
import '../core/services/notifications_service.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return appRouter;
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return LocalStorage(prefsAsync.value!);
});

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>((ref) {
  return FirebaseAnalytics.instance;
});

final firebaseCrashlyticsProvider = Provider<FirebaseCrashlytics>((ref) {
  return FirebaseCrashlytics.instance;
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final analytics = ref.watch(firebaseAnalyticsProvider);
  final crashlytics = ref.watch(firebaseCrashlyticsProvider);
  return AnalyticsService(analytics, crashlytics);
});

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});


