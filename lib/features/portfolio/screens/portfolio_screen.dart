import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final tradesAsync = ref.watch(tradeHistoryProvider(userId));
    final walletAsync = ref.watch(walletStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('Portfolio & Impact', style: GoogleFonts.outfit(color: Colors.white)), 
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: CustomScrollView(
        slivers: [
          // Impact Dashboard
          SliverToBoxAdapter(
            child: walletAsync.when(
              data: (wallet) {
                final balance = wallet?.cccBalance ?? 0;
                // 1 CCC = 1 Tonne = ~45 trees planted
                final trees = (balance * 45).toInt();
                
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Impact Dashboard',
                        style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ImpactStat(
                            icon: Icons.co2,
                            value: '$balance Tonnes',
                            label: 'Offset',
                          ),
                          _ImpactStat(
                            icon: Icons.park,
                            value: '$trees Trees',
                            label: 'Equivalent',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
              error: (e, st) => const SizedBox(),
            ),
          ),
          
          // P&L and Portfolio Carbon Score etc. could go here...

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Trade History',
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          tradesAsync.when(
            data: (trades) {
              if (trades.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No trades executed yet.', style: TextStyle(color: Colors.white70))),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trade = trades[index];
                    final isBuyer = trade.buyerId == userId;
                    
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBuyer ? const Color(0xFF22C55E).withValues(alpha: 0.2) : const Color(0xFFEF4444).withValues(alpha: 0.2),
                          child: Icon(
                            isBuyer ? Icons.call_received : Icons.call_made,
                            color: isBuyer ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          ),
                        ),
                        title: Text(isBuyer ? 'BOUGHT CCC' : 'SOLD CCC', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(trade.executedAt), style: const TextStyle(color: Colors.white54)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${trade.quantity} CCC', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            Text('₹${(trade.price * trade.quantity).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: trades.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error loading portfolio: $e', style: const TextStyle(color: Colors.red)))),
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImpactStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
