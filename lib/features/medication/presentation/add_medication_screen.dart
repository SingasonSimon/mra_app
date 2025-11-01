import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/medication.dart';
import '../../../core/services/refill_service.dart';
import '../providers/medication_providers.dart';
import '../../../di/providers.dart';
import '../../../features/logs/repository/logs_repository.dart';
import '../../../app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddMedicationScreen extends ConsumerStatefulWidget {
  final Medication? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  ConsumerState<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  final List<TimeOfDay> _selectedTimes = [];
  DateTime? _startDate;
  DateTime? _endDate;
  final _refillThresholdController = TextEditingController();
  DateTime? _refillDate;
  bool _manualRefillDate = false;
  String? _calculatedRefillDate;
  
  // New fields for wireframe design
  String _selectedUnit = 'mg';
  String _selectedFrequency = 'Once daily';
  bool _notificationsEnabled = true;
  bool _soundAlert = true;
  bool _refillReminder = true;
  File? _prescriptionImage;

  final List<String> _units = ['mg', 'ml', 'tablet', 'capsule', 'drop', 'unit'];
  final List<String> _frequencies = ['Once daily', 'Twice daily', 'Three times daily', 'Four times daily', 'As needed'];

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      final dosageParts = widget.medication!.dosage.split(' ');
      if (dosageParts.length >= 2) {
        _dosageController.text = dosageParts[0];
        _selectedUnit = dosageParts.sublist(1).join(' ');
      } else {
        _dosageController.text = widget.medication!.dosage;
      }
      _notesController.text = widget.medication!.notes ?? '';
      _selectedTimes.addAll(widget.medication!.timesPerDay);
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
      _refillThresholdController.text = widget.medication!.refillThreshold?.toString() ?? '';
      _refillDate = widget.medication!.refillDate;
      _manualRefillDate = widget.medication!.manualRefillDate;
      
      // Calculate duration
      if (_endDate != null && _startDate != null) {
        final days = _endDate!.difference(_startDate!).inDays;
        _durationController.text = days.toString();
      }
    } else {
      _startDate = DateTime.now();
      _durationController.text = '30';
    }
    
    // Set frequency based on timesPerDay count
    if (widget.medication != null && widget.medication!.timesPerDay.isNotEmpty) {
      final count = widget.medication!.timesPerDay.length;
      if (count == 1) _selectedFrequency = 'Once daily';
      else if (count == 2) _selectedFrequency = 'Twice daily';
      else if (count == 3) _selectedFrequency = 'Three times daily';
      else if (count >= 4) _selectedFrequency = 'Four times daily';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _refillThresholdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _calculateRefillDate() async {
    if (_selectedTimes.isEmpty || _startDate == null) return;
    
    final thresholdText = _refillThresholdController.text.trim();
    if (thresholdText.isEmpty) {
      setState(() => _calculatedRefillDate = null);
      return;
    }

    final threshold = int.tryParse(thresholdText);
    if (threshold == null || threshold <= 0) {
      setState(() => _calculatedRefillDate = null);
      return;
    }

    final tempMedication = Medication(
      id: widget.medication?.id ?? '',
      name: _nameController.text.trim(),
      dosage: '${_dosageController.text.trim()} $_selectedUnit',
      timesPerDay: _selectedTimes,
      frequency: 'daily',
      startDate: _startDate!,
      endDate: _endDate,
      refillThreshold: threshold,
    );

    try {
      final logsRepository = LogsRepository();
      final refillService = RefillService(logsRepository);
      final calculatedDate = await refillService.calculateRefillDate(tempMedication);
      
      if (calculatedDate != null && !_manualRefillDate) {
        setState(() {
          _refillDate = calculatedDate;
          _calculatedRefillDate = '${calculatedDate.day}/${calculatedDate.month}/${calculatedDate.year}';
        });
      }
    } catch (e) {
      debugPrint('Error calculating refill date: $e');
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null && !_selectedTimes.contains(time)) {
      setState(() {
        _selectedTimes.add(time);
        _selectedTimes.sort((a, b) {
          final aMinutes = a.hour * 60 + a.minute;
          final bMinutes = b.hour * 60 + b.minute;
          return aMinutes.compareTo(bMinutes);
        });
        // Update frequency based on count
        if (_selectedTimes.length == 1) _selectedFrequency = 'Once daily';
        else if (_selectedTimes.length == 2) _selectedFrequency = 'Twice daily';
        else if (_selectedTimes.length == 3) _selectedFrequency = 'Three times daily';
        else if (_selectedTimes.length >= 4) _selectedFrequency = 'Four times daily';
      });
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        // Update duration
        if (_startDate != null) {
          final days = date.difference(_startDate!).inDays;
          _durationController.text = days.toString();
        }
      });
    }
  }

  Future<void> _selectPrescriptionImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _prescriptionImage = File(image.path);
      });
    }
  }

  void _removeTime(TimeOfDay time) {
    setState(() {
      _selectedTimes.remove(time);
      // Update frequency based on count
      if (_selectedTimes.length == 1) _selectedFrequency = 'Once daily';
      else if (_selectedTimes.length == 2) _selectedFrequency = 'Twice daily';
      else if (_selectedTimes.length == 3) _selectedFrequency = 'Three times daily';
      else if (_selectedTimes.length >= 4) _selectedFrequency = 'Four times daily';
    });
  }

  String _getDisplayTime(TimeOfDay time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'AM' : 'PM';
    return '$hour:$minute $amPm';
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one dose time')),
      );
      return;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    try {
      final medication = Medication(
        id: widget.medication?.id ?? '',
        name: _nameController.text.trim(),
        dosage: '${_dosageController.text.trim()} $_selectedUnit',
        timesPerDay: _selectedTimes,
        frequency: _selectedFrequency.toLowerCase().replaceAll(' ', '_'),
        startDate: _startDate!,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        refillThreshold: _refillThresholdController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_refillThresholdController.text.trim()),
        refillDate: _refillDate,
        manualRefillDate: _manualRefillDate,
      );

      final repository = ref.read(medicationRepositoryProvider);
      final notificationsService = ref.read(notificationsServiceProvider);
      final logsRepository = LogsRepository();
      final refillService = RefillService(logsRepository);

      Medication finalMedication = medication;
      if (!_manualRefillDate && medication.refillThreshold != null) {
        final calculatedDate = await refillService.calculateRefillDate(medication);
        finalMedication = Medication(
          id: medication.id,
          name: medication.name,
          dosage: medication.dosage,
          timesPerDay: medication.timesPerDay,
          frequency: medication.frequency,
          startDate: medication.startDate,
          endDate: medication.endDate,
          notes: medication.notes,
          refillThreshold: medication.refillThreshold,
          refillDate: calculatedDate,
          manualRefillDate: false,
        );
      }

      String medicationId;
      if (widget.medication != null) {
        medicationId = widget.medication!.id;
        await repository.updateMedication(medicationId, finalMedication);
        await notificationsService.cancelRefillReminder(medicationId.hashCode);
      } else {
        medicationId = await repository.addMedication(finalMedication);
      }

      // Schedule notifications if enabled
      if (_notificationsEnabled) {
        for (int i = 0; i < _selectedTimes.length; i++) {
          await notificationsService.scheduleRecurringReminder(
            baseId: medicationId.hashCode + i,
            title: 'Medication Reminder',
            body: 'Time to take ${finalMedication.name} (${finalMedication.dosage})',
            time: _selectedTimes[i],
            medicationId: medicationId,
          );
        }
      }

      if (_refillReminder && finalMedication.refillDate != null) {
        await notificationsService.scheduleRefillReminder(
          id: medicationId.hashCode + 10000,
          medication: finalMedication,
        );
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.medication != null
                ? 'Medication updated'
                : 'Medication added'),
          ),
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

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1F2937), Color(0xFF111827)],
                      )
                    : AppTheme.tealGradient,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.arrowLeft, color: AppTheme.white),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Text(
                      'Add Medication',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance spacing
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Medication Name
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Medication Name*',
                        hintText: 'e.g., Metformin',
                        hintStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                          fontSize: 14,
                        ),
                        labelStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          AppIcons.pill,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.white.withValues(alpha: 0.1)
                            : AppTheme.gray100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medication name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Dosage and Unit Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _dosageController,
                            style: TextStyle(
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Dosage*',
                              hintText: 'e.g., 500',
                              hintStyle: TextStyle(
                                color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                fontSize: 14,
                              ),
                              labelStyle: TextStyle(
                                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppTheme.white.withValues(alpha: 0.1)
                                  : AppTheme.gray100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              labelStyle: TextStyle(
                                color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppTheme.white.withValues(alpha: 0.1)
                                  : AppTheme.gray100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            dropdownColor: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                            style: TextStyle(
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                              fontSize: 15,
                            ),
                            items: _units.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark ? AppTheme.white : AppTheme.gray900,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedUnit = value ?? 'mg');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Frequency Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedFrequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency*',
                        hintText: 'Select frequency',
                        hintStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                          fontSize: 14,
                        ),
                        labelStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.repeat_rounded,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.white.withValues(alpha: 0.1)
                            : AppTheme.gray100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1F2937) : AppTheme.white,
                      style: TextStyle(
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                        fontSize: 15,
                      ),
                      items: _frequencies.map((freq) {
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(
                            freq,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? AppTheme.white : AppTheme.gray900,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedFrequency = value ?? 'Once daily');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select frequency';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Time Field
                    InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.white.withValues(alpha: 0.1)
                              : AppTheme.gray100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.clock,
                              color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time*',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedTimes.isEmpty
                                        ? 'Tap to add time'
                                        : _selectedTimes.map((t) => _getDisplayTime(t)).join(', '),
                                    style: TextStyle(
                                      color: _selectedTimes.isEmpty
                                          ? (isDark ? AppTheme.gray400 : AppTheme.gray500)
                                          : (isDark ? AppTheme.white : AppTheme.gray900),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedTimes.isNotEmpty)
                              IconButton(
                                icon: Icon(
                                  AppIcons.x,
                                  size: 20,
                                  color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                ),
                                onPressed: () {
                                  setState(() => _selectedTimes.clear());
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Duration (days)
                    TextFormField(
                      controller: _durationController,
                      style: TextStyle(
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Duration (days)',
                        hintText: 'e.g., 30',
                        hintStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                          fontSize: 14,
                        ),
                        labelStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          AppIcons.calendar,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.white.withValues(alpha: 0.1)
                            : AppTheme.gray100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final days = int.tryParse(value);
                        if (days != null && _startDate != null) {
                          setState(() {
                            _endDate = _startDate!.add(Duration(days: days));
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      style: TextStyle(
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        hintText: 'Take with food, avoid dairy...',
                        hintStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                          fontSize: 14,
                        ),
                        labelStyle: TextStyle(
                          color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          AppIcons.edit,
                          color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.white.withValues(alpha: 0.1)
                            : AppTheme.gray100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    // Upload Prescription Photo
                    Text(
                      'Upload Prescription Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectPrescriptionImage,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.white.withValues(alpha: 0.1)
                              : AppTheme.gray50,
                          border: Border.all(
                            color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _prescriptionImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _prescriptionImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(AppIcons.x, color: AppTheme.white),
                                      onPressed: () {
                                        setState(() => _prescriptionImage = null);
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    AppIcons.plus,
                                    size: 32,
                                    color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Take or Upload Photo',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.white.withValues(alpha: 0.6)
                                          : AppTheme.gray600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Notification Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.white : AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Receive reminders for this medication',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.white.withValues(alpha: 0.6)
                                    : AppTheme.gray600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                          },
                        ),
                      ],
                    ),
                    if (_notificationsEnabled) ...[
                      const SizedBox(height: 16),
                      _NotificationToggleItem(
                        title: 'Sound Alert',
                        subtitle: 'Play sound with notification',
                        value: _soundAlert,
                        onChanged: (value) {
                          setState(() => _soundAlert = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _NotificationToggleItem(
                      title: 'Refill Reminder',
                      subtitle: 'Remind when supply is low',
                      value: _refillReminder,
                      onChanged: (value) {
                        setState(() => _refillReminder = value);
                      },
                    ),
                    const SizedBox(height: 32),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.teal500,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Save Medication',
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
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggleItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.white : AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.white.withValues(alpha: 0.6)
                      : AppTheme.gray600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
