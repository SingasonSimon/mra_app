import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Medical Reminder App',
      'login': 'Sign In',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'confirm_password': 'Confirm Password',
      'dashboard': 'Dashboard',
      'medications': 'Medications',
      'add_medication': 'Add Medication',
      'edit_medication': 'Edit Medication',
      'medication_name': 'Medication Name',
      'dosage': 'Dosage',
      'dose_times': 'Dose Times',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'notes': 'Notes',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'history': 'History',
      'log_medication': 'Log Medication',
      'taken': 'Taken',
      'snoozed': 'Snoozed',
      'skipped': 'Skip',
      'profile': 'Profile',
      'settings': 'Settings',
      'health_tips': 'Health Tips',
      'logout': 'Logout',
      'welcome': 'Welcome',
      'upcoming_medications': 'Upcoming Medications',
      'no_medications': 'No medications scheduled',
      'language': 'Language',
      'font_size': 'Font Size',
      'high_contrast': 'High Contrast Mode',
      'notifications': 'Notifications',
    },
    'sw': {
      'app_name': 'Programu ya Kukumbusha Dawa',
      'login': 'Ingia',
      'signup': 'Jisajili',
      'email': 'Barua Pepe',
      'password': 'Nenosiri',
      'name': 'Jina',
      'confirm_password': 'Thibitisha Nenosiri',
      'dashboard': 'Dashibodi',
      'medications': 'Dawa',
      'add_medication': 'Ongeza Dawa',
      'edit_medication': 'Hariri Dawa',
      'medication_name': 'Jina la Dawa',
      'dosage': 'Kipimo',
      'dose_times': 'Muda wa Kuchukua',
      'start_date': 'Tarehe ya Kuanza',
      'end_date': 'Tarehe ya Mwisho',
      'notes': 'Maelezo',
      'save': 'Hifadhi',
      'delete': 'Futa',
      'edit': 'Hariri',
      'history': 'Historia',
      'log_medication': 'Andika Dawa',
      'taken': 'Imechukuliwa',
      'snoozed': 'Imecheleweshwa',
      'skipped': 'Ruka',
      'profile': 'Wasifu',
      'settings': 'Mipangilio',
      'health_tips': 'Vidokezo vya Afya',
      'logout': 'Toka',
      'welcome': 'Karibu',
      'upcoming_medications': 'Dawa Zinazokuja',
      'no_medications': 'Hakuna dawa zilizopangwa',
      'language': 'Lugha',
      'font_size': 'Ukubwa wa Herufi',
      'high_contrast': 'Hali ya Tofauti Kubwa',
      'notifications': 'Arifa',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common strings
  String get appName => translate('app_name');
  String get login => translate('login');
  String get signup => translate('signup');
  String get email => translate('email');
  String get password => translate('password');
  String get name => translate('name');
  String get confirmPassword => translate('confirm_password');
  String get dashboard => translate('dashboard');
  String get medications => translate('medications');
  String get addMedication => translate('add_medication');
  String get editMedication => translate('edit_medication');
  String get medicationName => translate('medication_name');
  String get dosage => translate('dosage');
  String get doseTimes => translate('dose_times');
  String get startDate => translate('start_date');
  String get endDate => translate('end_date');
  String get notes => translate('notes');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get history => translate('history');
  String get logMedication => translate('log_medication');
  String get taken => translate('taken');
  String get snoozed => translate('snoozed');
  String get skipped => translate('skipped');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get healthTips => translate('health_tips');
  String get logout => translate('logout');
  String get welcome => translate('welcome');
  String get upcomingMedications => translate('upcoming_medications');
  String get noMedications => translate('no_medications');
  String get language => translate('language');
  String get fontSize => translate('font_size');
  String get highContrast => translate('high_contrast');
  String get notifications => translate('notifications');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'sw'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

