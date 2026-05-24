// ============ FILE: mobile_app/lib/utils/helpers.dart ============
import 'package:intl/intl.dart';

class Helpers {
  /// Format tanggal ke "24 Mei 2026"
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format waktu ke "08:00"
  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '-';
    return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
  }

  /// Format datetime ke "24 Mei 2026, 08:00"
  static String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return dateTimeStr;
    }
  }

  /// Konversi waktu lokal ke ISO string tanpa offset UTC
  static String toLocalISO(DateTime date) {
    final d = date.toLocal();
    return '${d.year}-${_pad(d.month)}-${_pad(d.day)}T${_pad(d.hour)}:${_pad(d.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Parse waktu "HH:mm" ke menit sejak midnight
  static int parseTimeToMinutes(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Menit ke waktu "HH:mm"
  static String minutesToTimeStr(int minutes) {
    final hh = (minutes ~/ 60) % 24;
    final mm = minutes % 60;
    return '${_pad(hh)}:${_pad(mm)}';
  }

  /// Hari sekarang dalam format lowercase english
  static String todayKey() {
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    return days[DateTime.now().weekday % 7];
  }

  /// Nama hari Indonesia
  static const Map<String, String> dayLabels = {
    'monday': 'Senin',
    'tuesday': 'Selasa',
    'wednesday': 'Rabu',
    'thursday': 'Kamis',
    'friday': 'Jumat',
    'saturday': 'Sabtu',
    'sunday': 'Minggu',
  };
}
