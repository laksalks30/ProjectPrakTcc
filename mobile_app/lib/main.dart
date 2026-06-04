// ============ FILE: mobile_app/lib/main.dart ============
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'screens/alarm_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase (Hanya untuk Mobile)
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase init error (will work without it): $e');
  }

  // Inisialisasi Notifikasi (Hanya untuk Mobile)
  if (!kIsWeb) {
    await NotificationService.initialize();
    NotificationService.onNotificationTapped = (payload) {
      final parts = payload.split('|');
      if (parts.length < 6 || parts.first != 'reminder') {
        return;
      }

      final reminderId = int.tryParse(parts[1]) ?? 0;
      final patientName = parts[2];
      final medicationName = parts[3];
      final dosage = parts[4];
      final time = parts[5];

      NotificationService.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => AlarmScreen(
            reminderId: reminderId,
            patientName: patientName,
            medicationName: medicationName,
            dosage: dosage,
            time: time,
          ),
        ),
      );
    };
  }

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ObatLansiaApp());
}

class ObatLansiaApp extends StatelessWidget {
  const ObatLansiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            navigatorKey: NotificationService.navigatorKey,
            title: 'ObatLansia',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: auth.isLoading
                ? const _SplashScreen()
                : auth.isAuthenticated
                    ? const MainNavigator()
                    : const LoginScreen(),
            routes: {
              '/login': (_) => const LoginScreen(),
              '/register': (_) => const RegisterScreen(),
              '/home': (_) => const MainNavigator(),
            },
          );
        },
      ),
    );
  }
}

// ── Splash Screen ───────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.gradientBg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              const Text(
                'ObatLansia',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Pengingat Minum Obat Lansia',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main Navigator with Bottom Navigation ──────────────────────────
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => MainNavigatorState();
}

class MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PatientsScreen(),
    RemindersScreen(),
    LogsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Jalankan alarm service di background saat berada di MainNavigator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AlarmService().start(context);
    });
  }

  @override
  void dispose() {
    AlarmService().stop();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  /// Exposed for child widgets to change tab
  void setTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final alarm = AlarmService();
    return ListenableBuilder(
      listenable: alarm,
      builder: (context, _) {
        final isRinging = alarm.isAlarmPlaying;
        final activeCount = alarm.activeReminders.length;
        final nextRem = alarm.nextReminder;
        final minutesLeft = alarm.minutesUntilNext;
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[_currentIndex]),
            centerTitle: false,
            actions: [
              // ── Alarm Indicator ──────────────────────────
              if (isRinging)
                _PulsingAlarmButton(
                  onTap: () => AlarmService().testAlarm(context),
                )
              else if (activeCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _onTabTapped(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.alarm, size: 22),
                              if (activeCount > 0)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEE5A24),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$activeCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (nextRem != null && minutesLeft != null && minutesLeft <= 60) ...[  
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: minutesLeft <= 10
                                    ? const Color(0xFFEE5A24).withOpacity(0.15)
                                    : const Color(0xFF0984E3).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                minutesLeft <= 0
                                    ? 'Sekarang!'
                                    : minutesLeft == 1
                                        ? '1 mnt lagi'
                                        : '$minutesLeft mnt lagi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: minutesLeft <= 10 ? const Color(0xFFEE5A24) : const Color(0xFF0984E3),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (_currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 22),
                  onPressed: () => setState(() {}),
                ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Beranda'),
                const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Lansia'),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.alarm),
                      if (activeCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEE5A24),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Reminder',
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Log'),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _titles = ['Dashboard', 'Data Lansia', 'Jadwal Reminder', 'Riwayat Log', 'Profil Saya'];
}

// ── Pulsing Alarm Button ─────────────────────────────────────────────
class _PulsingAlarmButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingAlarmButton({required this.onTap});

  @override
  State<_PulsingAlarmButton> createState() => _PulsingAlarmButtonState();
}

class _PulsingAlarmButtonState extends State<_PulsingAlarmButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEE5A24),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.alarm, color: Colors.white, size: 22),
            onPressed: widget.onTap,
            tooltip: 'Alarm Berbunyi!',
          ),
        ),
      ),
    );
  }
}
