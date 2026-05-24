// ============ FILE: mobile_app/lib/services/reminder_service.dart ============
import '../config/api_config.dart';
import '../models/reminder.dart';
import 'api_client.dart';

class ReminderService {
  final _client = ApiClient(ApiConfig.medBaseUrl);

  /// Buat reminder baru
  Future<Reminder> create(Map<String, dynamic> data) async {
    final res = await _client.post('/reminders', body: data);
    return Reminder.fromJson(res['data']['reminder']);
  }

  /// Ambil reminder berdasarkan patient ID
  Future<List<Reminder>> getByPatient(int patientId) async {
    final res = await _client.get('/reminders/patient/$patientId');
    final list = res['data']?['reminders'] as List? ?? [];
    return list.map((e) => Reminder.fromJson(e)).toList();
  }

  /// Update reminder
  Future<Reminder> update(int id, Map<String, dynamic> data) async {
    final res = await _client.put('/reminders/$id', body: data);
    return Reminder.fromJson(res['data']['reminder']);
  }

  /// Hapus reminder
  Future<void> delete(int id) async {
    await _client.delete('/reminders/$id');
  }
}
