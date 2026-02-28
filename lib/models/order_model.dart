class Order {
  final int? id;
  final String? qrToken;
  final DateTime? pickupDate;
  final DateTime? returnDate;
  final String status; // 'pending', 'approved', 'active', 'completed', 'cancelled', 'rejected'
  final String? purpose;
  final String? reviewNotes;
  final List<OrderItem> items;
  final DateTime createdAt;

  Order({
    this.id,
    this.qrToken,
    this.pickupDate,
    this.returnDate,
    required this.status,
    this.purpose,
    this.reviewNotes,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Backend uses desired_pickup_date / pickup_date
    final pickupRaw = json['desired_pickup_date'] ?? json['pickup_date'];
    final returnRaw = json['desired_return_date'] ?? json['return_date'];

    return Order(
      id: json['id'],
      qrToken: json['qr_token']?.toString(),
      pickupDate: pickupRaw != null ? DateTime.tryParse(pickupRaw) : null,
      returnDate: returnRaw != null ? DateTime.tryParse(returnRaw) : null,
      status: json['status'] ?? 'pending',
      purpose: json['purpose'],
      reviewNotes: json['review_notes'],
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'desired_pickup_date': pickupDate?.toIso8601String().split('T').first,
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
    // Backend: {id, material (int FK), material_detail: {id, name, sku}, quantity_requested}
    final detail = json['material_detail'];
    final int matId = detail is Map
        ? (detail['id'] as int? ?? 0)
        : (json['material_id'] ?? (json['material'] is int ? json['material'] : 0)) as int;
    final String matName = detail is Map
        ? (detail['name'] as String? ?? '')
        : (json['material_name'] ?? '') as String;
    final int qty =
        (json['quantity_requested'] ?? json['quantity'] ?? 0) as int;

    return OrderItem(
      id: json['id'],
      materialId: matId,
      materialName: matName,
      quantity: qty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'quantity': quantity,
    };
  }
}
