import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/appointment.dart';
import '../providers/appointment_providers.dart';
import '../../../di/providers.dart';
import '../../../utils/navigation_helper.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {
  final Appointment? appointment;

  const AddAppointmentScreen({super.key, this.appointment});

  @override
  ConsumerState<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _reminderEnabled = true;
  int _reminderMinutesBefore = 30;
  bool _isRecurring = false;
  String? _recurrencePattern;

  final List<int> _reminderOptions = [15, 30, 60, 120, 1440]; // 15min, 30min, 1hr, 2hr, 24hr
  final List<String> _recurrenceOptions = ['daily', 'weekly', 'monthly'];

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      final apt = widget.appointment!;
      _doctorNameController.text = apt.doctorName;
      _reasonController.text = apt.reason;
      _locationController.text = apt.location ?? '';
      _phoneController.text = apt.phone ?? '';
      _notesController.text = apt.notes ?? '';
      _selectedDate = apt.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(apt.dateTime);
      _reminderEnabled = apt.reminderEnabled;
      _reminderMinutesBefore = apt.reminderMinutesBefore;
      _isRecurring = apt.isRecurring;
      _recurrencePattern = apt.recurrencePattern;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _reasonController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    try {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final appointment = Appointment(
        id: widget.appointment?.id ?? '',
        doctorName: _doctorNameController.text.trim(),
        dateTime: dateTime,
        reason: _reasonController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        reminderEnabled: _reminderEnabled,
        reminderMinutesBefore: _reminderMinutesBefore,
        isRecurring: _isRecurring,
        recurrencePattern: _isRecurring ? (_recurrencePattern ?? 'weekly') : null,
        createdAt: widget.appointment?.createdAt,
      );

      final repository = ref.read(appointmentRepositoryProvider);
      final notificationsService = ref.read(notificationsServiceProvider);

      if (widget.appointment != null) {
        await repository.updateAppointment(widget.appointment!.id, appointment);
        // Cancel old reminder and schedule new one
        await notificationsService.cancelReminder(widget.appointment!.id.hashCode);
      } else {
        final id = await repository.addAppointment(appointment);
        // Schedule reminder if enabled
        if (appointment.reminderEnabled) {
          await notificationsService.scheduleAppointmentReminder(
            id: id.hashCode,
            appointment: appointment,
          );
        }
      }

      // Schedule reminder for existing appointment updates
      if (widget.appointment != null && appointment.reminderEnabled) {
        await notificationsService.scheduleAppointmentReminder(
          id: widget.appointment!.id.hashCode,
          appointment: appointment,
        );
      }

      if (mounted) {
        context.safePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.appointment != null
                ? 'Appointment updated'
                : 'Appointment added'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.safePop(),
        ),
        title: Text(widget.appointment != null ? 'Edit Appointment' : 'Add Appointment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter doctor name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason/Type *',
                prefixIcon: Icon(Icons.info_outline),
                hintText: 'e.g., General Checkup, Follow-up',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter reason';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date *'),
                    subtitle: Text(_selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Not selected'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time *'),
                    subtitle: Text(_selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : 'Not selected'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (Optional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            SwitchListTile(
              title: const Text('Enable Reminder'),
              subtitle: const Text('Get notified before appointment'),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              Text(
                'Remind me before:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _reminderOptions.map((minutes) {
                  final hours = minutes ~/ 60;
                  final displayText = minutes < 60
                      ? '$minutes min'
                      : hours == 1
                          ? '1 hour'
                          : hours == 24
                              ? '24 hours'
                              : '$hours hours';
                  return ChoiceChip(
                    label: Text(displayText),
                    selected: _reminderMinutesBefore == minutes,
                    onSelected: (selected) {
                      if (selected) setState(() => _reminderMinutesBefore = minutes);
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Recurring Appointment'),
              subtitle: const Text('Repeat this appointment'),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              Text(
                'Repeat:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recurrenceOptions.map((pattern) {
                  return ChoiceChip(
                    label: Text(pattern.toUpperCase()),
                    selected: _recurrencePattern == pattern,
                    onSelected: (selected) {
                      if (selected) setState(() => _recurrencePattern = pattern);
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveAppointment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Save Appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

