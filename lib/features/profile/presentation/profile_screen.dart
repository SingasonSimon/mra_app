import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/settings_providers.dart';
import '../../../utils/navigation_helper.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Teal Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1F2937), Color(0xFF111827)],
                      )
                    : AppTheme.tealGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(AppIcons.arrowLeft, color: AppTheme.white),
                        onPressed: () => context.safePop(),
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
                        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medical Conditions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          profileAsync.when(
                            data: (profile) {
                              if (profile == null || profile.conditions.isEmpty) {
                                return Text(
                                  'No conditions added',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppTheme.white.withValues(alpha: 0.6)
                                        : AppTheme.gray600,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: profile.conditions.map((condition) {
                                  final isTeal = condition.toLowerCase().contains('diabetes');
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isTeal
                                          ? AppTheme.successBg
                                          : AppTheme.blue100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      condition,
                                      style: TextStyle(
                                        color: isTeal
                                            ? AppTheme.successTextDark
                                            : AppTheme.blue700,
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
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _SettingsItem(
                            icon: AppIcons.user,
                            title: 'Edit Profile',
                            isDark: isDark,
                            onTap: () {
                              context.push('/profile/edit');
                            },
                          ),
                          Divider(height: 1, color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                          _SettingsItem(
                            icon: AppIcons.calendar,
                            title: 'Medical History',
                            isDark: isDark,
                            onTap: () {
                              context.push('/profile/medical-history');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Notifications
                    Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _SwitchSettingsItem(
                            icon: AppIcons.bell,
                            iconColor: AppTheme.teal600,
                            title: 'Medication Reminders',
                            subtitle: 'Get notified for doses',
                            value: medicationReminders,
                            isDark: isDark,
                            onChanged: (value) async {
                              final settings = await ref.read(settingsManagerProvider.future);
                              await settings.setMedicationReminders(value);
                              ref.invalidate(settingsManagerProvider);
                            },
                          ),
                          Divider(height: 1, color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                          _SwitchSettingsItem(
                            icon: AppIcons.calendar,
                            iconColor: AppTheme.blue600,
                            title: 'Refill Reminders',
                            subtitle: 'Low supply alerts',
                            value: refillReminders,
                            isDark: isDark,
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
                    Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _SwitchSettingsItem(
                            icon: AppIcons.moon,
                            iconColor: AppTheme.gray500,
                            title: 'Dark Mode',
                            subtitle: 'Easier on the eyes',
                            value: darkMode,
                            isDark: isDark,
                            onChanged: (value) async {
                              final settings = await ref.read(settingsManagerProvider.future);
                              await settings.setDarkMode(value);
                              ref.invalidate(settingsManagerProvider);
                            },
                          ),
                          Divider(height: 1, color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                          _SwitchSettingsItem(
                            icon: AppIcons.edit,
                            iconColor: AppTheme.teal600,
                            title: 'Large Text Mode',
                            subtitle: 'Better accessibility',
                            value: largeTextMode,
                            isDark: isDark,
                            onChanged: (value) async {
                              final settings = await ref.read(settingsManagerProvider.future);
                              await settings.setLargeTextMode(value);
                              ref.invalidate(settingsManagerProvider);
                            },
                          ),
                          Divider(height: 1, color: isDark ? AppTheme.gray700 : AppTheme.gray200),
                          _SettingsItem(
                            icon: AppIcons.shield,
                            iconColor: AppTheme.blue600,
                            title: 'Privacy & Data',
                            isDark: isDark,
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
                        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(AppIcons.logOut, color: AppTheme.red600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                                    title: Text(
                                      'Log Out',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.white : AppTheme.gray900,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to log out?',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.white.withValues(alpha: 0.6)
                                            : AppTheme.gray600,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.red600,
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
                              child: Text(
                                'Log Out',
                                style: TextStyle(
                                  color: AppTheme.red600,
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
  final bool isDark;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? AppTheme.gray400 : AppTheme.gray700),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.white : AppTheme.gray900,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.white.withValues(alpha: 0.6)
                    : AppTheme.gray600,
              ),
            )
          : null,
      trailing: Icon(
        AppIcons.chevronRight,
        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
      ),
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
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? AppTheme.gray400 : AppTheme.gray700),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.white : AppTheme.gray900,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.white.withValues(alpha: 0.6)
                    : AppTheme.gray600,
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
