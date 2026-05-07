import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/models/wallet_model.dart';
export '../../../core/models/wallet_model.dart';


final walletStreamProvider = StreamProvider<WalletModel?>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(null);
  
  return ref.read(walletServiceProvider).streamWalletBalance(userId);
});

// A provider to get the full wallet model
final balanceProvider = Provider<AsyncValue<WalletModel?>>((ref) {
  return ref.watch(walletStreamProvider);
});

final transactionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);
  
  return Supabase.instance.client
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((event) => event);
});

