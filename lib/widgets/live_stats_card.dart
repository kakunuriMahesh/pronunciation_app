import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LiveStatsHeader extends StatelessWidget {
  final int correct;
  final int wrong;
  final int remaining;

  const LiveStatsHeader({
    super.key,
    required this.correct,
    required this.wrong,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = correct + wrong + remaining;
    final progress = total > 0 ? correct / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Correct',
                value: correct.toString(),
                color: AppColors.successGreen,
                icon: Icons.check_circle_outline,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
               ),
               _StatItem(
                 label: 'Wrong',
                 value: wrong.toString(),
                 color: AppColors.errorRed,
                 icon: Icons.cancel_outlined,
               ),
               Container(
                 width: 1,
                 height: 40,
                 color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
               ),
               _StatItem(
                 label: 'Left',
                 value: remaining.toString(),
                 color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                icon: Icons.hourglass_empty,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
               valueColor: AlwaysStoppedAnimation<Color>(
                 progress >= 0.8
                     ? AppColors.successGreen
                     : progress >= 0.5
                         ? AppColors.warningOrange
                         : AppColors.primaryBlue,
               ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% Complete',
             style: TextStyle(
               color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
               fontSize: 13,
               fontWeight: FontWeight.w500,
             ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}