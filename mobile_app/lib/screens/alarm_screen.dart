import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../config/app_theme.dart';
import '../services/notification_service.dart';

class AlarmScreen extends StatefulWidget {
  final String patientName;
  final String medicationName;
  final String dosage;
  final String time;
  final int reminderId;

  const AlarmScreen({
    super.key,
    required this.patientName,
    required this.medicationName,
    required this.dosage,
    required this.time,
    required this.reminderId,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    HapticFeedback.heavyImpact();

    _autoCloseTimer = Timer(const Duration(minutes: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _snooze() async {
    await NotificationService.scheduleInMinutes(
      id: widget.reminderId + 90000,
      minutes: 5,
      title: 'Pengingat Obat (Tunda)',
      body: '${widget.patientName} — ${widget.medicationName} (${widget.dosage})\nJadwal: ${widget.time}',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alarm ditunda 5 menit'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop('snoozed');
    }
  }

  void _dismiss() {
    Navigator.of(context).pop('dismissed');
  }

  void _markTaken() {
    Navigator.of(context).pop('taken');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppTheme.gradientBg),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.alarm, color: Colors.white, size: 60),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    'Waktunya Minum Obat!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.time,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pasien',
                                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                                  ),
                                  Text(
                                    widget.patientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Colors.white.withOpacity(0.15), height: 1),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.medication, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Obat',
                                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                                  ),
                                  Text(
                                    widget.medicationName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (widget.dosage.isNotEmpty)
                                    Text(
                                      'Dosis: ${widget.dosage}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _markTaken,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text('Sudah Diminum', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _snooze,
                            icon: const Icon(Icons.snooze, size: 20),
                            label: const Text('Tunda 5 Menit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _dismiss,
                            icon: const Icon(Icons.close, size: 20),
                            label: const Text('Tutup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white.withOpacity(0.7),
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
