class User {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String role;
  final double balance;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.role,
    required this.balance,
    this.qrCode,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'] ?? json['username'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'] ?? json['phone'],
      role: json['role'],
      balance: (json['cashback_balance'] ?? json['balance'] ?? 0).toDouble(),
      qrCode: json['qr_code'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'cashback_balance': balance,
      'qr_code': qrCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
