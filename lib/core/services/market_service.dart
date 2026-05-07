import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/trade_model.dart';
import 'config/api_config.dart';

class MarketService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio();

  Future<double> getLiveCarbonPrice() async {
    try {
      final response = await _dio.get('${ApiConfig.carbonmarkBaseUrl}/prices');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final bctData = data.firstWhere(
          (item) => item['id'].toString().toLowerCase() == 'bct',
          orElse: () => data.isNotEmpty ? data[0] : null,
        );

        if (bctData != null) {
          double priceInUsd = double.parse(bctData['price'].toString());
          double usdToInr = 83.50; 
          return priceInUsd * usdToInr;
        }
      }
      return 840.0; // Default fallback price
    } catch (e) {
      debugPrint('Error fetching price: $e');
      return 840.0;
    }
  }

  // Stream for the last trade to get Last Traded Price (LTP)
  Stream<TradeModel?> streamLastTrade() {
    return _supabase
        .from('trades')
        .stream(primaryKey: ['id'])
        .order('executed_at', ascending: false)
        .limit(1)
        .map((event) {
      if (event.isEmpty) return null;
      return TradeModel.fromJson(event.first);
    });
  }

  // Stream for recent trades (for the chart/history)
  Stream<List<TradeModel>> streamRecentTrades() {
    return _supabase
        .from('trades')
        .stream(primaryKey: ['id'])
        .order('executed_at', ascending: false)
        .limit(50)
        .map((event) {
      return event.map((e) => TradeModel.fromJson(e)).toList();
    });
  }

  // Fetch market stats (change %, high, low)
  Future<Map<String, dynamic>> getMarketStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final response = await _supabase
          .from('trades')
          .select('price')
          .gte('executed_at', startOfDay.toIso8601String());

      if (response.isEmpty) {
        return {'change': 0.0, 'high': 0.0, 'low': 0.0};
      }

      final prices = response.map((r) => double.parse(r['price'].toString())).toList();
      final high = prices.reduce((a, b) => a > b ? a : b);
      final low = prices.reduce((a, b) => a < b ? a : b);
      
      final firstTrade = response.first;
      final openPrice = double.parse(firstTrade['price'].toString());
      final lastPrice = prices.last;
      
      final change = ((lastPrice - openPrice) / openPrice) * 100;

      return {
        'change': change,
        'high': high,
        'low': low,
      };
    } catch (e) {
      return {'change': 0.0, 'high': 0.0, 'low': 0.0};
    }
  }
}
