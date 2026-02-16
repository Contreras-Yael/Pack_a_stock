class Order {
  final int? id;
  final String? qrToken;
  final DateTime? pickupDate;
  final String status; // 'pending', 'approved', 'active', 'completed', 'cancelled'
  final List<OrderItem> items;
  final DateTime createdAt;

  Order({
    this.id,
    this.qrToken,
    this.pickupDate,
    required this.status,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      qrToken: json['qr_token'],
      pickupDate: json['pickup_date'] != null 
          ? DateTime.parse(json['pickup_date']) 
          : null,
      status: json['status'] ?? 'pending',
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pickup_date': pickupDate?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderItem {
  final int? id;
  final int materialId;
  final String materialName;
  final int quantity;

  OrderItem({
    this.id,
    required this.materialId,
    required this.materialName,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      materialId: json['material_id'] ?? json['material']?['id'] ?? 0,
      materialName: json['material_name'] ?? json['material']?['name'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'quantity': quantity,
    };
  }
}
