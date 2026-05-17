enum CarrinhoStatus { OPEN, CLOSED, CANCELED }

enum ItemStatus { VALIDATED, PENDING, CANCELED }

class Carrinho {
  final String carrinhoId;
  final List<Item> items;
  final String terminalId;
  final CarrinhoStatus status;
  final double subtotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Carrinho({
    required this.carrinhoId,
    required this.items,
    required this.terminalId,
    required this.status,
    required this.subtotal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Carrinho.fromJson(Map<String, dynamic> json) {
    return Carrinho(
      carrinhoId: json['carrinhoId'],
      items: (json['items'] as List).map((e) => Item.fromJson(e)).toList(),
      terminalId: json['terminalId'],
      status: CarrinhoStatus.values.firstWhere((e) => e.name == json['status']),
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carrinhoId': carrinhoId,
      'items': items.map((e) => e.toJson()).toList(),
      'terminalId': terminalId,
      'status': status.name,
      'subtotal': subtotal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Item {
  final String itemId;
  final String? carrinhoId;
  final int productId;
  final String barcode;
  final String name;
  final String foto;
  final double unitPrice;
  final int quantity;
  final bool requiresWeight;
  final double? expectedWeight;
  final double? receivedWeight;
  final ItemStatus status;

  Item({
    required this.itemId,
    required this.carrinhoId,
    required this.productId,
    required this.barcode,
    required this.name,
    required this.foto,
    required this.unitPrice,
    required this.quantity,
    required this.requiresWeight,
    this.expectedWeight,
    this.receivedWeight,
    required this.status,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['itemId'],
      carrinhoId: json['carrinho']?['carrinhoId'],
      productId: json['productId'],
      barcode: json['barcode'],
      name: json['name'],
      foto: json['foto'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'],
      requiresWeight: json['requiresWeight'],
      expectedWeight: json['expectedWeight'] != null
          ? (json['expectedWeight'] as num).toDouble()
          : null,
      receivedWeight: json['receivedWeight'] != null
          ? (json['receivedWeight'] as num).toDouble()
          : null,
      status: ItemStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'carrinhoId': carrinhoId,
      'productId': productId,
      'barcode': barcode,
      'name': name,
      'foto': foto,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'requiresWeight': requiresWeight,
      'expectedWeight': expectedWeight,
      'receivedWeight': receivedWeight,
      'status': status.name,
    };
  }
}
