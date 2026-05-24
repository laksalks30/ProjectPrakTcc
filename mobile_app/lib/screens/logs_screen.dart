// ============ FILE: mobile_app/lib/screens/logs_screen.dart ============
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/patient.dart';
import '../models/prescription.dart';
import '../models/reminder.dart';
import '../models/medication_log.dart';
import '../services/patient_service.dart';
import '../services/prescription_service.dart';
import '../services/reminder_service.dart';
import '../services/log_service.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/log_item.dart';
import '../utils/helpers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const List<String> _dayKeys = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final PatientService _patientService = PatientService();
  final PrescriptionService _prescriptionService = PrescriptionService();
  final ReminderService _reminderService = ReminderService();
  final LogService _logService = LogService();
  final FirestoreService _firestoreService = FirestoreService();

  List<Patient> _patients = [];
  List<Prescription> _prescriptions = [];
  List<Reminder> _todayReminders = [];
  List<MedicationLog> _logs = [];
  bool _loadingLogs = false;
  bool _confirming = false;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  int _step = 1;
  Patient? _selectedPatient;
  Prescription? _selectedPrescription;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    _loadPatients();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _nowMins => _currentTime.hour * 60 + _currentTime.minute;

  Reminder? get _activeReminder {
    return _todayReminders.cast<Reminder?>().firstWhere(
      (r) => r != null && !r.alreadyLogged && _nowMins >= Helpers.parseTimeToMinutes(r.scheduledTime),
      orElse: () => null,
    );
  }

  Reminder? get _nextUpcoming {
    return _todayReminders.cast<Reminder?>().firstWhere(
      (r) => r != null && !r.alreadyLogged && Helpers.parseTimeToMinutes(r.scheduledTime) > _nowMins,
      orElse: () => null,
    );
  }

  bool get _canConfirm => _activeReminder != null;

  Future<void> _loadPatients() async {
    try {
      _patients = await _patientService.getAll();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _handleSelectPatient(Patient patient) async {
    setState(() {
      _selectedPatient = patient;
      _selectedPrescription = null;
      _todayReminders = [];
      _prescriptions = [];
      _step = 2;
    });
    try {
      _prescriptions = await _prescriptionService.getByPatient(patient.id);
    } catch (_) {}
    _fetchLogs(patient.id);
    if (mounted) setState(() {});
  }

  Future<void> _handleSelectPrescription(Prescription prescription) async {
    setState(() {
      _selectedPrescription = prescription;
      _todayReminders = [];
      _step = 3;
    });

    try {
      final reminders = await _reminderService.getByPatient(_selectedPatient!.id);
      final todayKey = _dayKeys[DateTime.now().weekday % 7];

      final filtered = reminders.where((r) {
        if (r.prescriptionId != prescription.id) return false;
        final days = r.daysOfWeek.map((d) => d.toLowerCase()).toList();
        return days.contains(todayKey) || days.contains('everyday') || days.isEmpty;
      }).toList();

      final todayDate = Helpers.toLocalISO(DateTime.now()).split('T')[0];
      for (final r in filtered) {
        final timeStr = r.timeShort;
        r.alreadyLogged = _logs.any((log) {
          if (log.prescriptionId != prescription.id) return false;
          if (log.scheduledAt.isEmpty) return false;
          final logDate = log.scheduledAt.split('T')[0];
          final logTime = log.scheduledAt.split('T')[1].substring(0, 5);
          return logDate == todayDate && logTime == timeStr;
        });
      }

      filtered.sort((a, b) => a.scheduledMinutes.compareTo(b.scheduledMinutes));
      setState(() => _todayReminders = filtered);
    } catch (_) {}
  }

  Future<void> _fetchLogs(int patientId) async {
    setState(() => _loadingLogs = true);
    try {
      _logs = await _logService.getByPatient(patientId);
    } catch (_) {}
    if (mounted) setState(() => _loadingLogs = false);
  }

  Future<void> _handleConfirm(String status) async {
    setState(() => _confirming = true);

    try {
      final now = DateTime.now();
      final takenAt = Helpers.toLocalISO(now);
      final todayDate = Helpers.toLocalISO(now).split('T')[0];
      final scheduledAt = _activeReminder != null
          ? '${todayDate}T${_activeReminder!.timeShort}'
          : takenAt;

      final logData = {
        'patient_id': _selectedPatient!.id,
        'prescription_id': _selectedPrescription!.id,
        'scheduled_at': scheduledAt,
        'taken_at': status == 'taken' ? takenAt : null,
        'status': status,
        'notes': '',
      };

      // Cek koneksi — jika offline, simpan ke Firestore
      final connectivity = await Connectivity().checkConnectivity();
      final auth = context.read<AuthProvider>();

      if (connectivity.contains(ConnectivityResult.none)) {
        // 🔥 OFFLINE — Simpan ke Firestore NoSQL
        await _firestoreService.saveOfflineLog(
          userId: auth.user!.id,
          logData: logData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('📴 Tersimpan offline. Akan disinkronkan saat online.'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // ✅ ONLINE — Kirim langsung ke REST API
        await _logService.create(logData);

        // Update Firestore realtime status
        if (_activeReminder != null) {
          await _firestoreService.updateReminderStatus(
            userId: auth.user!.id,
            reminderId: _activeReminder!.id,
            status: status,
            takenAt: status == 'taken' ? takenAt : null,
          );
        }

        // Cek terlambat → geser jadwal berikutnya
        if (status == 'taken' && _activeReminder != null) {
          final scheduledMins = Helpers.parseTimeToMinutes(_activeReminder!.scheduledTime);
          final takenMins = now.hour * 60 + now.minute;
          final delayMins = takenMins - scheduledMins;

          if (delayMins > 15) {
            final nextReminder = _todayReminders.cast<Reminder?>().firstWhere(
              (r) => r != null && Helpers.parseTimeToMinutes(r.scheduledTime) > Helpers.parseTimeToMinutes(_activeReminder!.scheduledTime),
              orElse: () => null,
            );

            if (nextReminder != null) {
              final origMins = Helpers.parseTimeToMinutes(nextReminder.scheduledTime);
              final newTimeStr = Helpers.minutesToTimeStr(origMins + delayMins);

              await _reminderService.update(nextReminder.id, {
                'scheduled_time': newTimeStr,
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⏰ Terlambat $delayMins menit — jadwal berikutnya digeser ke $newTimeStr'),
                    backgroundColor: AppTheme.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            }
          }
        }
      }

      final msg = status == 'taken'
          ? '✅ ${_selectedPrescription!.medicationName ?? "Obat"} dicatat sudah diminum!'
          : '❌ ${_selectedPrescription!.medicationName ?? "Obat"} dicatat belum diminum.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: status == 'taken' ? AppTheme.success : AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      await _fetchLogs(_selectedPatient!.id);
      setState(() {
        _selectedPrescription = null;
        _todayReminders = [];
        _step = 2;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error),
        );
      }
    }

    if (mounted) setState(() => _confirming = false);
  }

  void _handleReset() {
    setState(() {
      _step = 1;
      _selectedPatient = null;
      _selectedPrescription = null;
      _prescriptions = [];
      _todayReminders = [];
      _logs = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header + Clock ────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Riwayat Log', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const Text('Catat minum obat pasien', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              // Realtime clock
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF93C5FD), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_step > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _handleReset,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Mulai Ulang'),
              ),
            ),
          const SizedBox(height: 12),

          // ── Breadcrumb ────────────────────────────────
          Row(
            children: [
              _BreadcrumbStep(n: 1, label: 'Pilih Lansia', active: _step >= 1),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
              _BreadcrumbStep(n: 2, label: 'Pilih Obat', active: _step >= 2),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
              _BreadcrumbStep(n: 3, label: 'Konfirmasi', active: _step >= 3),
            ],
          ),
          const SizedBox(height: 16),

          // ── STEP 1: Pilih Pasien ──────────────────────
          if (_step == 1) ...[
            _SectionCard(
              title: 'Pilih Pasien Lansia',
              child: _patients.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data pasien', style: TextStyle(color: AppTheme.textMuted))))
                  : Column(
                      children: _patients.map((p) => _SelectableItem(
                            title: p.name,
                            subtitle: '${p.genderLabel}${p.address != null ? ' · ${p.address}' : ''}',
                            initial: p.initials,
                            onTap: () => _handleSelectPatient(p),
                          )).toList(),
                    ),
            ),
          ],

          // ── STEP 2: Pilih Obat ────────────────────────
          if (_step == 2 && _selectedPatient != null) ...[
            _SectionCard(
              title: 'Pilih Obat untuk ${_selectedPatient!.name}',
              subtitle: 'Pilih obat yang ingin dicatat status minumnya',
              child: _prescriptions.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text('Belum ada resep aktif', style: TextStyle(color: AppTheme.textMuted)),
                            Text('Tambahkan resep via web', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: _prescriptions.map((rx) => _SelectableItem(
                            title: rx.medicationName ?? 'Obat',
                            subtitle: '${rx.dosage} · ${rx.frequency}',
                            icon: Icons.medication,
                            onTap: () => _handleSelectPrescription(rx),
                          )).toList(),
                    ),
            ),
          ],

          // ── STEP 3: Konfirmasi ────────────────────────
          if (_step == 3 && _selectedPatient != null && _selectedPrescription != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  // Info pasien & obat
                  Text('Konfirmasi minum obat untuk', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(_selectedPatient!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _selectedPrescription!.medicationName ?? 'Obat',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.info),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedPrescription!.dosage} · ${_selectedPrescription!.frequency}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Jadwal hari ini
                  if (_todayReminders.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('📅 Jadwal minum hari ini:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _todayReminders.map((r) {
                        final rMins = Helpers.parseTimeToMinutes(r.scheduledTime);
                        final isDue = _nowMins >= rMins;
                        final isActive = _activeReminder?.id == r.id;

                        Color bgColor;
                        Color borderColor;
                        Color textColor;
                        String suffix;

                        if (r.alreadyLogged) {
                          bgColor = AppTheme.success.withOpacity(0.1);
                          borderColor = AppTheme.success.withOpacity(0.3);
                          textColor = AppTheme.success;
                          suffix = ' (Selesai)';
                        } else if (isActive) {
                          bgColor = AppTheme.success.withOpacity(0.15);
                          borderColor = AppTheme.success;
                          textColor = AppTheme.success;
                          suffix = ' ← Sekarang';
                        } else if (isDue) {
                          bgColor = AppTheme.textMuted.withOpacity(0.1);
                          borderColor = AppTheme.textMuted.withOpacity(0.3);
                          textColor = AppTheme.textMuted;
                          suffix = '';
                        } else {
                          bgColor = AppTheme.info.withOpacity(0.1);
                          borderColor = AppTheme.info.withOpacity(0.3);
                          textColor = AppTheme.info;
                          suffix = ' (belum)';
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Text(
                            '${r.timeShort}$suffix',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: textColor),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppTheme.textMuted),
                          SizedBox(width: 8),
                          Text('Tidak ada jadwal reminder hari ini.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Realtime clock
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF93C5FD), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24, fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 8),
                        Text('WIB', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Belum waktunya / Selesai
                  if (_todayReminders.isNotEmpty && !_canConfirm) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _todayReminders.every((r) => r.alreadyLogged)
                            ? AppTheme.success.withOpacity(0.08)
                            : AppTheme.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _todayReminders.every((r) => r.alreadyLogged)
                              ? AppTheme.success.withOpacity(0.3)
                              : AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: _todayReminders.every((r) => r.alreadyLogged)
                          ? const Column(
                              children: [
                                Icon(Icons.check_circle, size: 28, color: AppTheme.success),
                                SizedBox(height: 6),
                                Text('Semua Selesai', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.success)),
                                Text('Seluruh jadwal hari ini sudah dicatat.', style: TextStyle(fontSize: 12, color: AppTheme.success)),
                              ],
                            )
                          : Column(
                              children: [
                                const Icon(Icons.warning_amber, size: 28, color: AppTheme.warning),
                                const SizedBox(height: 6),
                                const Text('Belum Waktunya', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.warning)),
                                if (_nextUpcoming != null)
                                  Text('Tunggu hingga pukul ${_nextUpcoming!.timeShort}', style: const TextStyle(fontSize: 12, color: AppTheme.warning)),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Konfirmasi buttons
                  if (_canConfirm || _todayReminders.isEmpty) ...[
                    const Text('Apakah obat sudah diminum?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _confirming ? null : () => _handleConfirm('missed'),
                            icon: const Icon(Icons.cancel, size: 18, color: AppTheme.error),
                            label: const Text('Belum', style: TextStyle(color: AppTheme.error)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.error, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _confirming ? null : () => _handleConfirm('taken'),
                            icon: _confirming
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle, size: 18),
                            label: Text(_confirming ? 'Menyimpan...' : 'Sudah ✓'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _step = 2;
                        _selectedPrescription = null;
                        _todayReminders = [];
                      });
                    },
                    child: const Text('← Ganti obat'),
                  ),
                ],
              ),
            ),
          ],

          // ── Riwayat Log ───────────────────────────────
          if (_selectedPatient != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Riwayat — ${_selectedPatient!.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${_logs.length} entri', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingLogs)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primary)))
            else if (_logs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(child: Text('Belum ada riwayat log', style: TextStyle(color: AppTheme.textMuted))),
              )
            else
              ..._logs.take(20).map((log) => LogItem(log: log)),
          ],
        ],
      ),
    );
  }
}

// ── Breadcrumb Step ─────────────────────────────────────────────────
class _BreadcrumbStep extends StatelessWidget {
  final int n;
  final String label;
  final bool active;
  const _BreadcrumbStep({required this.n, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppTheme.info.withOpacity(0.1) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$n. $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AppTheme.info : AppTheme.textMuted,
        ),
      ),
    );
  }
}

// ── Section Card ────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Selectable Item ─────────────────────────────────────────────────
class _SelectableItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? initial;
  final IconData? icon;
  final VoidCallback onTap;

  const _SelectableItem({
    required this.title,
    required this.subtitle,
    this.initial,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (initial != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(gradient: AppTheme.gradientMedical, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(initial!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              )
            else if (icon != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
