import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../models/patient.dart';
import '../services/patient_service.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';

class AlarmService extends ChangeNotifier {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PatientService _patientService = PatientService();
  final ReminderService _reminderService = ReminderService();

  List<Reminder> _activeReminders = [];
  bool _isPlaying = false;
  bool _isStarted = false;
  DateTime? _lastFetchTime;
  String? _lastPlayedReminderKey;

  bool get isAlarmPlaying => _isPlaying;
  List<Reminder> get activeReminders => List.unmodifiable(_activeReminders);

  Reminder? get nextReminder {
    final now = DateTime.now();
    final currentDay = Helpers.todayKey();
    final currentMinutes = now.hour * 60 + now.minute;
    List<Reminder> todayReminders = _activeReminders
        .where((r) => r.daysOfWeek.contains(currentDay) && r.scheduledMinutes > currentMinutes)
        .toList();
    if (todayReminders.isEmpty) return null;
    todayReminders.sort((a, b) => a.scheduledMinutes.compareTo(b.scheduledMinutes));
    return todayReminders.first;
  }

  int? get minutesUntilNext {
    final next = nextReminder;
    if (next == null) return null;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    return next.scheduledMinutes - currentMinutes;
  }

  void start(BuildContext context) {
    if (_isStarted) return;
    _isStarted = true;

    _timer?.cancel();
    _fetchReminders().then((_) => _checkAlarm(context));
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkAlarm(context);
      notifyListeners();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isStarted = false;
    stopAlarm();
  }

  Future<void> refreshReminders() async {
    await _fetchReminders();
    notifyListeners();
  }

  Future<void> _fetchReminders() async {
    try {
      List<Patient> patients = await _patientService.getAll();
      List<Reminder> allReminders = [];
      for (var p in patients) {
        var rems = await _reminderService.getByPatient(p.id);
        allReminders.addAll(rems.where((r) => r.isActive));
      }
      _activeReminders = allReminders;
      _lastFetchTime = DateTime.now();
      debugPrint('AlarmService fetched ${_activeReminders.length} active reminders');
    } catch (e) {
      debugPrint("Gagal fetch reminders untuk alarm: $e");
    }
  }

  void _checkAlarm(BuildContext context) {
    if (_isPlaying) return;

    final now = DateTime.now();

    if (_lastFetchTime == null || now.difference(_lastFetchTime!).inMinutes >= 5) {
      _fetchReminders();
    }

    final currentDate = DateFormat('yyyy-MM-dd').format(now);
    final currentDay = Helpers.todayKey();
    final currentMinutes = now.hour * 60 + now.minute;

    debugPrint('=== CHECK ALARM ${now.hour}:${now.minute} ===');
    debugPrint('Hari: $currentDay | Menit sekarang: $currentMinutes');
    debugPrint('Total active reminders: ${_activeReminders.length}');
    for (var r in _activeReminders) {
      final selisih = currentMinutes - r.scheduledMinutes;
      debugPrint('  Reminder ${r.id}: days=${r.daysOfWeek}, scheduledMenit=${r.scheduledMinutes}, selisih=$selisih');
      debugPrint('  → containsDay: ${r.daysOfWeek.contains(currentDay)}');
    }

    for (var reminder in _activeReminders) {
      final reminderKey = '$currentDate|${reminder.id}|${reminder.timeShort}';

      if (_lastPlayedReminderKey == reminderKey) continue;

      final minutesLate = currentMinutes - reminder.scheduledMinutes;
      final shouldRingToday =
          reminder.daysOfWeek.contains(currentDay) && minutesLate >= 0 && minutesLate <= 10;

      if (shouldRingToday) {
        _lastPlayedReminderKey = reminderKey;
        debugPrint('Alarm fired for reminder ${reminder.id} at ${reminder.timeShort}');
        _playAlarmAndShowDialog(context, reminder);
        break;
      }
    }
  }

  Future<void> testAlarm(BuildContext context, {Reminder? reminder}) async {
    final testReminder = reminder ?? Reminder(
      id: 0,
      prescriptionId: 0,
      patientId: 0,
      scheduledTime: DateFormat('HH:mm').format(DateTime.now()),
      daysOfWeek: [Helpers.todayKey()],
      isActive: true,
      medicationName: 'Obat Tes',
      patientName: 'Pasien Tes',
      notes: 'Ini adalah tes alarm. Suara dan dialog alarm berfungsi!',
    );
    _isPlaying = false;
    await _playAlarmAndShowDialog(context, testReminder);
  }

  Future<void> _playAlarmAndShowDialog(BuildContext context, Reminder reminder) async {
    if (_isPlaying) return;
    _isPlaying = true;
    notifyListeners();

    // Kirim notifikasi ke status bar
    await NotificationService.showAlarmNotification(
      id: reminder.id,
      title: 'Waktunya Minum Obat! 🔔',
      body: '${reminder.patientName ?? "Pasien"} — ${reminder.medicationName ?? "Obat"} jam ${reminder.timeShort}',
      payload: 'reminder|${reminder.id}|${reminder.patientName ?? ""}|${reminder.medicationName ?? ""}||${reminder.timeShort}',
    );

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm.wav'));
    } catch (e) {
      debugPrint("Gagal mainkan suara alarm: $e");
      try {
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      } catch (_) {}
    }

    if (!context.mounted) {
      stopAlarm();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AlarmDialog(
        reminder: reminder,
        onDismiss: () {
          stopAlarm();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void stopAlarm() {
    _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }
}

// ── Alarm Dialog Widget ───────────────────────────────────────────────
class _AlarmDialog extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onDismiss;

  const _AlarmDialog({required this.reminder, required this.onDismiss});

  @override
  State<_AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<_AlarmDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.alarm, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waktunya Minum Obat!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2D3436)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.person_outline, label: 'Pasien', value: widget.reminder.patientName ?? 'Pasien'),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.medication_outlined, label: 'Obat', value: widget.reminder.medicationName ?? 'Obat'),
                  _InfoRow(icon: Icons.access_time_outlined, label: 'Waktu', value: widget.reminder.timeShort),
                  if (widget.reminder.notes != null && widget.reminder.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.notes_outlined, label: 'Catatan', value: widget.reminder.notes!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEE5A24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: widget.onDismiss,
                icon: const Icon(Icons.alarm_off, size: 20),
                label: const Text('Matikan Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.red),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF636E72))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF2D3436)))),
        ],
      ),
    );
  }
}