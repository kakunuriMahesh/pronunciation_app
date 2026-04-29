import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../providers/reading_provider.dart';

class ReadingChart extends StatelessWidget {
  final ReadingProvider provider;

  const ReadingChart({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final result = provider.result;
    if (result == null) return const SizedBox.shrink();

    final usedTime = result.usedTime;
    if (usedTime == 0) return const SizedBox.shrink();

    final spots1 = <FlSpot>[];
    final spots2 = <FlSpot>[];

    for (int i = 0; i <= usedTime; i++) {
      final progress = (i / usedTime * result.completionScore).clamp(0, 100).toDouble();
      spots1.add(FlSpot(i.toDouble(), progress));
      
      final speed = (result.wpm * (0.8 + (i % 10) / 20)).clamp(0, 100).toDouble();
      spots2.add(FlSpot(i.toDouble(), speed));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.show_chart,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Reading Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 25,
                  verticalInterval: usedTime > 20 ? 5 : 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: usedTime > 20 ? 5 : 2,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${value.toInt()}s',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                minX: 0,
                maxX: usedTime.toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots1,
                    isCurved: true,
                    color: AppColors.successGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.successGreen.withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: spots2,
                    isCurved: true,
                    color: AppColors.primaryBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          if (provider.pauseEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPauseSummary(provider.pauseEvents),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppColors.successGreen,
          label: 'Progress',
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: AppColors.primaryBlue,
          label: 'Speed',
          isDashed: true,
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: AppColors.errorRed,
          label: 'Mistakes',
        ),
      ],
    );
  }

  Widget _buildPauseSummary(List<PauseEvent> pauseEvents) {
    final totalPauses = pauseEvents.length;
    final totalPauseTime = pauseEvents.fold<int>(
      0,
      (sum, event) => sum + event.durationMs,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pause_circle_outline,
            color: AppColors.warningOrange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$totalPauses pauses (${(totalPauseTime / 1000).toStringAsFixed(1)}s total)',
            style: const TextStyle(
              color: AppColors.warningOrange,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (isDashed) ...[
          const SizedBox(width: 2),
          Container(
            width: 4,
            height: 3,
            color: Colors.transparent,
          ),
          Container(
            width: 8,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 6),
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
