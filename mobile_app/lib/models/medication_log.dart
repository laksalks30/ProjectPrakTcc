// ============ FILE: mobile_app/lib/models/medication_log.dart ============
class MedicationLog {
  final int? id;
  final int? reminderId;
  final int patientId;
  final int prescriptionId;
  final String scheduledAt;
  final String? takenAt;
  final String status; // taken, missed, skipped, late
  final String? notes;
  final int? loggedBy;
  final String? patientName;
  final String? medicationName;
  final String? createdAt;

  MedicationLog({
    this.id,
    this.reminderId,
    required this.patientId,
    required this.prescriptionId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    this.notes,
    this.loggedBy,
    this.patientName,
    this.medicationName,
    this.createdAt,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'],
      reminderId: json['reminder_id'],
      patientId: json['patient_id'] ?? 0,
      prescriptionId: json['prescription_id'] ?? 0,
      scheduledAt: json['scheduled_at'] ?? '',
      takenAt: json['taken_at'],
      status: json['status'] ?? 'taken',
      notes: json['notes'],
      loggedBy: json['logged_by'],
      patientName: json['patient_name'],
      medicationName: json['medication_name'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'prescription_id': prescriptionId,
        'scheduled_at': scheduledAt,
        'taken_at': takenAt,
        'status': status,
        'notes': notes ?? '',
      };

  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';

  String get statusLabel {
    switch (status) {
      case 'taken':
        return 'Diminum';
      case 'missed':
        return 'Terlewat';
      case 'skipped':
        return 'Dilewati';
      case 'late':
        return 'Terlambat';
      default:
        return status;
    }
  }
}
