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

  static const String _alarmChannelId = 'obat_lansia_alarm_v1';
  static const String _alarmChannelName = 'Alarm Obat';
  static const String _alarmChannelDesc = 'Alarm pengingat minum obat dengan suara';

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void Function(String payload)? onNotificationTapped;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final name = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

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

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _alarmChannelId,
        _alarmChannelName,
        description: _alarmChannelDesc,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        ledColor: Color(0xFF14B8A6),
      ),
    );

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty && onNotificationTapped != null) {
      onNotificationTapped!(payload);
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? sound,
    String? payload,
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
      payload: payload,
    );
  }

  static Future<void> showAlarmNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('taken', 'Sudah Diminum', showsUserInterface: true),
        const AndroidNotificationAction('snooze', 'Tunda 5 Menit', showsUserInterface: true),
      ],
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> scheduleWeeklyReminder({
    required int reminderId,
    required String dayKey,
    required String time,
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

    final payload = 'reminder|$reminderId|$patientName|$medicationName|${dosage ?? ""}|$time';

    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        'Waktunya Minum Obat!',
        body,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        'Waktunya Minum Obat!',
        body,
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  static Future<void> scheduleInMinutes({
    required int id,
    required int minutes,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(minutes: minutes));

    final androidDetails = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
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
        payload: payload,
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
        payload: payload,
      );
    }
  }

  static Future<int> pendingCount() async {
    final list = await _plugin.pendingNotificationRequests();
    return list.length;
  }

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
    final timeKey = hour * 60 + minute;
    final safeReminder = reminderId % 100000;
    return safeReminder * 100000 + weekday * 10000 + timeKey;
  }

  static Future<void> showMedicationReminder({
    required int reminderId,
    required String patientName,
    required String medicationName,
    required String dosage,
    required String time,
  }) async {
    final payload = 'reminder|$reminderId|$patientName|$medicationName|$dosage|$time';
    await showAlarmNotification(
      id: reminderId,
      title: 'Waktunya Minum Obat!',
      body: '$patientName — $medicationName ($dosage)\nJadwal: $time',
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
