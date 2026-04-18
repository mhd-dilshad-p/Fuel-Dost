import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../expense_tracker/domain/providers/expense_provider.dart';

class SpendingChart extends ConsumerWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(monthlySpendingHistoryProvider);

    if (history.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxSpending = history.fold<double>(
      0,
      (max, item) => item.totalSpending > max ? item.totalSpending : max,
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxSpending > 0 ? maxSpending * 1.2 : 1000,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = history[group.x.toInt()];
              return BarTooltipItem(
                '${Formatters.shortMonth(data.date)}\n₹${data.totalSpending.toStringAsFixed(0)}',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}k',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= history.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    Formatters.shortMonth(history[index].date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxSpending > 0 ? maxSpending / 4 : 250,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(history.length, (index) {
          final data = history[index];
          final isCurrentMonth = index == history.length - 1;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.totalSpending,
                gradient: LinearGradient(
                  colors: isCurrentMonth
                      ? [AppColors.accent, AppColors.accentLight]
                      : [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 28,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
