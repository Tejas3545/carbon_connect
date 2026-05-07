class WalletModel {
  final String userId;
  final double inrBalance;
  final int cccBalance;
  final DateTime updatedAt;

  WalletModel({
    required this.userId,
    required this.inrBalance,
    required this.cccBalance,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['user_id'],
      inrBalance: double.parse(json['inr_balance'].toString()),
      cccBalance: json['ccc_balance'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'inr_balance': inrBalance,
      'ccc_balance': cccBalance,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
