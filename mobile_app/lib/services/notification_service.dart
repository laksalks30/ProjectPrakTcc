// ============ FILE: mobile_app/lib/services/notification_service.dart ============
// 🔔 Notification Service — Notifikasi lokal + suara
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static const String _channelId = 'obat_lansia_channel_v2';
  static const String _channelName = 'Pengingat Obat';
  static const String _channelDesc = 'Notifikasi pengingat minum obat';

  /// Inisialisasi plugin notifikasi
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      // Best-effort: set local time zone if name is recognized.
      final name = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle tap pada notifikasi
      },
    );

    // Request permission untuk Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {}

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    );

    _initialized = true;
  }

  /// Tampilkan notifikasi langsung
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? sound,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  /// Jadwalkan notifikasi mingguan berdasarkan hari dan waktu
  static Future<void> scheduleWeeklyReminder({
    required int reminderId,
    required String dayKey, // monday, tuesday, ...
    required String time, // HH:mm
    required String patientName,
    required String medicationName,
    String? dosage,
  }) async {
    if (kIsWeb) return;

    final day = _weekdayFromKey(dayKey);
    final timeParts = time.split(':');
    if (day == null || timeParts.length != 2) return;

    final hour = int.tryParse(timeParts[0]) ?? 8;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final id = _buildNotificationId(reminderId, day, hour, minute);

    final scheduledDate = _nextInstanceOfWeekdayTime(day, TimeOfDay(hour: hour, minute: minute));

    final doseText = (dosage != null && dosage.trim().isNotEmpty) ? ' (${dosage.trim()})' : '';
    final body = '$patientName — $medicationName$doseText\nJadwal: $time';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        '💊 Waktunya Minum Obat!',
        body,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        '💊 Waktunya Minum Obat!',
        body,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Jadwalkan notifikasi sekali dalam beberapa menit (debug)
  static Future<void> scheduleInMinutes({
    required int id,
    required int minutes,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(minutes: minutes));

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Debug: jumlah notifikasi terjadwal
  static Future<int> pendingCount() async {
    final list = await _plugin.pendingNotificationRequests();
    return list.length;
  }

  /// Batalkan semua jadwal notifikasi untuk reminder tertentu
  static Future<void> cancelReminderSchedules({
    required int reminderId,
    required List<String> days,
    required String time,
  }) async {
    if (kIsWeb) return;
    final timeParts = time.split(':');
    if (timeParts.length != 2) return;
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    for (final dayKey in days) {
      final day = _weekdayFromKey(dayKey);
      if (day == null) continue;
      final id = _buildNotificationId(reminderId, day, hour, minute);
      await _plugin.cancel(id);
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static int? _weekdayFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  static int _buildNotificationId(int reminderId, int weekday, int hour, int minute) {
    final timeKey = hour * 60 + minute; // 0..1439
    final safeReminder = reminderId % 100000;
    return safeReminder * 100000 + weekday * 10000 + timeKey;
  }

  /// Tampilkan notifikasi pengingat minum obat
  static Future<void> showMedicationReminder({
    required int reminderId,
    required String patientName,
    required String medicationName,
    required String dosage,
    required String time,
  }) async {
    await showNotification(
      id: reminderId,
      title: '💊 Waktunya Minum Obat!',
      body: '$patientName — $medicationName ($dosage)\nJadwal: $time',
    );
  }

  /// Cancel notifikasi
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel semua notifikasi
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
