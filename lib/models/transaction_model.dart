class Transaction {
  final int id;
  final int userId;
  final int sellerId;
  final int? serviceId;
  final double amount;
  final String? type;
  final String? description;
  final double cashbackEarned;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.sellerId,
    this.serviceId,
    required this.amount,
    this.type,
    this.description,
    required this.cashbackEarned,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      sellerId: json['seller_id'],
      serviceId: json['service_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'],
      description: json['description'] ?? json['service_description'],
      cashbackEarned: (json['cashback_earned'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'seller_id': sellerId,
      'service_id': serviceId,
      'amount': amount,
      'type': type,
      'description': description,
      'cashback_earned': cashbackEarned,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
