// ============ FILE: mobile_app/lib/widgets/reminder_card.dart ============
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/reminder.dart';
import '../utils/helpers.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggle;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isActive ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Clock icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: reminder.isActive
                    ? AppTheme.primary.withOpacity(0.1)
                    : AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.alarm,
                color: reminder.isActive ? AppTheme.primary : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reminder.timeShort,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          fontFamily: 'monospace',
                          color: reminder.isActive ? AppTheme.textPrimary : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (reminder.medicationName != null)
                        Expanded(
                          child: Text(
                            reminder.medicationName!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: reminder.daysOfWeek.map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          Helpers.dayLabels[day] ?? day,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Toggle + Delete
            Column(
              children: [
                if (onToggle != null)
                  SizedBox(
                    height: 28,
                    child: Switch(
                      value: reminder.isActive,
                      onChanged: onToggle,
                      activeColor: AppTheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
