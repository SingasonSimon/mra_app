import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../di/providers.dart';
import '../../../app/routing/app_router.dart';
import '../../../widgets/page_enter_transition.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedLanguage = 'en';
  double _fontSize = 1.0;
  bool _highContrast = false;
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  int _snoozeInterval = 15; // minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefsAsync = ref.read(sharedPreferencesProvider);
    final prefs = prefsAsync.value;
    if (prefs != null) {
      setState(() {
        _selectedLanguage = prefs.getString('language') ?? 'en';
        _fontSize = prefs.getDouble('fontSize') ?? 1.0;
        _highContrast = prefs.getBool('highContrast') ?? false;
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _darkMode = prefs.getBool('darkMode') ?? false;
        _snoozeInterval = prefs.getInt('snoozeInterval') ?? 15;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefsAsync = ref.read(sharedPreferencesProvider);
    final prefs = prefsAsync.value;
    if (prefs == null) return;
    prefs.setString('language', _selectedLanguage);
    prefs.setDouble('fontSize', _fontSize);
    prefs.setBool('highContrast', _highContrast);
    prefs.setBool('notificationsEnabled', _notificationsEnabled);
    prefs.setBool('darkMode', _darkMode);
    prefs.setInt('snoozeInterval', _snoozeInterval);

    // Invalidate locale provider to update app language
    ref.invalidate(localeProvider);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
      // Restart app to apply language change
      // In production, you might want to use a stateful approach
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: PageEnterTransition(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Language',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  RadioListTile<String>(
                    title: const Text('English'),
                    value: 'en',
                    groupValue: _selectedLanguage,
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Swahili'),
                    value: 'sw',
                    groupValue: _selectedLanguage,
                    onChanged: (value) {
                      setState(() => _selectedLanguage = value!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Font Size',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Small'),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: _fontSize.toStringAsFixed(1),
                            onChanged: (value) {
                              setState(() => _fontSize = value);
                            },
                          ),
                        ),
                        const Text('Large'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Current: ${(_fontSize * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('High Contrast Mode'),
                subtitle: const Text('Increase contrast for better visibility'),
                value: _highContrast,
                onChanged: (value) {
                  setState(() => _highContrast = value);
                },
                secondary: const Icon(Icons.contrast),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Enable medication reminders'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                secondary: const Icon(Icons.notifications),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                },
                secondary: const Icon(Icons.dark_mode),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Snooze Interval',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('5 min'),
                        Expanded(
                          child: Slider(
                            value: _snoozeInterval.toDouble(),
                            min: 5,
                            max: 60,
                            divisions: 11,
                            label: '$_snoozeInterval minutes',
                            onChanged: (value) {
                              setState(() => _snoozeInterval = value.toInt());
                            },
                          ),
                        ),
                        const Text('60 min'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Current: $_snoozeInterval minutes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
