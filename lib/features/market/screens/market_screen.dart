import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';
import '../widgets/price_chart_widget.dart';
import '../widgets/place_order_sheet.dart';
import '../widgets/order_book_widget.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  void _showPlaceOrderSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PlaceOrderSheet(orderType: type),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livePriceAsync = ref.watch(livePriceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon Exchange'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Market Sentiment / Live Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1E2D42), const Color(0xFF1E2D42).withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BCT Benchmark', style: TextStyle(color: Color(0xFF94A3B8))),
                      livePriceAsync.when(
                        data: (price) => Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                        loading: () => const Text('...', style: TextStyle(fontSize: 28)),
                        error: (_, __) => const Text('Unavailable'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text('LIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Performance Chart
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Performance Index', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(height: 180, child: PriceChartWidget()),
            ),

            const SizedBox(height: 24),

            // Order Book
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Order Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: OrderBookWidget(),
            ),

            const SizedBox(height: 120), // Space for FABs
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'buy_btn',
                onPressed: () => _showPlaceOrderSheet(context, 'BUY'),
                label: const Text('BUY CCC', style: TextStyle(fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.add_shopping_cart),
                backgroundColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'sell_btn',
                onPressed: () => _showPlaceOrderSheet(context, 'SELL'),
                label: const Text('SELL CCC', style: TextStyle(fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.sell),
                backgroundColor: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

