import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/market_provider.dart';

class PlaceOrderSheet extends ConsumerStatefulWidget {
  final String orderType; // 'BUY' or 'SELL'

  const PlaceOrderSheet({super.key, required this.orderType});

  @override
  ConsumerState<PlaceOrderSheet> createState() => _PlaceOrderSheetState();
}

class _PlaceOrderSheetState extends ConsumerState<PlaceOrderSheet> {
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    final price = double.tryParse(_priceController.text);
    final quantity = int.tryParse(_quantityController.text);

    if (price == null || quantity == null || price <= 0 || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid price and quantity')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(orderServiceProvider).placeOrder(
            type: widget.orderType,
            price: price,
            quantity: quantity,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.orderType} Order Placed Successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.orderType == 'BUY';
    final color = isBuy ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Place ${widget.orderType} Order',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price (INR)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity (CCC)',
              prefixIcon: Icon(Icons.eco),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: _isLoading ? null : _submitOrder,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('CONFIRM ${widget.orderType}'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
