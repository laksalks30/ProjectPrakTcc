// ============ FILE: mobile_app/lib/screens/reminders_screen.dart ============
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../models/reminder.dart';
import '../services/patient_service.dart';
import '../services/prescription_service.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_card.dart';
import '../utils/helpers.dart';

const List<String> _allDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final PatientService _patientService = PatientService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final ReminderService _reminderService = ReminderService();

  List<Patient> _patients = [];
  List<Prescription> _prescriptions = [];
  List<Reminder> _reminders = [];
  Patient? _selectedPatient;
  bool _loading = true;
  bool _showForm = false;

  // Form state
  int? _formPrescriptionId;
  List<String> _formTimes = ['08:00'];
  List<String> _formDays = List.from(_allDays);
  String _formNotes = '';
  bool _formLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      _patients = await _patientService.getAll();
      if (_patients.isNotEmpty && _selectedPatient == null) {
        _selectPatient(_patients.first);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selectPatient(Patient patient) async {
    setState(() {
      _selectedPatient = patient;
      _loading = true;
    });
    try {
      _reminders = await _reminderService.getByPatient(patient.id);
      _prescriptions = await _prescriptionService.getByPatient(patient.id, status: 'active');
      await _syncSchedulesForActive();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _syncSchedulesForActive() async {
    if (_selectedPatient == null) return;
    for (final reminder in _reminders) {
      if (!reminder.isActive) continue;
      await _scheduleReminder(reminder);
    }
  }

  Future<void> _scheduleReminder(Reminder reminder) async {
    final patientName = _selectedPatient?.name ?? reminder.patientName ?? 'Pasien';
    final medicationName = reminder.medicationName ?? 'Obat';
    for (final day in reminder.daysOfWeek) {
      await NotificationService.scheduleWeeklyReminder(
        reminderId: reminder.id,
        dayKey: day,
        time: reminder.timeShort,
        patientName: patientName,
        medicationName: medicationName,
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedPatient == null || _formPrescriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pasien dan resep terlebih dahulu'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (_formDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 hari'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _formLoading = true);

    try {
      final rx = _prescriptions.firstWhere((p) => p.id == _formPrescriptionId);

      for (final time in _formTimes) {
        final created = await _reminderService.create({
          'patient_id': _selectedPatient!.id,
          'prescription_id': _formPrescriptionId,
          'scheduled_time': time,
          'days_of_week': _formDays,
          'notes': _formNotes,
        });

        for (final day in _formDays) {
          await NotificationService.scheduleWeeklyReminder(
            reminderId: created.id,
            dayKey: day,
            time: time,
            patientName: _selectedPatient!.name,
            medicationName: rx.medicationName ?? 'Obat',
            dosage: rx.dosage,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Reminder berhasil dibuat!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {
          _showForm = false;
          _formPrescriptionId = null;
          _formTimes = ['08:00'];
          _formDays = List.from(_allDays);
          _formNotes = '';
        });
        _selectPatient(_selectedPatient!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _formLoading = false);
  }

  Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Reminder?'),
        content: const Text('Reminder ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _reminderService.delete(id);
      final deleted = _reminders.firstWhere((r) => r.id == id, orElse: () => _reminders.first);
      await NotificationService.cancelReminderSchedules(
        reminderId: id,
        days: deleted.daysOfWeek,
        time: deleted.timeShort,
      );
      setState(() => _reminders.removeWhere((r) => r.id == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder dihapus'), backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {}
  }

  Future<void> _handleToggle(int id, bool isActive) async {
    try {
      await _reminderService.update(id, {'is_active': isActive});
      setState(() {
        final idx = _reminders.indexWhere((r) => r.id == id);
        if (idx != -1) {
          final old = _reminders[idx];
          _reminders[idx] = Reminder(
            id: old.id,
            prescriptionId: old.prescriptionId,
            patientId: old.patientId,
            scheduledTime: old.scheduledTime,
            daysOfWeek: old.daysOfWeek,
            isActive: isActive,
            notes: old.notes,
            medicationName: old.medicationName,
            patientName: old.patientName,
          );
        }
      });
      final updated = _reminders.firstWhere((r) => r.id == id, orElse: () => _reminders.first);
      if (isActive) {
        await _scheduleReminder(updated);
      } else {
        await NotificationService.cancelReminderSchedules(
          reminderId: updated.id,
          days: updated.daysOfWeek,
          time: updated.timeShort,
        );
      }
    } catch (_) {}
  }

  Future<void> _testNotification() async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    await NotificationService.showNotification(
      id: id,
      title: 'Tes Notifikasi',
      body: 'Jika ini muncul, izin notifikasi OK.',
    );
  }

  Future<void> _testScheduledNotification() async {
    final id = DateTime.now().millisecondsSinceEpoch % 100000;
    await NotificationService.scheduleInMinutes(
      id: id,
      minutes: 1,
      title: 'Tes Jadwal 1 Menit',
      body: 'Notifikasi terjadwal harus muncul dalam 1 menit.',
    );
    final count = await NotificationService.pendingCount();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jadwal dibuat. Pending: $count'), backgroundColor: AppTheme.info),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _selectedPatient != null ? _selectPatient(_selectedPatient!) : _loadPatients(),
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jadwal Reminder', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                const Text('Kelola pengingat minum obat', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _testNotification,
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: const Text('Tes'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _testScheduledNotification,
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text('Tes Jadwal'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showForm = !_showForm),
                      icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                      label: Text(_showForm ? 'Tutup' : 'Tambah'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Patient Selector ────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Pasien', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedPatient?.id,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    hint: const Text('-- Pilih Pasien --'),
                    items: _patients.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final patient = _patients.firstWhere((p) => p.id == id);
                        _selectPatient(patient);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Add Form ────────────────────────────────
            if (_showForm) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Form Tambah Reminder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 14),

                    // Prescription selector
                    const Text('Resep Aktif *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _formPrescriptionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      hint: const Text('-- Pilih Resep --'),
                      items: _prescriptions.map((rx) {
                        final label = '${rx.medicationName ?? "Obat"} — ${rx.dosage} (${rx.frequency})';
                        return DropdownMenuItem(
                          value: rx.id,
                          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      selectedItemBuilder: (context) {
                        return _prescriptions.map((rx) {
                          final label = '${rx.medicationName ?? "Obat"} — ${rx.dosage} (${rx.frequency})';
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                          );
                        }).toList();
                      },
                      onChanged: (id) {
                        if (id != null) {
                          final rx = _prescriptions.firstWhere((r) => r.id == id);
                          final count = rx.frequencyCount;
                          List<String> times;
                          if (count == 1) {
                            times = ['08:00'];
                          } else if (count == 2) {
                            times = ['08:00', '20:00'];
                          } else if (count == 3) {
                            times = ['08:00', '13:00', '18:00'];
                          } else if (count == 4) {
                            times = ['06:00', '12:00', '18:00', '23:00'];
                          } else {
                            times = List.generate(count, (_) => '08:00');
                          }
                          setState(() {
                            _formPrescriptionId = id;
                            _formTimes = times;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Time pickers
                    Text(
                      'Waktu Pengingat (${_formTimes.length}x sehari) *',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: List.generate(_formTimes.length, (idx) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Waktu ${idx + 1}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () async {
                                final parts = _formTimes[idx].split(':');
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _formTimes[idx] =
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.border),
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppTheme.bgLight,
                                ),
                                child: Text(
                                  _formTimes[idx],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // Day selector
                    const Text('Hari *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _allDays.map((day) {
                        final isSelected = _formDays.contains(day);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _formDays.remove(day);
                              } else {
                                _formDays.add(day);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : AppTheme.border,
                              ),
                            ),
                            child: Text(
                              Helpers.dayLabels[day] ?? day,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Catatan tambahan...',
                      ),
                      onChanged: (val) => _formNotes = val,
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _showForm = false),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _formLoading ? null : _handleSubmit,
                            child: _formLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── Reminders List ──────────────────────────
            if (_selectedPatient == null)
              _EmptyState(icon: Icons.alarm, message: 'Pilih pasien untuk melihat reminder')
            else if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primary)))
            else if (_reminders.isEmpty)
              _EmptyState(icon: Icons.alarm, message: 'Belum ada reminder untuk ${_selectedPatient!.name}')
            else
              ..._reminders.map((r) => ReminderCard(
                    reminder: r,
                    onDelete: () => _handleDelete(r.id),
                    onToggle: (val) => _handleToggle(r.id, val),
                  )),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.textMuted.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
