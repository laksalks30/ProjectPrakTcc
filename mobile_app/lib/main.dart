import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/alarm_screen.dart';

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

class ObatLansiaApp extends StatefulWidget {
  const ObatLansiaApp({super.key});

  @override
  State<ObatLansiaApp> createState() => _ObatLansiaAppState();
}

class _ObatLansiaAppState extends State<ObatLansiaApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.onNotificationTapped = _handleNotificationTap;
  }

  void _handleNotificationTap(String payload) {
    final parts = payload.split('|');
    if (parts.isEmpty || parts[0] != 'reminder') return;

    final reminderId = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final patientName = parts.length > 2 ? parts[2] : 'Pasien';
    final medicationName = parts.length > 3 ? parts[3] : 'Obat';
    final dosage = parts.length > 4 ? parts[4] : '';
    final time = parts.length > 5 ? parts[5] : '';

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
  }

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

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  /// Exposed for child widgets to change tab
  void setTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: false,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, size: 22),
              onPressed: () {
                setState(() {});
              },
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Lansia'),
            BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminder'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Log'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  static const _titles = ['Dashboard', 'Data Lansia', 'Jadwal Reminder', 'Riwayat Log', 'Profil Saya'];
}
