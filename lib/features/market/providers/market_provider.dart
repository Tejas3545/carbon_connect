import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/market_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/models/trade_model.dart';
import '../../../core/models/order_model.dart';

final marketServiceProvider = Provider((ref) => MarketService());
final orderServiceProvider = Provider((ref) => OrderService());

final livePriceProvider = StreamProvider<double>((ref) async* {
  final service = ref.read(marketServiceProvider);
  while (true) {
    yield await service.getLiveCarbonPrice();
    await Future.delayed(const Duration(seconds: 30));
  }
});

final lastTradeProvider = StreamProvider<TradeModel?>((ref) {
  return ref.read(marketServiceProvider).streamLastTrade();
});

final recentTradesProvider = StreamProvider<List<TradeModel>>((ref) {
  return ref.read(marketServiceProvider).streamRecentTrades();
});

final marketStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  // We refresh stats when a new trade occurs
  ref.watch(lastTradeProvider); 
  return ref.read(marketServiceProvider).getMarketStats();
});

final orderBookProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.read(orderServiceProvider).streamOrderBook();
});
