import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/order_service.dart';
import '../../../core/models/order_model.dart';

final orderService = Provider((ref) => OrderService());

final orderBookProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.read(orderService).streamOrderBook();
});

// Derived provider to separate BIDS (Buy orders) and ASKS (Sell orders)
final bidsProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(orderBookProvider).value ?? [];
  final bids = orders.where((o) => o.type == 'BUY').toList();
  // Sort BIDS descending by price
  bids.sort((a, b) => b.price.compareTo(a.price));
  return bids;
});

final asksProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(orderBookProvider).value ?? [];
  final asks = orders.where((o) => o.type == 'SELL').toList();
  // Sort ASKS ascending by price
  asks.sort((a, b) => a.price.compareTo(b.price));
  return asks;
});
