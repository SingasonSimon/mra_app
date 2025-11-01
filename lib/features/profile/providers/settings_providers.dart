import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../di/providers.dart';

// Settings manager class
class SettingsManager {
  final SharedPreferences prefs;

  SettingsManager(this.prefs);

  bool get medicationRemindersEnabled => prefs.getBool('medicationRemindersEnabled') ?? true;
  bool get refillRemindersEnabled => prefs.getBool('refillRemindersEnabled') ?? true;
  bool get darkMode => prefs.getBool('darkMode') ?? false;
  bool get largeTextMode => prefs.getBool('largeTextMode') ?? false;

  Future<void> setMedicationReminders(bool value) async {
    await prefs.setBool('medicationRemindersEnabled', value);
  }

  Future<void> setRefillReminders(bool value) async {
    await prefs.setBool('refillRemindersEnabled', value);
  }

  Future<void> setDarkMode(bool value) async {
    await prefs.setBool('darkMode', value);
  }

  Future<void> setLargeTextMode(bool value) async {
    await prefs.setBool('largeTextMode', value);
  }
}

// Provider for SettingsManager
final settingsManagerProvider = FutureProvider<SettingsManager>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsManager(prefs);
});

// Notification preferences providers
final medicationRemindersEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsManagerProvider);
  return settingsAsync.value?.medicationRemindersEnabled ?? true;
});

final refillRemindersEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsManagerProvider);
  return settingsAsync.value?.refillRemindersEnabled ?? true;
});

// Theme preferences providers
final darkModeEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsManagerProvider);
  return settingsAsync.value?.darkMode ?? false;
});

// Accessibility preferences providers
final largeTextModeEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsManagerProvider);
  return settingsAsync.value?.largeTextMode ?? false;
});

// Helper providers for easy access (aliases)
final medicationRemindersProvider = medicationRemindersEnabledProvider;
final refillRemindersProvider = refillRemindersEnabledProvider;
final darkModeProvider = darkModeEnabledProvider;
final largeTextModeProvider = largeTextModeEnabledProvider;
