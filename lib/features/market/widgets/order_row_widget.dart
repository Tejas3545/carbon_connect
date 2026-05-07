import 'package:flutter/material.dart';

class OrderRowWidget extends StatelessWidget {
  final double price;
  final int quantity;
  final Color color;

  const OrderRowWidget({
    super.key,
    required this.price,
    required this.quantity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            price.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            quantity.toString(),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
