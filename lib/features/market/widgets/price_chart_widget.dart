import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
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

        // Group trades by an arbitrary time slice (e.g., a day or hour). 
        // For visual sake on limited data, let's group by 1-hour intervals.
        final map = <int, List<double>>{};
        final volumes = <int, double>{};
        
        for (var t in trades) {
          // Flatten to hour precision
          final dt = DateTime(t.executedAt.year, t.executedAt.month, t.executedAt.day, t.executedAt.hour);
          final ms = dt.millisecondsSinceEpoch;
          
          if (!map.containsKey(ms)) {
            map[ms] = [];
            volumes[ms] = 0;
          }
          map[ms]!.add(t.price);
          volumes[ms] = volumes[ms]! + t.quantity;
        }

        final candles = <Candle>[];
        final sortedKeys = map.keys.toList()..sort();
        for (var ms in sortedKeys) {
          final prices = map[ms]!;
          if (prices.isEmpty) continue;
          
          final date = DateTime.fromMillisecondsSinceEpoch(ms);
          final open = prices.first; // Note: trades might need sorting inside the group for accurate open/close
          final close = prices.last;
          final high = prices.reduce((a, b) => a > b ? a : b);
          final low = prices.reduce((a, b) => a < b ? a : b);
          final volume = volumes[ms] ?? 0.0;
          
          candles.add(Candle(
            date: date,
            high: high,
            low: low,
            open: open,
            close: close,
            volume: volume,
          ));
        }

        // Candlesticks package requires the list to be reversed for showing the latest on the right
        final reversedCandles = candles.reversed.toList();

        return SizedBox(
          height: 250,
          child: Theme(
            data: ThemeData.dark().copyWith(
              cardColor: const Color(0xFF0F172A),
            ),
            child: Candlesticks(
              candles: reversedCandles,
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SizedBox(height: 250, child: Center(child: Text('Chart Error: $e'))),
    );
  }
}
