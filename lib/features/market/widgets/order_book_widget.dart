import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/market_provider.dart';

class OrderBookWidget extends ConsumerWidget {
  const OrderBookWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderBookAsync = ref.watch(orderBookProvider);

    return orderBookAsync.when(
      data: (orders) {
        final buyOrders = orders.where((o) => o.type == 'BUY').toList()
          ..sort((a, b) => b.price.compareTo(a.price));
        final sellOrders = orders.where((o) => o.type == 'SELL').toList()
          ..sort((a, b) => a.price.compareTo(b.price));

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buy Side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUY ORDERS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (buyOrders.isEmpty)
                    const Text('No buy orders', style: TextStyle(color: Colors.white24, fontSize: 12))
                  else
                    ...buyOrders.take(10).map((o) => _buildOrderRow(o, const Color(0xFF10B981))),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Sell Side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELL ORDERS',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sellOrders.isEmpty)
                    const Text('No sell orders', style: TextStyle(color: Colors.white24, fontSize: 12))
                  else
                    ...sellOrders.take(10).map((o) => _buildOrderRow(o, const Color(0xFFEF4444))),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading order book', style: TextStyle(color: Colors.red)),
    );
  }

  Widget _buildOrderRow(dynamic order, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '₹${order.price.toStringAsFixed(1)}',
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            '${order.quantity}',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
