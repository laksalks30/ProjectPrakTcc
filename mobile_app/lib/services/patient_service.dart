// ============ FILE: mobile_app/lib/services/patient_service.dart ============
import '../config/api_config.dart';
import '../models/patient.dart';
import 'api_client.dart';

class PatientService {
  final _client = ApiClient(ApiConfig.medBaseUrl);

  /// Ambil semua pasien milik caregiver yang login
  Future<List<Patient>> getAll({int limit = 100}) async {
    final res = await _client.get('/patients', params: {'limit': '$limit'});
    final list = res['data']?['patients'] as List? ?? [];
    return list.map((e) => Patient.fromJson(e)).toList();
  }

  /// Ambil detail pasien berdasarkan ID
  Future<Patient> getById(int id) async {
    final res = await _client.get('/patients/$id');
    return Patient.fromJson(res['data']['patient']);
  }

  /// Tambah pasien baru
  Future<Patient> create({
    required String name,
    required String birthDate, // YYYY-MM-DD
    required String gender, // male/female
    String? address,
    String? bloodType,
    String? medicalNotes,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      if (address != null && address.isNotEmpty) 'address': address,
      if (bloodType != null && bloodType.isNotEmpty) 'blood_type': bloodType,
      if (medicalNotes != null && medicalNotes.isNotEmpty) 'medical_notes': medicalNotes,
    };

    final res = await _client.post('/patients', body: body);
    return Patient.fromJson(res['data']['patient']);
  }
}
