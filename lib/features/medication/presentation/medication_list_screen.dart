import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/medication_providers.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../../app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimes(List timesPerDay) {
    if (timesPerDay.isEmpty) return 'No schedule';
    
    final formatted = timesPerDay.map((time) {
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final amPm = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $amPm';
    }).join(', ');
    
    return formatted;
  }

  String _getFrequency(int count) {
    if (count == 1) return 'Once daily';
    if (count == 2) return 'Twice daily';
    if (count == 3) return 'Three times daily';
    return '$count times daily';
  }

  String? _getSupplyDays(medication) {
    if (medication.refillDate != null) {
      final now = DateTime.now();
      final days = medication.refillDate!.difference(now).inDays;
      if (days >= 0) {
        return '$days days supply';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationsStreamProvider);
    
    // Filter active medications
    final activeMedications = medicationsAsync.maybeWhen(
      data: (meds) {
        final now = DateTime.now();
        final active = meds.where((med) {
          if (med.startDate.isAfter(now)) return false;
          if (med.endDate != null && med.endDate!.isBefore(now)) return false;
          return true;
        }).toList();
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          return active.where((med) {
            return med.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }
        
        return active;
      },
      orElse: () => <dynamic>[],
    );

    final activeCount = activeMedications.length;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          // Teal Header Section with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1F2937), Color(0xFF111827)],
                    )
                  : AppTheme.tealGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Back Button, Title, Add Button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(AppIcons.arrowLeft, color: AppTheme.white),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Expanded(
                        child: Text(
                          'My Medications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.plus, color: AppTheme.white),
                        onPressed: () => context.push('/medications/add'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$activeCount active medications',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: TextStyle(
                      color: isDark ? AppTheme.white : AppTheme.gray900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search medications...',
                      hintStyle: TextStyle(
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                      ),
                      prefixIcon: Icon(
                        AppIcons.search,
                        color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.white.withValues(alpha: 0.1)
                          : AppTheme.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: medicationsAsync.when(
              data: (medications) {
                if (activeMedications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            AppIcons.pill,
                            size: 64,
                            color: isDark ? AppTheme.gray400 : AppTheme.gray400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No medications added yet'
                                : 'No medications found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            Text(
                              'Tap the + button to add your first medication',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.white.withValues(alpha: 0.6)
                                    : AppTheme.gray600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...activeMedications.map((medication) => _MedicationCard(
                      medication: medication,
                      onEdit: () {
                        context.push('/medications/add', extra: medication);
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Medication'),
                            content: Text('Are you sure you want to delete ${medication.name}?'),
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
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          try {
                            final repository = ref.read(medicationRepositoryProvider);
                            await repository.deleteMedication(medication.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Medication deleted')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${e.toString()}')),
                              );
                            }
                          }
                        }
                      },
                      formatTimes: _formatTimes,
                      getFrequency: _getFrequency,
                      getSupplyDays: _getSupplyDays,
                    )).toList(),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        AppIcons.alertCircle,
                        size: 48,
                        color: AppTheme.red500,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading medications',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.white.withValues(alpha: 0.6)
                              : AppTheme.gray700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(List) formatTimes;
  final String Function(int) getFrequency;
  final String? Function(dynamic) getSupplyDays;

  const _MedicationCard({
    required this.medication,
    required this.onEdit,
    required this.onDelete,
    required this.formatTimes,
    required this.getFrequency,
    required this.getSupplyDays,
  });

  @override
  Widget build(BuildContext context) {
    final supplyDays = getSupplyDays(medication);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name and Active Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  medication.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.white : AppTheme.gray900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'active',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Dosage & Frequency
              Text(
                '${medication.dosage} - ${getFrequency(medication.timesPerDay.length)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.white.withValues(alpha: 0.6)
                      : AppTheme.gray700,
                ),
              ),
              const SizedBox(height: 8),
              // Schedule with clock icon
              Row(
                children: [
                  Icon(
                    AppIcons.clock,
                    size: 16,
                    color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatTimes(medication.timesPerDay),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.white.withValues(alpha: 0.6)
                          : AppTheme.gray700,
                    ),
                  ),
                ],
              ),
              if (supplyDays != null) ...[
                const SizedBox(height: 8),
                Text(
                  supplyDays,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppTheme.white.withValues(alpha: 0.6)
                        : AppTheme.gray700,
                  ),
                ),
              ],
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(AppIcons.edit, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.blue600,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(AppIcons.trash2),
                color: AppTheme.red500,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
