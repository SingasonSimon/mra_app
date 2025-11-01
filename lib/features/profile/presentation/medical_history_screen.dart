import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../utils/navigation_helper.dart';
import 'package:intl/intl.dart';

class MedicalHistoryScreen extends ConsumerStatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  ConsumerState<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends ConsumerState<MedicalHistoryScreen> {

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppTheme.teal500,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.safePop(),
        ),
        title: const Text(
          'Medical History',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Summary Card
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
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.white : AppTheme.gray900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  profileAsync.when(
                    data: (profile) {
                      if (profile == null) {
                        return Text(
                          'No profile information available',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.white.withValues(alpha: 0.6)
                                : AppTheme.gray600,
                          ),
                        );
                      }
                      return Column(
                        children: [
                          _InfoRow(label: 'Name', value: profile.name),
                          if (profile.age != null)
                            _InfoRow(label: 'Age', value: profile.age.toString()),
                          if (profile.gender != null)
                            _InfoRow(label: 'Gender', value: profile.gender!),
                          if (profile.emergencyContact != null)
                            _InfoRow(
                              label: 'Emergency Contact',
                              value: profile.emergencyContact!,
                            ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(
                      'Error loading profile',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.white.withValues(alpha: 0.6)
                            : AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                  const SizedBox(height: 16),
                  profileAsync.when(
                    data: (profile) {
                      if (profile == null || profile.conditions.isEmpty) {
                        return Text(
                          'No conditions recorded',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.white.withValues(alpha: 0.6)
                                : AppTheme.gray600,
                            fontSize: 14,
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
                                    ? AppTheme.successText
                                    : AppTheme.blue600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => Text(
                      'Error loading conditions',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.white.withValues(alpha: 0.6)
                            : AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Account Creation Date
            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return Container(
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
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.white : AppTheme.gray900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'Member Since',
                        value: DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppTheme.white.withValues(alpha: 0.6)
                    : AppTheme.gray600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.white : AppTheme.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

