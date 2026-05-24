// ============ FILE: mobile_app/lib/screens/home_screen.dart ============
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/patient_service.dart';
import '../services/firestore_service.dart';
import '../models/patient.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PatientService _patientService = PatientService();
  final FirestoreService _firestoreService = FirestoreService();
  List<Patient> _patients = [];
  bool _loading = true;
  int _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _patients = await _patientService.getAll();

      // Cek log offline yang belum disync
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        try {
          final unsynced = await _firestoreService.getUnsyncedLogs(auth.user!.id);
          _unsyncedCount = unsynced.length;

          // Auto-sync jika ada
          if (_unsyncedCount > 0) {
            final synced = await _firestoreService.syncOfflineLogs(auth.user!.id);
            if (synced > 0 && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ $synced log offline berhasil disinkronkan'),
                  backgroundColor: AppTheme.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
              _unsyncedCount -= synced;
            }
          }
        } catch (_) {
          // Firebase belum dikonfigurasi, skip fitur offline sync
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _navigateToTab(int index) {
    final navState = context.findAncestorStateOfType<MainNavigatorState>();
    navState?.setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.gradientMedical,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?.name ?? 'User'} 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pantau kesehatan lansia Anda',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Offline sync banner ────────────────────
            if (_unsyncedCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off, color: AppTheme.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_unsyncedCount log belum disinkronkan',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadData,
                      child: const Text('Sync', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

            // ── Quick Stats ─────────────────────────────
            Row(
              children: [
                _StatCard(
                  icon: Icons.people,
                  label: 'Total Lansia',
                  value: '${_patients.length}',
                  color: AppTheme.primary,
                  loading: _loading,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.notifications_active,
                  label: 'Reminder',
                  value: 'Aktif',
                  color: AppTheme.secondary,
                  loading: _loading,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick Actions ───────────────────────────
            const Text(
              'Aksi Cepat',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionCard(
                  icon: Icons.alarm_add,
                  label: 'Jadwal\nReminder',
                  color: AppTheme.primary,
                  onTap: () => _navigateToTab(2),
                ),
                const SizedBox(width: 12),
                _ActionCard(
                  icon: Icons.checklist,
                  label: 'Catat\nLog Obat',
                  color: AppTheme.info,
                  onTap: () => _navigateToTab(3),
                ),
                const SizedBox(width: 12),
                _ActionCard(
                  icon: Icons.people_alt,
                  label: 'Data\nLansia',
                  color: AppTheme.accent,
                  onTap: () => _navigateToTab(1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Patients List ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lansia Terdaftar',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                Text(
                  '${_patients.length} pasien',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ))
            else if (_patients.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 40, color: AppTheme.textMuted),
                      SizedBox(height: 8),
                      Text('Belum ada data lansia', style: TextStyle(color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              )
            else
              ...(_patients.take(5).map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: AppTheme.gradientMedical,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              p.initials,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text(p.genderLabel, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
                      ],
                    ),
                  ))),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card Widget ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool loading;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            if (loading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Action Card Widget ──────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
