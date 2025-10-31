import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  AnalyticsService(this._analytics, this._crashlytics);

  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason}) async {
    await _crashlytics.recordError(error, stackTrace, reason: reason);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}

