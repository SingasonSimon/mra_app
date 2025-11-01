import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../medication/providers/medication_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
import '../../../utils/navigation_helper.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Red Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                gradient: AppTheme.redGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(AppIcons.arrowLeft, color: AppTheme.white),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.alertCircle,
                          color: AppTheme.red600,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Emergency',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quick access & contacts',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Important Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.red900.withValues(alpha: 0.3) : AppTheme.red50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.red700 : AppTheme.red200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.alertCircle,
                            color: isDark ? AppTheme.red500 : AppTheme.red700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'In case of medical emergency, always call 911 or your local emergency number first.',
                              style: TextStyle(
                                color: isDark ? AppTheme.white : AppTheme.gray900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Emergency Services Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.redGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Services',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _makePhoneCall('911'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.white,
                                  foregroundColor: AppTheme.red600,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(AppIcons.phone, color: AppTheme.red600, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Call 911',
                                      style: TextStyle(
                                        color: AppTheme.red600,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Emergency Contacts Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.white : AppTheme.gray900,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement add contact
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add contact feature coming soon')),
                            );
                          },
                          icon: const Icon(AppIcons.plus, size: 18),
                          label: const Text('Add', style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: BorderSide(
                              color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                            ),
                            foregroundColor: isDark ? AppTheme.gray400 : AppTheme.gray700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Contact Cards
                    _EmergencyContactCard(
                      name: 'Dr. Sarah Johnson',
                      type: 'Primary Care',
                      phone: '+1 (555) 123-4567',
                      onCall: () => _makePhoneCall('+15551234567'),
                    ),
                    const SizedBox(height: 12),
                    _EmergencyContactCard(
                      name: 'Emily Doe',
                      type: 'Daughter',
                      phone: '+1 (555) 987-6543',
                      onCall: () => _makePhoneCall('+15559876543'),
                    ),
                    const SizedBox(height: 12),
                    _EmergencyContactCard(
                      name: 'City Hospital ER',
                      type: 'Emergency',
                      phone: '911',
                      onCall: () => _makePhoneCall('911'),
                    ),
                    const SizedBox(height: 24),
                    // Medication Summary
                    Text(
                      'Medication Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    medicationsAsync.when(
                      data: (medications) {
                        if (medications.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                              ),
                            ),
                            child: Text(
                              'No medications recorded',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.white.withValues(alpha: 0.6)
                                    : AppTheme.gray600,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: medications.take(5).map((med) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      AppIcons.pill,
                                      size: 16,
                                      color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppTheme.white : AppTheme.gray900,
                                            ),
                                          ),
                                          Text(
                                            '${med.dosage} - ${med.timesPerDay.length}x daily',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppTheme.white.withValues(alpha: 0.6)
                                                  : AppTheme.gray600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                            ),
                          ),
                          child: Text(
                            'Error loading medications',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.white.withValues(alpha: 0.6)
                                  : AppTheme.gray600,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 0), // Emergency from dashboard
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final String name;
  final String type;
  final String phone;
  final VoidCallback onCall;

  const _EmergencyContactCard({
    required this.name,
    required this.type,
    required this.phone,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.gray700 : AppTheme.gray200,
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.blue50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.user,
              color: AppTheme.blue600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.white : AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.white.withValues(alpha: 0.6)
                        : AppTheme.gray600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.white.withValues(alpha: 0.6)
                        : AppTheme.gray600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.teal500,
              foregroundColor: AppTheme.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Icon(AppIcons.phone, size: 20),
          ),
        ],
      ),
    );
  }
}

