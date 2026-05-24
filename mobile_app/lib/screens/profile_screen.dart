// ============ FILE: mobile_app/lib/screens/profile_screen.dart ============
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _soundEnabled = true;
  String _soundType = 'default';
  bool _vibrationEnabled = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    try {
      final prefs = await _firestoreService.getNotificationPreferences(auth.user!.id);
      setState(() {
        _soundEnabled = prefs['sound_enabled'] ?? true;
        _soundType = prefs['sound_type'] ?? 'default';
        _vibrationEnabled = prefs['vibration_enabled'] ?? true;
        _loadingPrefs = false;
      });
    } catch (_) {
      setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _savePreferences() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    try {
      await _firestoreService.saveNotificationPreferences(
        userId: auth.user!.id,
        soundEnabled: _soundEnabled,
        soundType: _soundType,
        vibrationEnabled: _vibrationEnabled,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Preferensi disimpan'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Profile Card ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.gradientMedical,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: user?.avatarUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(user!.avatarUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                    ),
                                  )),
                        )
                      : Center(
                          child: Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role == 'admin' ? '👨‍⚕️ Admin' : '👤 User',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Info Section ───────────────────────────────
          _InfoTile(icon: Icons.email, label: 'Email', value: user?.email ?? '-'),
          _InfoTile(icon: Icons.phone, label: 'Telepon', value: user?.phone ?? 'Belum diisi'),
          _InfoTile(icon: Icons.badge, label: 'Role', value: user?.role == 'admin' ? 'Admin (Dokter/Klinik)' : 'User (Keluarga/Lansia)'),

          const SizedBox(height: 20),

          // ── Notification Preferences (NoSQL/Firestore) ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '🔥 Disimpan ke Firebase Firestore (NoSQL)',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const Divider(height: 20),

                if (_loadingPrefs)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primary)))
                else ...[
                  // Sound toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Suara Notifikasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Mainkan suara saat waktunya minum obat', style: TextStyle(fontSize: 12)),
                    value: _soundEnabled,
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                      _savePreferences();
                    },
                    activeColor: AppTheme.primary,
                  ),

                  // Sound type
                  if (_soundEnabled) ...[
                    const Text('Jenis Suara', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _SoundChip(label: '🔔 Default', value: 'default', selected: _soundType == 'default', onTap: () {
                          setState(() => _soundType = 'default');
                          _savePreferences();
                        }),
                        _SoundChip(label: '🎵 Gentle', value: 'gentle', selected: _soundType == 'gentle', onTap: () {
                          setState(() => _soundType = 'gentle');
                          _savePreferences();
                        }),
                        _SoundChip(label: '⏰ Alarm', value: 'alarm', selected: _soundType == 'alarm', onTap: () {
                          setState(() => _soundType = 'alarm');
                          _savePreferences();
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Vibration toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Getar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Getarkan perangkat saat notifikasi', style: TextStyle(fontSize: 12)),
                    value: _vibrationEnabled,
                    onChanged: (val) {
                      setState(() => _vibrationEnabled = val);
                      _savePreferences();
                    },
                    activeColor: AppTheme.primary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Logout Button ──────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await auth.logout();
                  if (mounted) Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.error, size: 18),
              label: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── App info ────────────────────────────────
          Text('ObatLansia v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text('© 2026 — Pengingat Minum Obat Lansia', style: TextStyle(fontSize: 11, color: AppTheme.textMuted.withOpacity(0.6))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Info Tile ────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sound Chip ──────────────────────────────────────────────────────
class _SoundChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _SoundChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
