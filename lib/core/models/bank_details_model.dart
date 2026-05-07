class BankDetailsModel {
  final String userId;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final DateTime createdAt;

  BankDetailsModel({
    required this.userId,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.createdAt,
  });

  factory BankDetailsModel.fromJson(Map<String, dynamic> json) {
    return BankDetailsModel(
      userId: json['user_id'],
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      ifscCode: json['ifsc_code'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
    };
  }
}
