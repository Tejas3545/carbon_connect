import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/trade_model.dart';
import '../../../core/models/order_model.dart';

final userOrdersProvider = StreamProvider.family<List<OrderModel>, String>((ref, userId) {
  return Supabase.instance.client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((event) => event.map((e) => OrderModel.fromJson(e)).toList());
});

final tradeHistoryProvider = StreamProvider.family<List<TradeModel>, String>((ref, userId) {
  return Supabase.instance.client
      .from('trades')
      .stream(primaryKey: ['id'])
      .map((event) => event
          .where((e) => e['buyer_id'] == userId || e['seller_id'] == userId)
          .map((e) => TradeModel.fromJson(e))
          .toList());
});
