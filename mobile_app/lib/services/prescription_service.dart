// ============ FILE: mobile_app/lib/services/prescription_service.dart ============
import '../config/api_config.dart';
import '../models/prescription.dart';
import 'api_client.dart';

class PrescriptionService {
  final _client = ApiClient(ApiConfig.medBaseUrl);

  /// Ambil resep berdasarkan patient ID
  Future<List<Prescription>> getByPatient(int patientId, {String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;

    final res = await _client.get('/prescriptions/patient/$patientId', params: params.isNotEmpty ? params : null);
    final list = res['data']?['prescriptions'] as List? ?? [];
    return list.map((e) => Prescription.fromJson(e)).toList();
  }
}
