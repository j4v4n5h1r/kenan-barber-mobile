class Service {
  final int id;
  final String name;
  final double price;
  final double cashbackPercentage;
  final int sellerId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.cashbackPercentage,
    required this.sellerId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      price: (json['price'] ?? 0).toDouble(),
      cashbackPercentage: (json['cashback_percentage'] ?? 0).toDouble(),
      sellerId: json['seller_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'cashback_percentage': cashbackPercentage,
      'seller_id': sellerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
