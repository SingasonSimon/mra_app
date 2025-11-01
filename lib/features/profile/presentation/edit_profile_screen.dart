import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/models/user_profile.dart';
import '../../../app/theme/app_theme.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  String? _selectedGender;
  final List<String> _conditions = [];
  bool _isLoading = false;

  final List<String> _availableConditions = [
    'Diabetes',
    'Hypertension',
    'High Blood Pressure',
    'Asthma',
    'Arthritis',
    'Heart Disease',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profileAsync = ref.read(userProfileProvider);
    profileAsync.whenData((profile) {
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile.name;
          _ageController.text = profile.age?.toString() ?? '';
          _emergencyContactController.text = profile.emergencyContact ?? '';
          _selectedGender = profile.gender;
          _conditions.clear();
          _conditions.addAll(profile.conditions);
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final repository = ref.read(authRepositoryProvider);
      final profile = UserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        age: _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        gender: _selectedGender,
        conditions: _conditions,
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
      );

      await repository.updateUserProfile(user.uid, profile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleCondition(String condition) {
    setState(() {
      if (_conditions.contains(condition)) {
        _conditions.remove(condition);
      } else {
        _conditions.add(condition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Full Name
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Full Name*',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(Icons.person, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Age
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Age (Optional)',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(Icons.cake, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Gender (Optional)',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(Icons.people, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
                DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
              ],
              onChanged: (value) {
                setState(() => _selectedGender = value);
              },
            ),
            const SizedBox(height: 16),
            // Emergency Contact
            TextFormField(
              controller: _emergencyContactController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Emergency Contact (Optional)',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            // Medical Conditions
            const Text(
              'Medical Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableConditions.map((condition) {
                final isSelected = _conditions.contains(condition);
                return FilterChip(
                  label: Text(condition),
                  selected: isSelected,
                  onSelected: (_) => _toggleCondition(condition),
                  selectedColor: condition.toLowerCase().contains('diabetes')
                      ? Colors.green[100]
                      : Colors.blue[100],
                  checkmarkColor: condition.toLowerCase().contains('diabetes')
                      ? Colors.green[700]
                      : Colors.blue[700],
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

