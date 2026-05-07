import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream for Realtime Order Book Updates
  Stream<List<OrderModel>> streamOrderBook() {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'OPEN')
        .map((event) {
          return event.map((e) => OrderModel.fromJson(e)).toList();
        });
  }

  Future<void> placeOrder({
    required String type, // 'BUY' or 'SELL'
    required double price,
    required int quantity,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // 1. Check if user has enough balance
    final walletResponse = await _supabase.from('wallets').select().eq('user_id', user.id).single();
    if (type == 'BUY') {
      final totalCost = price * quantity;
      if (walletResponse['inr_balance'] < totalCost) {
        throw Exception('Insufficient INR balance');
      }
    } else {
      if (walletResponse['ccc_balance'] < quantity) {
        throw Exception('Insufficient CCC balance');
      }
    }

    // 2. Insert the order
    final orderData = await _supabase.from('orders').insert({
      'user_id': user.id,
      'type': type,
      'price': price,
      'quantity': quantity,
      'status': 'OPEN',
    }).select().single();

    final orderId = orderData['id'];

    // 3. Attempt Matching
    try {
      final matchType = type == 'BUY' ? 'SELL' : 'BUY';
      final query = _supabase
          .from('orders')
          .select()
          .eq('type', matchType)
          .eq('status', 'OPEN')
          .gte('quantity', quantity); // Match if they have enough quantity

      if (type == 'BUY') {
        query.lte('price', price);
      } else {
        query.gte('price', price);
      }

      final matches = await query.order('created_at', ascending: true).limit(1);

      if (matches.isNotEmpty) {
        final match = matches.first;
        final matchId = match['id'];
        final matchUserId = match['user_id'];
        final tradePrice = match['price'].toDouble();

        // 4. Create Trade
        await _supabase.from('trades').insert({
          'buy_order_id': type == 'BUY' ? orderId : matchId,
          'sell_order_id': type == 'BUY' ? matchId : orderId,
          'buyer_id': type == 'BUY' ? user.id : matchUserId,
          'seller_id': type == 'BUY' ? matchUserId : user.id,
          'price': tradePrice,
          'quantity': quantity,
        });

        // 5. Update Orders
        await _supabase.from('orders').update({'status': 'MATCHED'}).inFilter('id', [orderId, matchId]);

        // 6. Update Wallets
        final totalValue = tradePrice * quantity;
        
        // Buyer updates
        final buyerId = type == 'BUY' ? user.id : matchUserId;
        final buyerWallet = await _supabase.from('wallets').select().eq('user_id', buyerId).single();
        await _supabase.from('wallets').update({
          'inr_balance': buyerWallet['inr_balance'] - totalValue,
          'ccc_balance': buyerWallet['ccc_balance'] + quantity,
        }).eq('user_id', buyerId);

        // Seller updates
        final sellerId = type == 'BUY' ? matchUserId : user.id;
        final sellerWallet = await _supabase.from('wallets').select().eq('user_id', sellerId).single();
        await _supabase.from('wallets').update({
          'inr_balance': sellerWallet['inr_balance'] + totalValue,
          'ccc_balance': sellerWallet['ccc_balance'] - quantity,
        }).eq('user_id', sellerId);

        // 7. Log Transactions
        await _supabase.from('transactions').insert([
          {
            'user_id': buyerId,
            'type': 'TRADE_DEBIT',
            'amount': totalValue,
            'description': 'Bought $quantity CCC at ₹$tradePrice',
          },
          {
            'user_id': sellerId,
            'type': 'TRADE_CREDIT',
            'amount': totalValue,
            'description': 'Sold $quantity CCC at ₹$tradePrice',
          }
        ]);
      }
    } catch (e) {
      // If matching fails, the order is still OPEN
      debugPrint('Matching error: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    await _supabase.from('orders').update({
      'status': 'CANCELLED',
    }).eq('id', orderId);
  }
}
