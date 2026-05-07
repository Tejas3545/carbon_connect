class TradeModel {
  final String id;
  final String buyOrderId;
  final String sellOrderId;
  final String buyerId;
  final String sellerId;
  final double price;
  final int quantity;
  final DateTime executedAt;

  TradeModel({
    required this.id,
    required this.buyOrderId,
    required this.sellOrderId,
    required this.buyerId,
    required this.sellerId,
    required this.price,
    required this.quantity,
    required this.executedAt,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      id: json['id'],
      buyOrderId: json['buy_order_id'],
      sellOrderId: json['sell_order_id'],
      buyerId: json['buyer_id'],
      sellerId: json['seller_id'],
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      executedAt: DateTime.parse(json['executed_at']),
    );
  }
}
