import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/providers/insights_provider.dart';

class TrendCard extends ConsumerWidget {
  const TrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(costPerKmTrendProvider);

    if (trend.isEmpty) {
      return Center(
        child: Text(
          'Save more trips to see trends',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    final maxVal = trend.fold<double>(
        0, (max, p) => p.value > max ? p.value : max);
    final minVal = trend.fold<double>(
        double.infinity, (min, p) => p.value < min ? p.value : min);

    return LineChart(
      LineChartData(
        minY: (minVal * 0.8).clamp(0, double.infinity),
        maxY: maxVal * 1.2,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  '₹${spot.y.toStringAsFixed(1)}/km',
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxVal - minVal) > 0 ? (maxVal - minVal) / 3 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(trend.length, (i) {
              return FlSpot(i.toDouble(), trend[i].value);
            }),
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.accent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.surface,
                  strokeWidth: 2.5,
                  strokeColor: AppColors.accent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.2),
                  AppColors.accent.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
