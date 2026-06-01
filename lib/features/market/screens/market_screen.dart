import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/market_provider.dart';
import '../widgets/price_chart_widget.dart';
import '../widgets/place_order_sheet.dart';
import '../widgets/order_book_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  void _showPlaceOrderSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PlaceOrderSheet(orderType: type),
    );
  }

  void _showPriceAlertSheet(BuildContext context, double currentPrice) {
    final targetPriceController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Price Alert',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Current Price: ₹${currentPrice.toStringAsFixed(2)}',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Target Price (₹)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final target = double.tryParse(targetPriceController.text);
                  if (target != null && target > 0) {
                    try {
                      final userId = Supabase.instance.client.auth.currentUser?.id;
                      if (userId != null) {
                        /* 
                         Assuming backend has `price_alerts` table:
                         await Supabase.instance.client.from('price_alerts').insert({
                           'user_id': userId,
                           'target_price': target,
                           'symbol': 'BCT',
                           'status': 'active'
                         });
                        */
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Price alert set for BCT crossing ₹$target', style: const TextStyle(color: Colors.white)),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Add Alert', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livePriceAsync = ref.watch(livePriceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon Exchange'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () {
              final val = livePriceAsync.valueOrNull ?? 0.0;
              _showPriceAlertSheet(context, val);
            },
            tooltip: 'Set Price Alert',
          ),
        ],
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

