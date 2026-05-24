// ============ FILE: mobile_app/lib/models/prescription.dart ============
class Prescription {
  final int id;
  final int patientId;
  final int medicationId;
  final String dosage;
  final String frequency;
  final String startDate;
  final String? endDate;
  final String? doctorName;
  final String? notes;
  final String status;
  final String? medicationName;
  final String? patientName;

  Prescription({
    required this.id,
    required this.patientId,
    required this.medicationId,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.doctorName,
    this.notes,
    required this.status,
    this.medicationName,
    this.patientName,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      medicationId: json['medication_id'] ?? 0,
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'],
      doctorName: json['doctor_name'],
      notes: json['notes'],
      status: json['status'] ?? 'active',
      medicationName: json['medication_name'],
      patientName: json['patient_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'medication_id': medicationId,
        'dosage': dosage,
        'frequency': frequency,
        'start_date': startDate,
        'end_date': endDate,
        'doctor_name': doctorName,
        'notes': notes,
        'status': status,
      };

  bool get isActive => status == 'active';

  /// Parse frekuensi (e.g. "2x sehari") menjadi angka
  int get frequencyCount {
    final match = RegExp(r'(\d+)x').firstMatch(frequency);
    return match != null ? int.parse(match.group(1)!) : 1;
  }
}
