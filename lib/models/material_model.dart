class MaterialItem {
  final int id;
  final String name;
  final String description;
  final String sku;
  final String qrCode;
  final int availableQuantity;
  final String status; // 'available', 'on_loan', etc.

  MaterialItem({
    required this.id,
    required this.name,
    required this.description,
    required this.sku,
    required this.qrCode,
    required this.availableQuantity,
    required this.status,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      qrCode: json['qr_code'] ?? '',
      availableQuantity: json['available_quantity'] ?? 0,
      status: json['status'] ?? 'unknown',
    );
  }
}