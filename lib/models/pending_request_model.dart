class PendingRequest {
  final int id;
  final String requesterName;
  final String requesterEmail;
  final DateTime? pickupDate;
  final DateTime? returnDate;
  final String status;
  final String? purpose;
  final List<PendingRequestItem> items;
  final DateTime createdAt;

  PendingRequest({
    required this.id,
    required this.requesterName,
    required this.requesterEmail,
    this.pickupDate,
    this.returnDate,
    required this.status,
    this.purpose,
    required this.items,
    required this.createdAt,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    // Backend returns nested user in 'requester_detail'
    final requesterDetail = json['requester_detail'];
    final String name = requesterDetail is Map
        ? (requesterDetail['full_name'] ?? requesterDetail['email'] ?? 'Empleado') as String
        : (json['requester_name'] ?? 'Empleado') as String;
    final String email = requesterDetail is Map
        ? (requesterDetail['email'] ?? '') as String
        : '';

    final pickupRaw = json['desired_pickup_date'] ?? json['pickup_date'];
    final returnRaw = json['desired_return_date'] ?? json['return_date'];

    return PendingRequest(
      id: json['id'] ?? 0,
      requesterName: name,
      requesterEmail: email,
      pickupDate: pickupRaw != null ? DateTime.tryParse(pickupRaw) : null,
      returnDate: returnRaw != null ? DateTime.tryParse(returnRaw) : null,
      status: json['status'] ?? 'pending',
      purpose: json['purpose'],
      items: (json['items'] as List?)
              ?.map((item) => PendingRequestItem.fromJson(item))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PendingRequestItem {
  final int id;
  final String materialName;
  final String materialSku;
  final int quantity;

  PendingRequestItem({
    required this.id,
    required this.materialName,
    required this.materialSku,
    required this.quantity,
  });

  factory PendingRequestItem.fromJson(Map<String, dynamic> json) {
    final detail = json['material_detail'];
    final String name = detail is Map
        ? (detail['name'] as String? ?? 'Material')
        : 'Material';
    final String sku = detail is Map
        ? (detail['sku'] as String? ?? '')
        : '';

    return PendingRequestItem(
      id: json['id'] ?? 0,
      materialName: name,
      materialSku: sku,
      quantity: (json['quantity_requested'] ?? json['quantity'] ?? 1) as int,
    );
  }
}
