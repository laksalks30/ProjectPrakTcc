// ============ FILE: mobile_app/lib/services/log_service.dart ============
import '../config/api_config.dart';
import '../models/medication_log.dart';
import 'api_client.dart';

class LogService {
  final _client = ApiClient(ApiConfig.medBaseUrl);

  /// Catat log minum obat
  Future<MedicationLog> create(Map<String, dynamic> data) async {
    final res = await _client.post('/logs', body: data);
    return MedicationLog.fromJson(res['data']['log']);
  }

  /// Ambil riwayat log berdasarkan patient ID
  Future<List<MedicationLog>> getByPatient(int patientId) async {
    final res = await _client.get('/logs/patient/$patientId');
    final list = res['data']?['logs'] as List? ?? [];
    return list.map((e) => MedicationLog.fromJson(e)).toList();
  }
}
