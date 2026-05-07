class UserModel {
  final String id;
  final String? fullName;
  final String? email;
  final String? location;
  final String? phone;
  final String? role;
  final String kycStatus;
  final DateTime createdAt;

  UserModel({
    required this.id,
    this.fullName,
    this.email,
    this.location,
    this.phone,
    this.role,
    required this.kycStatus,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      location: json['location'],
      phone: json['phone'],
      role: json['role'],
      kycStatus: json['kyc_status'] ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'location': location,
      'phone': phone,
      'role': role,
      'kyc_status': kycStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
