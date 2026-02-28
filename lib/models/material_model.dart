class MaterialItem {
  final int id;
  final String name;
  final String description;
  final String sku;
  final String qrCode;
  final int availableQuantity;
  final int quantity;
  final String status;
  final String? imageUrl;
  final String? categoryName;
  final bool isConsumable;
  final bool isLowStock;

  MaterialItem({
    required this.id,
    required this.name,
    required this.description,
    required this.sku,
    required this.qrCode,
    required this.availableQuantity,
    required this.quantity,
    required this.status,
    this.imageUrl,
    this.categoryName,
    this.isConsumable = false,
    this.isLowStock = false,
  });

  bool get isAvailable => status == 'available' && availableQuantity > 0;

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final bool isConsumable = category is Map
        ? (category['is_consumable'] as bool? ?? false)
        : false;

    return MaterialItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sin nombre',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      qrCode: json['qr_code'] ?? '',
      availableQuantity: json['available_quantity'] ?? 0,
      quantity: json['quantity'] ?? 0,
      status: json['status'] ?? 'unknown',
      imageUrl: json['image'] as String?,
      categoryName: json['category_name'] as String?,
      isConsumable: isConsumable,
      isLowStock: json['is_low_stock'] as bool? ?? false,
    );
  }
}
