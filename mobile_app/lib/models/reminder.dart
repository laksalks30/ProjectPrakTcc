// ============ FILE: mobile_app/lib/models/reminder.dart ============
class Reminder {
  final int id;
  final int prescriptionId;
  final int patientId;
  final String scheduledTime;
  final List<String> daysOfWeek;
  final bool isActive;
  final String? notes;
  final String? medicationName;
  final String? patientName;
  bool alreadyLogged; // flag sisi client

  Reminder({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.scheduledTime,
    required this.daysOfWeek,
    required this.isActive,
    this.notes,
    this.medicationName,
    this.patientName,
    this.alreadyLogged = false,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    List<String> days = [];
    if (json['days_of_week'] is List) {
      days = (json['days_of_week'] as List).map((e) => e.toString().toLowerCase()).toList();
    } else if (json['days_of_week'] is String) {
      days = (json['days_of_week'] as String).split(',').map((e) => e.trim().toLowerCase()).toList();
    }

    return Reminder(
      id: json['id'] ?? 0,
      prescriptionId: json['prescription_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      scheduledTime: json['scheduled_time'] ?? '08:00',
      daysOfWeek: days,
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
      medicationName: json['medication_name'],
      patientName: json['patient_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'prescription_id': prescriptionId,
        'patient_id': patientId,
        'scheduled_time': scheduledTime,
        'days_of_week': daysOfWeek,
        'is_active': isActive,
        'notes': notes,
      };

  /// Waktu dalam format HH:mm
  String get timeShort => scheduledTime.length >= 5 ? scheduledTime.substring(0, 5) : scheduledTime;

  /// Parse waktu ke menit sejak midnight
  int get scheduledMinutes {
    final parts = timeShort.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
