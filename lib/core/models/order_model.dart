class OrderModel {
  final String id;
  final String userId;
  final String type; // 'BUY' or 'SELL'
  final double price;
  final int quantity;
  final String status; // 'OPEN', 'MATCHED', 'CANCELLED'
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.price,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'],
      status: json['status'] ?? 'OPEN',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'price': price,
      'quantity': quantity,
      'status': status,
    };
  }
}
