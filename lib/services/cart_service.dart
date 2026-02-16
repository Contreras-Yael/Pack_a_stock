import '../models/cart_item_model.dart';

class CartService {
  // Singleton
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);

  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(CartItem item) {
    // Verificar si el item ya existe
    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.materialId == item.materialId,
    );

    if (existingIndex != -1) {
      // Actualizar cantidad
      _cartItems[existingIndex].quantity += item.quantity;
    } else {
      // Agregar nuevo item
      _cartItems.add(item);
    }
  }

  void removeFromCart(int materialId) {
    _cartItems.removeWhere((item) => item.materialId == materialId);
  }

  void updateQuantity(int materialId, int newQuantity) {
    final index = _cartItems.indexWhere(
      (item) => item.materialId == materialId,
    );
    
    if (index != -1) {
      if (newQuantity <= 0) {
        removeFromCart(materialId);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
    }
  }

  void clearCart() {
    _cartItems.clear();
  }

  bool isInCart(int materialId) {
    return _cartItems.any((item) => item.materialId == materialId);
  }

  int getQuantityInCart(int materialId) {
    final item = _cartItems.firstWhere(
      (item) => item.materialId == materialId,
      orElse: () => CartItem(
        materialId: 0,
        name: '',
        description: '',
        sku: '',
        qrCode: '',
        quantity: 0,
        availableQuantity: 0,
      ),
    );
    return item.quantity;
  }
}
