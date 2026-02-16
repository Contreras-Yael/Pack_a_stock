class CartItem {
  final int materialId;
  final String name;
  final String description;
  final String sku;
  final String qrCode;
  int quantity;
  final int availableQuantity;

  CartItem({
    required this.materialId,
    required this.name,
    required this.description,
    required this.sku,
    required this.qrCode,
    required this.quantity,
    required this.availableQuantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'material_id': materialId,
      'quantity': quantity,
    };
  }
}
