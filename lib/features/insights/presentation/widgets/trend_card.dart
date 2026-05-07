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
      return _buildEmptyState();
    }

    final maxVal = trend.fold<double>(0, (max, p) => p.value > max ? p.value : max);
    final minVal = trend.fold<double>(double.infinity, (min, p) => p.value < min ? p.value : min);

    return LineChart(
      LineChartData(
        // Add padding to chart edges
        minY: (minVal * 0.9).clamp(0, double.infinity),
        maxY: maxVal * 1.1,
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => const Color(0xFF1A1A1A), // Dark Premium Tooltip
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (spots) {
              return spots.map((spot) {
                return LineTooltipItem(
                  '₹${spot.y.toStringAsFixed(2)}/km',
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxVal - minVal) > 0 ? (maxVal - minVal) / 2 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textTertiary.withOpacity(0.05),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '₹${value.toStringAsFixed(1)}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary.withOpacity(0.6),
                    ),
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
            curveSmoothness: 0.4,
            // Gradient for the line itself
            gradient: LinearGradient(
              colors: [
                AppColors.accent,
                AppColors.accent.withOpacity(0.7),
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            // Only show dots for first and last or during touch for clean look
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: AppColors.accent,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.25),
                  AppColors.accent.withOpacity(0.05),
                  AppColors.accent.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph_rounded, size: 32, color: AppColors.textTertiary.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'Save more trips to see trends',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}