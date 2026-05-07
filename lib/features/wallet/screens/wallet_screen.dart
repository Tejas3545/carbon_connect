import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/wallet_service.dart';
// import '../../../core/models/wallet_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String get userId => Supabase.instance.client.auth.currentUser?.id ?? '';
  bool _isLoading = false;

  void _deposit() async {
    // This is where Razorpay integration happens
    // _razorpay.open({'amount': 50000});
    // On success:
    setState(() => _isLoading = true);
    try {
      await ref.read(walletServiceProvider).depositInr(
          userId, 500.0, 'txn_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deposit Successful via Razorpay')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Deposit Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _withdraw() async {
    setState(() => _isLoading = true);
    try {
      final amount = 500.0; // Simulated withdrawal amount
      final currentWallet = await Supabase.instance.client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .single();
      
      if (currentWallet['inr_balance'] < amount) {
        throw Exception('Insufficient balance for withdrawal');
      }

      await Supabase.instance.client.from('wallets').update({
        'inr_balance': currentWallet['inr_balance'] - amount,
      }).eq('user_id', userId);

      await Supabase.instance.client.from('transactions').insert({
        'user_id': userId,
        'type': 'WITHDRAWAL',
        'amount': amount,
        'description': 'Withdrawal to linked bank account',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Withdrawal Successful')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Withdrawal Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet'), centerTitle: true),
      body: walletAsync.when(
        data: (wallet) {
          if (wallet == null) {
            return const Center(child: Text('No wallet found.'));
          }
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BalanceCard(
                  title: 'INR Balance',
                  balance: '₹${wallet.inrBalance.toStringAsFixed(2)}',
                  color: Colors.blueAccent,
                  icon: Icons.account_balance_wallet,
                ),
                const SizedBox(height: 16),
                _BalanceCard(
                  title: 'Carbon Credits (CCC)',
                  balance: '${wallet.cccBalance} CCC',
                  color: const Color(0xFF00D4AA),
                  icon: Icons.eco,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D4AA)),
                        onPressed: _isLoading ? null : _deposit,
                        icon: const Icon(Icons.add),
                        label: const Text('DEPOSIT'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2D42)),
                        onPressed: _withdraw,
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('WITHDRAW'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Transaction History',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ref.watch(transactionsProvider).when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                          child: Text('No recent transactions',
                              style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final isDeposit = tx['type'] == 'DEPOSIT';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isDeposit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            child: Icon(
                              isDeposit ? Icons.add : Icons.remove,
                              color: isDeposit ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(tx['type'] ?? 'Transaction'),
                          subtitle: Text(tx['description'] ?? ''),
                          trailing: Text(
                            '${isDeposit ? "+" : "-"}₹${tx['amount']}',
                            style: TextStyle(
                              color: isDeposit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, __) => Text('Error loading history: $e'),
                ),

              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final String balance;
  final Color color;
  final IconData icon;

  const _BalanceCard({
    required this.title,
    required this.balance,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
              const SizedBox(height: 4),
              Text(balance,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
