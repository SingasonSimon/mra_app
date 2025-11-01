import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MedicalHistoryScreen extends ConsumerWidget {
  const MedicalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  profileAsync.when(
                    data: (profile) {
                      if (profile == null) {
                        return const Text('No profile information available');
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
                    error: (_, __) => const Text('Error loading profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                  const SizedBox(height: 16),
                  profileAsync.when(
                    data: (profile) {
                      if (profile == null || profile.conditions.isEmpty) {
                        return Text(
                          'No conditions recorded',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
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
                    error: (_, __) => const Text('Error loading conditions'),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

