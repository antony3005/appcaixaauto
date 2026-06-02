class OrderModel {
  final String orderId;
  final double total;
  final String status;
  final DateTime? createdAt;

  final double? subtotal;
  final double? desconto;

  OrderModel({
    required this.orderId,
    required this.total,
    required this.status,
    this.createdAt,
    this.desconto,
    this.subtotal,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      desconto: (json['desconto'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'total': total,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'subtotal': total,
      'desconto': desconto,
    };
  }
}
