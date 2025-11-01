import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../medication/providers/medication_providers.dart';
import '../providers/emergency_contacts_providers.dart';
import '../../../core/models/emergency_contact.dart';
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

  String _sanitizeDialNumber(String input) {
    return input.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  Future<void> _showContactForm(
    BuildContext context,
    WidgetRef ref, {
    EmergencyContact? contact,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetContext) {
        return _ContactFormWidget(
          contact: contact,
          ref: ref,
          onComplete: () {
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EmergencyContact contact,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete contact'),
          content: Text('Remove ${contact.name} from your emergency contacts?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.red600),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await ref
            .read(emergencyContactsRepositoryProvider)
            .deleteContact(contact.id);
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Emergency contact deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Unable to delete contact: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationsStreamProvider);
    final contactsAsync = ref.watch(emergencyContactsStreamProvider);
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
              decoration: BoxDecoration(gradient: AppTheme.redGradient),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          AppIcons.arrowLeft,
                          color: AppTheme.white,
                        ),
                        onPressed: () => context.safePop(),
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
                        color: isDark
                            ? AppTheme.red900.withValues(alpha: 0.3)
                            : AppTheme.red50,
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
                                color: isDark
                                    ? AppTheme.white
                                    : AppTheme.gray900,
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      AppIcons.phone,
                                      color: AppTheme.red600,
                                      size: 24,
                                    ),
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
                          onPressed: () => _showContactForm(context, ref),
                          icon: const Icon(AppIcons.plus, size: 18),
                          label: const Text(
                            'Add',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? AppTheme.gray700
                                  : AppTheme.gray200,
                            ),
                            foregroundColor: isDark
                                ? AppTheme.gray400
                                : AppTheme.gray700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    contactsAsync.when(
                      data: (contacts) {
                        if (contacts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : AppTheme.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.gray700
                                    : AppTheme.gray200,
                              ),
                            ),
                            child: Text(
                              'No emergency contacts added yet',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.white.withValues(alpha: 0.6)
                                    : AppTheme.gray600,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: contacts.map((contact) {
                            final dialNumber = _sanitizeDialNumber(
                              contact.phone,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _EmergencyContactCard(
                                name: contact.name,
                                type: contact.relationship,
                                phone: contact.phone,
                                notes: contact.notes,
                                onCall: () => _makePhoneCall(dialNumber),
                                onEdit: () => _showContactForm(
                                  context,
                                  ref,
                                  contact: contact,
                                ),
                                onDelete: () =>
                                    _confirmDelete(context, ref, contact),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) {
                        debugPrint('Emergency contacts error: $error');
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.gray700
                                  : AppTheme.gray200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unable to load emergency contacts',
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.white.withValues(alpha: 0.6)
                                      : AppTheme.gray600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error: ${error.toString()}',
                                style: const TextStyle(
                                  color: AppTheme.red500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  ref.invalidate(
                                    emergencyContactsStreamProvider,
                                  );
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
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
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : AppTheme.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.gray700
                                    : AppTheme.gray200,
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
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.gray700
                                  : AppTheme.gray200,
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
                                      color: isDark
                                          ? AppTheme.gray400
                                          : AppTheme.gray500,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppTheme.white
                                                  : AppTheme.gray900,
                                            ),
                                          ),
                                          Text(
                                            '${med.dosage} - ${med.timesPerDay.length}x daily',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppTheme.white.withValues(
                                                      alpha: 0.6,
                                                    )
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1F2937)
                                : AppTheme.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.gray700
                                  : AppTheme.gray200,
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
      bottomNavigationBar: const BottomNavigation(currentIndex: 0),
    );
  }
}

// === _ContactFormWidget ===

class _ContactFormWidget extends ConsumerStatefulWidget {
  final EmergencyContact? contact;
  final WidgetRef ref;
  final VoidCallback onComplete;

  const _ContactFormWidget({
    required this.contact,
    required this.ref,
    required this.onComplete,
  });

  @override
  ConsumerState<_ContactFormWidget> createState() => _ContactFormWidgetState();
}

class _ContactFormWidgetState extends ConsumerState<_ContactFormWidget> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController relationshipController;
  late final TextEditingController phoneController;
  late final TextEditingController notesController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.contact?.name ?? '');
    relationshipController = TextEditingController(
      text: widget.contact?.relationship ?? '',
    );
    phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    notesController = TextEditingController(text: widget.contact?.notes ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    relationshipController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (isSaving || !formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => isSaving = true);
    FocusScope.of(context).unfocus();

    final repository = widget.ref.read(emergencyContactsRepositoryProvider);
    final name = nameController.text.trim();
    final relationship = relationshipController.text.trim();
    final phone = phoneController.text.trim();
    final notes = notesController.text.trim().isEmpty
        ? null
        : notesController.text.trim();

    try {
      if (widget.contact == null) {
        await repository.addContact(
          EmergencyContact(
            id: '',
            name: name,
            relationship: relationship,
            phone: phone,
            notes: notes,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency contact added'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onComplete();
        }
      } else {
        await repository.updateContact(
          widget.contact!.id,
          widget.contact!.copyWith(
            name: name,
            relationship: relationship,
            phone: phone,
            notes: notes,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency contact updated'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to save contact: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.contact == null ? 'Add Contact' : 'Edit Contact',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: widget.onComplete,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveContact,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === _EmergencyContactCard ===

class _EmergencyContactCard extends StatelessWidget {
  final String name;
  final String type;
  final String phone;
  final String? notes;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmergencyContactCard({
    required this.name,
    required this.type,
    required this.phone,
    this.notes,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
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
        border: Border.all(color: isDark ? AppTheme.gray700 : AppTheme.gray200),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.red100,
            radius: 24,
            child: Icon(AppIcons.user, color: AppTheme.red600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? AppTheme.white : AppTheme.gray900,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.white.withValues(alpha: 0.6)
                        : AppTheme.gray600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    color: isDark ? AppTheme.gray400 : AppTheme.gray700,
                    fontSize: 13,
                  ),
                ),
                if (notes != null && notes!.isNotEmpty)
                  Text(
                    notes!,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.white.withValues(alpha: 0.6)
                          : AppTheme.gray600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onCall,
                icon: const Icon(AppIcons.phone, color: AppTheme.teal500),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(AppIcons.edit, color: AppTheme.blue500),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(AppIcons.trash2, color: AppTheme.red500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
