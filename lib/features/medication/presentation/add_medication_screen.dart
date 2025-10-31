import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/medication.dart';
import '../providers/medication_providers.dart';
import '../../../di/providers.dart';

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
  final List<TimeOfDay> _selectedTimes = [];
  DateTime? _startDate;
  DateTime? _endDate;
  int? _refillThreshold;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage;
      _notesController.text = widget.medication!.notes ?? '';
      _selectedTimes.addAll(widget.medication!.timesPerDay);
      _startDate = widget.medication!.startDate;
      _endDate = widget.medication!.endDate;
      _refillThreshold = widget.medication!.refillThreshold;
    } else {
      _startDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
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
      setState(() => _endDate = date);
    }
  }

  void _removeTime(TimeOfDay time) {
    setState(() => _selectedTimes.remove(time));
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
        dosage: _dosageController.text.trim(),
        timesPerDay: _selectedTimes,
        frequency: 'daily',
        startDate: _startDate!,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        refillThreshold: _refillThreshold,
      );

      final repository = ref.read(medicationRepositoryProvider);
      final notificationsService = ref.read(notificationsServiceProvider);

      if (widget.medication != null) {
        await repository.updateMedication(widget.medication!.id, medication);
      } else {
        final id = await repository.addMedication(medication);
        // Schedule notifications for each time
        for (int i = 0; i < _selectedTimes.length; i++) {
          await notificationsService.scheduleRecurringReminder(
            baseId: id.hashCode + i,
            title: 'Medication Reminder',
            body: 'Time to take ${medication.name} (${medication.dosage})',
            time: _selectedTimes[i],
          );
        }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication != null ? 'Edit Medication' : 'Add Medication'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                prefixIcon: Icon(Icons.medication),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 1 tablet, 5ml)',
                prefixIcon: Icon(Icons.science),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Dose Times',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedTimes.map((time) {
                  return Chip(
                    label: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
                    onDeleted: () => _removeTime(time),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Add Time'),
                  onPressed: _selectTime,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(_startDate != null
                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                  : 'Not selected'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectStartDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('End Date (Optional)'),
              subtitle: Text(_endDate != null
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : 'No end date'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectEndDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Save Medication'),
            ),
          ],
        ),
      ),
    );
  }
}

