import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final tradesAsync = ref.watch(tradeHistoryProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio'), centerTitle: true),
      body: tradesAsync.when(
        data: (trades) {
          if (trades.isEmpty) {
            return const Center(child: Text('No trades executed yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trades.length,
            itemBuilder: (context, index) {
              final trade = trades[index];
              final isBuyer = trade.buyerId == userId;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBuyer ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2),
                    child: Icon(
                      isBuyer ? Icons.call_received : Icons.call_made,
                      color: isBuyer ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                    ),
                  ),
                  title: Text(isBuyer ? 'BOUGHT CCC' : 'SOLD CCC', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(trade.executedAt)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${trade.quantity} CCC', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₹${(trade.price * trade.quantity).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading portfolio: $e')),
      ),
    );
  }
}
