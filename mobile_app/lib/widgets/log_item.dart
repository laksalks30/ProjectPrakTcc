// ============ FILE: mobile_app/lib/widgets/log_item.dart ============
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/medication_log.dart';
import '../utils/helpers.dart';

class LogItem extends StatelessWidget {
  final MedicationLog log;

  const LogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final isTaken = log.status == 'taken';
    final isMissed = log.status == 'missed';

    final Color statusColor = isTaken
        ? AppTheme.success
        : isMissed
            ? AppTheme.error
            : AppTheme.warning;

    final IconData statusIcon = isTaken
        ? Icons.check_circle
        : isMissed
            ? Icons.cancel
            : Icons.access_time;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Status Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.medicationName ?? 'Obat',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Jadwal: ${Helpers.formatDateTime(log.scheduledAt)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  if (log.takenAt != null) ...[
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        Icon(Icons.done_all, size: 12, color: AppTheme.success),
                        const SizedBox(width: 4),
                        Text(
                          'Diminum: ${Helpers.formatDateTime(log.takenAt)}',
                          style: TextStyle(fontSize: 11, color: AppTheme.success),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                log.statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
