import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/medication.dart';
import '../../../core/services/refill_service.dart';
import '../providers/medication_providers.dart';
import '../../../di/providers.dart';
import '../../../features/logs/repository/logs_repository.dart';
import '../../../app/theme/app_theme.dart';
import '../../../utils/navigation_helper.dart';
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
  String? _existingPrescriptionImageUrl; // URL from existing medication when editing

  final List<String> _units = ['mg', 'ml', 'tablet', 'capsule', 'drop', 'unit'];
  final List<String> _frequencies = ['Once daily', 'Twice daily', 'Three times daily', 'Four times daily', 'As needed'];
  bool _isSaving = false;

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
      
      // Store existing prescription image URL for display
      _existingPrescriptionImageUrl = widget.medication!.prescriptionImageUrl;
      
      // Load prescription image URL if exists
      if (widget.medication!.prescriptionImageUrl != null && widget.medication!.prescriptionImageUrl!.isNotEmpty) {
        // Note: We can't load the image directly into File, but we can store the URL
        // The image will be loaded later when displaying
      }
      
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
      
      // Recalculate refill date when times change (if not manual)
      if (!_manualRefillDate) {
        _calculateRefillDate();
      }
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
    
    // Recalculate refill date when times change (if not manual)
    if (!_manualRefillDate) {
      _calculateRefillDate();
    }
  }

  String _getDisplayTime(TimeOfDay time) {
    // Use MaterialLocalizations to respect device's 12/24-hour format preference
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat);
  }

  Future<void> _saveMedication() async {
    if (_isSaving) return;
    
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
    if (_manualRefillDate && _refillDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a refill date or disable manual mode')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(medicationRepositoryProvider);
      final notificationsService = ref.read(notificationsServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      final logsRepository = LogsRepository();
      final refillService = RefillService(logsRepository);

      // Preserve existing image URL if editing and no new image selected and not removed
      String? initialPrescriptionImageUrl;
      if (widget.medication != null && _prescriptionImage == null && _existingPrescriptionImageUrl != null) {
        initialPrescriptionImageUrl = _existingPrescriptionImageUrl;
      } else if (_prescriptionImage == null && _existingPrescriptionImageUrl == null) {
        // User explicitly removed the image
        initialPrescriptionImageUrl = null;
      }

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
        prescriptionImageUrl: initialPrescriptionImageUrl,
      );

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
          prescriptionImageUrl: medication.prescriptionImageUrl,
        );
      }

      String medicationId;
      String? oldImageUrl;
      
      // If editing, get the old image URL for potential deletion and cancel old notifications
      if (widget.medication != null) {
        medicationId = widget.medication!.id;
        oldImageUrl = widget.medication!.prescriptionImageUrl;
        await repository.updateMedication(medicationId, finalMedication);
        
        // Cancel all old notifications for this medication
        // Cancel dose reminders (one for each scheduled time)
        for (int i = 0; i < widget.medication!.timesPerDay.length; i++) {
          await notificationsService.cancelReminder(medicationId.hashCode + i);
          // Also cancel recurring notifications
          await notificationsService.cancelReminder(medicationId.hashCode + i + 100000);
        }
        // Cancel refill reminder
        await notificationsService.cancelRefillReminder(medicationId.hashCode + 10000);
      } else {
        medicationId = await repository.addMedication(finalMedication);
      }

      // Handle prescription image upload after medication is saved (so we have the ID)
      if (_prescriptionImage != null) {
        try {
          // Upload the image
          final prescriptionImageUrl = await storageService.uploadPrescriptionImage(
            imageFile: _prescriptionImage!,
            medicationId: medicationId,
          );

          // Update medication with image URL
          final updatedMedication = Medication(
            id: finalMedication.id,
            name: finalMedication.name,
            dosage: finalMedication.dosage,
            timesPerDay: finalMedication.timesPerDay,
            frequency: finalMedication.frequency,
            startDate: finalMedication.startDate,
            endDate: finalMedication.endDate,
            notes: finalMedication.notes,
            refillThreshold: finalMedication.refillThreshold,
            refillDate: finalMedication.refillDate,
            manualRefillDate: finalMedication.manualRefillDate,
            prescriptionImageUrl: prescriptionImageUrl,
          );
          
          await repository.updateMedication(medicationId, updatedMedication);

          // If editing and old image exists, delete it
          if (oldImageUrl != null && oldImageUrl.isNotEmpty && oldImageUrl != prescriptionImageUrl) {
            try {
              await storageService.deletePrescriptionImage(oldImageUrl);
            } catch (e) {
              // Non-critical error, continue
              debugPrint('Failed to delete old prescription image: $e');
            }
          }
          
          // Clear existing image URL since we have a new one
          setState(() {
            _existingPrescriptionImageUrl = null;
          });
        } catch (e) {
          // Image upload failed, but medication is already saved
          debugPrint('Failed to upload prescription image: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Medication saved but image upload failed: ${e.toString()}'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }

      // Schedule notifications if enabled (errors are handled internally)
      if (_notificationsEnabled) {
        try {
          for (int i = 0; i < _selectedTimes.length; i++) {
            await notificationsService.scheduleRecurringReminder(
              baseId: medicationId.hashCode + i,
              title: 'Medication Reminder',
              body: 'Time to take ${finalMedication.name} (${finalMedication.dosage})',
              time: _selectedTimes[i],
              medicationId: medicationId,
              playSound: _soundAlert,
            );
          }
        } catch (e) {
          debugPrint('Error scheduling medication reminders: $e');
          // Don't show error to user - medication was saved successfully
        }
      }

      if (_refillReminder && finalMedication.refillDate != null) {
        try {
          await notificationsService.scheduleRefillReminder(
            id: medicationId.hashCode + 10000,
            medication: finalMedication,
          );
        } catch (e) {
          debugPrint('Error scheduling refill reminder: $e');
          // Don't show error to user - medication was saved successfully
        }
      }

      if (mounted) {
        context.safePop();
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
                    onPressed: () => context.safePop(),
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
                        if (value == null) return;
                        
                        setState(() {
                          _selectedFrequency = value;
                          
                          // Auto-populate times based on frequency (if times are empty or user wants to reset)
                          if (value != 'As needed') {
                            // Suggest common times based on frequency
                            final suggestedTimes = <TimeOfDay>[];
                            
                            if (value == 'Once daily') {
                              suggestedTimes.add(const TimeOfDay(hour: 9, minute: 0)); // 9:00 AM
                            } else if (value == 'Twice daily') {
                              suggestedTimes.add(const TimeOfDay(hour: 9, minute: 0)); // 9:00 AM
                              suggestedTimes.add(const TimeOfDay(hour: 21, minute: 0)); // 9:00 PM
                            } else if (value == 'Three times daily') {
                              suggestedTimes.add(const TimeOfDay(hour: 8, minute: 0)); // 8:00 AM
                              suggestedTimes.add(const TimeOfDay(hour: 14, minute: 0)); // 2:00 PM
                              suggestedTimes.add(const TimeOfDay(hour: 20, minute: 0)); // 8:00 PM
                            } else if (value == 'Four times daily') {
                              suggestedTimes.add(const TimeOfDay(hour: 8, minute: 0)); // 8:00 AM
                              suggestedTimes.add(const TimeOfDay(hour: 12, minute: 0)); // 12:00 PM
                              suggestedTimes.add(const TimeOfDay(hour: 16, minute: 0)); // 4:00 PM
                              suggestedTimes.add(const TimeOfDay(hour: 20, minute: 0)); // 8:00 PM
                            }
                            
                            // Only auto-populate if no times are set yet
                            if (_selectedTimes.isEmpty) {
                              _selectedTimes.addAll(suggestedTimes);
                            } else {
                              // Update frequency label only, keep existing times
                              // The frequency display will reflect the actual count
                            }
                          } else {
                            // "As needed" - clear times but allow manual selection
                            // Don't auto-clear, let user manage manually
                          }
                        });
                        
                        // Recalculate refill date when frequency changes (if not manual)
                        if (!_manualRefillDate) {
                          _calculateRefillDate();
                        }
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
                    // Refill Settings
                    Text(
                      'Refill Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Refill Threshold
                    TextFormField(
                      controller: _refillThresholdController,
                      style: TextStyle(
                        color: isDark ? AppTheme.white : AppTheme.gray900,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Refill Threshold (number of doses)',
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
                          Icons.inventory_2_rounded,
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
                        // Recalculate refill date when threshold changes
                        if (!_manualRefillDate) {
                          _calculateRefillDate();
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Manual Refill Date Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manual Refill Date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.white : AppTheme.gray900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Override calculated refill date',
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
                          value: _manualRefillDate,
                          onChanged: (value) {
                            setState(() {
                              _manualRefillDate = value;
                              if (!value) {
                                // When disabling manual, recalculate
                                _calculateRefillDate();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    if (_manualRefillDate) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _refillDate ?? DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            setState(() {
                              _refillDate = date;
                            });
                          }
                        },
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
                                AppIcons.calendar,
                                color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Refill Date*',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.gray400 : AppTheme.gray600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _refillDate != null
                                          ? '${_refillDate!.day}/${_refillDate!.month}/${_refillDate!.year}'
                                          : 'Select refill date',
                                      style: TextStyle(
                                        color: _refillDate != null
                                            ? (isDark ? AppTheme.white : AppTheme.gray900)
                                            : (isDark ? AppTheme.gray400 : AppTheme.gray500),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_calculatedRefillDate != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.teal50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.teal600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Calculated refill date: $_calculatedRefillDate',
                                style: TextStyle(
                                  color: AppTheme.teal700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                            : _existingPrescriptionImageUrl != null && _existingPrescriptionImageUrl!.isNotEmpty
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          _existingPrescriptionImageUrl!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 120,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 120,
                                              color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                                              child: Center(
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: isDark ? AppTheme.gray400 : AppTheme.gray500,
                                                ),
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              height: 120,
                                              color: isDark ? AppTheme.gray700 : AppTheme.gray200,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          icon: const Icon(AppIcons.x, color: AppTheme.white),
                                          onPressed: () {
                                            setState(() {
                                              _existingPrescriptionImageUrl = null;
                                              _prescriptionImage = null;
                                            });
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
                        onPressed: _isSaving ? null : _saveMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.teal500,
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: AppTheme.teal500.withValues(alpha: 0.6),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
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
