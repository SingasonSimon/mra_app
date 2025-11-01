import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/settings_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final medicationReminders = ref.watch(medicationRemindersProvider);
    final refillReminders = ref.watch(refillRemindersProvider);
    final darkMode = ref.watch(darkModeProvider);
    final largeTextMode = ref.watch(largeTextModeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Teal/Green Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Avatar with initials
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(profileAsync.value?.name ?? user?.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileAsync.value?.name ?? user?.displayName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                            if (profileAsync.value?.age != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Age: ${profileAsync.value!.age}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medical Conditions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Medical Conditions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          profileAsync.when(
                            data: (profile) {
                              if (profile == null || profile.conditions.isEmpty) {
                                return Text(
                                  'No conditions added',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: profile.conditions.map((condition) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: condition.toLowerCase().contains('diabetes')
                                          ? Colors.green[50]
                                          : Colors.blue[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      condition,
                                      style: TextStyle(
                                        color: condition.toLowerCase().contains('diabetes')
                                            ? Colors.green[700]
                                            : Colors.blue[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Account Settings
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _SettingsItem(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () {
                              context.push('/profile/edit');
                            },
                          ),
                          const Divider(height: 1),
                          _SettingsItem(
                            icon: Icons.calendar_today_outlined,
                            title: 'Medical History',
                            onTap: () {
                              context.push('/profile/medical-history');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Notifications
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _SwitchSettingsItem(
                            icon: Icons.notifications_outlined,
                            iconColor: Colors.green,
                            title: 'Medication Reminders',
                            subtitle: 'Get notified for doses',
                            value: medicationReminders,
                            onChanged: (value) async {
                              final settings = await ref.read(settingsManagerProvider.future);
                              await settings.setMedicationReminders(value);
                              ref.invalidate(settingsManagerProvider);
                            },
                          ),
                          const Divider(height: 1),
                          _SwitchSettingsItem(
                            icon: Icons.calendar_today_outlined,
                            iconColor: Colors.blue,
                            title: 'Refill Reminders',
                            subtitle: 'Low supply alerts',
                            value: refillReminders,
                            onChanged: (value) async {
                              final settings = await ref.read(settingsManagerProvider.future);
                              await settings.setRefillReminders(value);
                              ref.invalidate(settingsManagerProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Caregiver & Sharing - Future Feature
                    // TODO: Implement Caregiver & Sharing feature in future version
                    /*
                    const Text(
                      'Caregiver & Sharing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _SettingsItem(
                        icon: Icons.people_outline,
                        iconColor: Colors.purple,
                        title: 'Connect Caregiver',
                        subtitle: 'Share your medication data',
                        onTap: () {
                          context.push('/caregiver');
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    */
                    // Preferences
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _SwitchSettingsItem(
                            icon: Icons.dark_mode_outlined,
                            iconColor: Colors.grey,
                            title: 'Dark Mode',
                            subtitle: 'Easier on the eyes',
                            value: darkMode,
                            onChanged: (value) async {
                              final settings = await ref.read(settingsManagerProvider.future);
                              await settings.setDarkMode(value);
                              ref.invalidate(settingsManagerProvider);
                            },
                          ),
                          const Divider(height: 1),
                          _SwitchSettingsItem(
                            icon: Icons.text_fields,
                            iconColor: Colors.green,
                            title: 'Large Text Mode',
                            subtitle: 'Better accessibility',
                            value: largeTextMode,
                            onChanged: (value) async {
                              final settings = await ref.read(settingsManagerProvider.future);
                              await settings.setLargeTextMode(value);
                              ref.invalidate(settingsManagerProvider);
                            },
                          ),
                          const Divider(height: 1),
                          _SettingsItem(
                            icon: Icons.shield_outlined,
                            iconColor: Colors.blue,
                            title: 'Privacy & Data',
                            onTap: () {
                              context.push('/profile/privacy');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Log Out Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Log Out'),
                                    content: const Text('Are you sure you want to log out?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('Log Out'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  final repository = ref.read(authRepositoryProvider);
                                  await repository.signOut();
                                  if (context.mounted) {
                                    context.go('/welcome');
                                  }
                                }
                              },
                              child: const Text(
                                'Log Out',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 3),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey[700],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _SwitchSettingsItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey[700],
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
