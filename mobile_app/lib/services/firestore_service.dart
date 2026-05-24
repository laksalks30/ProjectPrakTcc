// ============ FILE: mobile_app/lib/services/firestore_service.dart ============
// 🔥 NoSQL Service — Firebase Firestore
// Fungsi utama:
// 1. Log minum obat OFFLINE (simpan lokal → sync saat online)
// 2. Status pengingat REALTIME (snapshot listeners)
// 3. Sinkronisasi perangkat mobile
// 4. Preferensi notifikasi suara

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'log_service.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }
  final LogService _logService = LogService();

  // ─────────────────────────────────────────────────────────────────
  // 1. OFFLINE LOGS — Simpan log saat offline, sync saat online
  // ─────────────────────────────────────────────────────────────────

  /// Simpan log minum obat ke Firestore (offline-first)
  Future<void> saveOfflineLog({
    required int userId,
    required Map<String, dynamic> logData,
  }) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId.toString())
        .collection('offline_logs')
        .add({
      ...logData,
      'synced': false,
      'created_at': FieldValue.serverTimestamp(),
      'device_time': DateTime.now().toIso8601String(),
    });
  }

  /// Sinkronisasi semua log offline ke REST API backend
  Future<int> syncOfflineLogs(int userId) async {
    final db = _db;
    if (db == null) return 0;
    // Cek koneksi internet
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return 0;

    final snapshot = await db
        .collection('users')
        .doc(userId.toString())
        .collection('offline_logs')
        .where('synced', isEqualTo: false)
        .get();

    int syncedCount = 0;

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();
        // Kirim ke REST API backend
        await _logService.create({
          'patient_id': data['patient_id'],
          'prescription_id': data['prescription_id'],
          'scheduled_at': data['scheduled_at'],
          'taken_at': data['taken_at'],
          'status': data['status'],
          'notes': data['notes'] ?? '',
        });

        // Tandai sudah disinkronkan
        await doc.reference.update({'synced': true, 'synced_at': FieldValue.serverTimestamp()});
        syncedCount++;
      } catch (_) {
        // Jika gagal sync, biarkan untuk dicoba lagi nanti
      }
    }

    return syncedCount;
  }

  /// Ambil semua log offline yang belum disinkronkan
  Future<List<Map<String, dynamic>>> getUnsyncedLogs(int userId) async {
    final db = _db;
    if (db == null) return [];
    final snapshot = await db
        .collection('users')
        .doc(userId.toString())
        .collection('offline_logs')
        .where('synced', isEqualTo: false)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ─────────────────────────────────────────────────────────────────
  // 2. REMINDER STATUS REALTIME — Stream status pengingat
  // ─────────────────────────────────────────────────────────────────

  /// Update status reminder di Firestore (realtime)
  Future<void> updateReminderStatus({
    required int userId,
    required int reminderId,
    required String status, // 'pending', 'taken', 'missed'
    String? takenAt,
  }) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId.toString())
        .collection('reminder_status')
        .doc(reminderId.toString())
        .set({
      'reminder_id': reminderId,
      'status': status,
      'taken_at': takenAt,
      'updated_at': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String().substring(0, 10),
    }, SetOptions(merge: true));
  }

  /// Stream realtime status reminder untuk hari ini
  Stream<QuerySnapshot> streamTodayReminderStatus(int userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('users')
        .doc(userId.toString())
        .collection('reminder_status')
        .where('date', isEqualTo: today)
        .snapshots();
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. SINKRONISASI PERANGKAT — Device sync info
  // ─────────────────────────────────────────────────────────────────

  /// Catat info perangkat yang sedang aktif
  Future<void> registerDevice({
    required int userId,
    required String deviceId,
    required String deviceName,
  }) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId.toString())
        .collection('device_sync')
        .doc(deviceId)
        .set({
      'device_id': deviceId,
      'device_name': deviceName,
      'last_active': FieldValue.serverTimestamp(),
      'platform': 'android',
    }, SetOptions(merge: true));
  }

  /// Stream perangkat aktif milik user
  Stream<QuerySnapshot> streamActiveDevices(int userId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('users')
        .doc(userId.toString())
        .collection('device_sync')
        .orderBy('last_active', descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────────────────────────────
  // 4. PREFERENSI NOTIFIKASI SUARA
  // ─────────────────────────────────────────────────────────────────

  /// Simpan preferensi notifikasi
  Future<void> saveNotificationPreferences({
    required int userId,
    required bool soundEnabled,
    required String soundType, // 'default', 'gentle', 'alarm'
    required bool vibrationEnabled,
  }) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId.toString())
        .collection('preferences')
        .doc('notification_settings')
        .set({
      'sound_enabled': soundEnabled,
      'sound_type': soundType,
      'vibration_enabled': vibrationEnabled,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Ambil preferensi notifikasi
  Future<Map<String, dynamic>> getNotificationPreferences(int userId) async {
    final db = _db;
    if (db == null) {
      return {
        'sound_enabled': true,
        'sound_type': 'default',
        'vibration_enabled': true,
      };
    }
    final doc = await db
        .collection('users')
        .doc(userId.toString())
        .collection('preferences')
        .doc('notification_settings')
        .get();

    if (doc.exists) {
      return doc.data()!;
    }

    // Default preferences
    return {
      'sound_enabled': true,
      'sound_type': 'default',
      'vibration_enabled': true,
    };
  }

  /// Stream preferensi notifikasi (realtime)
  Stream<DocumentSnapshot> streamNotificationPreferences(int userId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('users')
        .doc(userId.toString())
        .collection('preferences')
        .doc('notification_settings')
        .snapshots();
  }
}
