import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';

class PriceChartWidget extends ConsumerWidget {
  const PriceChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tradesAsync = ref.watch(recentTradesProvider);

    return tradesAsync.when(
      data: (trades) {
        if (trades.isEmpty) {
          return const SizedBox(
            height: 250,
            child: Center(child: Text('No trades yet today', style: TextStyle(color: Color(0xFF94A3B8)))),
          );
        }

        // Convert trades to spots. X-axis: time (relative), Y-axis: price
        // For simplicity, we use index as X
        final spots = trades.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.price);
        }).toList().reversed.toList(); // Reverse to show chronological order if sorted desc

        final minPrice = trades.map((t) => t.price).reduce((a, b) => a < b ? a : b);
        final maxPrice = trades.map((t) => t.price).reduce((a, b) => a > b ? a : b);
        final padding = (maxPrice - minPrice) * 0.2;

        return SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: const Color(0xFF0A1628).withValues(alpha: 0.5),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: const FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide time for now
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minY: minPrice - padding,
              maxY: maxPrice + padding,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF00D4AA),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 250, child: Center(child: Text('Chart Error: $e'))),
    );
  }
}
