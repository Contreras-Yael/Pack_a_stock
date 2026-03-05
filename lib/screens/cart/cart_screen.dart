import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../order/order_confirmation_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../config/app_colors.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final TextEditingController _purposeController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _returnDate;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  ThemeData get _datePickerTheme => Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppPalette.accent,
          onPrimary: Colors.white,
          surface: Color(0xFF1A1A2E),
          onSurface: Colors.white,
        ),
      );

  Future<void> _selectPickupDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) =>
          Theme(data: _datePickerTheme, child: child!),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Reset return date if it's before the new pickup date
        if (_returnDate != null && !_returnDate!.isAfter(picked)) {
          _returnDate = null;
        }
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final firstReturn = (_selectedDate ?? DateTime.now()).add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: firstReturn,
      firstDate: firstReturn,
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) =>
          Theme(data: _datePickerTheme, child: child!),
    );

    if (picked != null) {
      setState(() => _returnDate = picked);
    }
  }

  void _proceedToCheckout() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de retiro'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una fecha de devolución'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final purpose = _purposeController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          cartItems: _cartService.cartItems,
          pickupDate: _selectedDate!,
          returnDate: _returnDate!,
          purpose: purpose.isNotEmpty ? purpose : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cartItems = _cartService.cartItems;

    return Scaffold(
      backgroundColor: colors.bg,
      drawer: const AppDrawer(currentRoute: 'cart'),
      appBar: AppBar(
        backgroundColor: colors.card,
        title: Text('Carrito de Solicitud', style: TextStyle(color: colors.text)),
        elevation: 0,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.text),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final dlgColors = context.colors;
                    return AlertDialog(
                      backgroundColor: dlgColors.card,
                      title: Text(
                        'Vaciar carrito',
                        style: TextStyle(color: dlgColors.text),
                      ),
                      content: Text(
                        '¿Estás seguro de que deseas vaciar el carrito?',
                        style: TextStyle(color: dlgColors.textSub),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            _cartService.clearCart();
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: const Text(
                            'Vaciar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(colors)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(cartItems[index], colors);
                    },
                  ),
                ),
                _buildPickupDateSelector(colors),
                _buildCheckoutButton(colors),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: colors.textHint,
          ),
          const SizedBox(height: 20),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 20,
              color: colors.textSub,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Escanea un QR para agregar artículos',
            style: TextStyle(
              fontSize: 14,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppPalette.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${item.sku}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () {
                  setState(() {
                    _cartService.removeFromCart(item.materialId);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponibles: ${item.availableQuantity}',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSub,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (item.quantity > 1) {
                        setState(() {
                          _cartService.updateQuantity(
                            item.materialId,
                            item.quantity - 1,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppPalette.accent,
                    iconSize: 20,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (item.quantity < item.availableQuantity) {
                        setState(() {
                          _cartService.updateQuantity(
                            item.materialId,
                            item.quantity + 1,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppPalette.accent,
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required String hint,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null
                    ? AppPalette.accent
                    : colors.border,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: value != null
                      ? AppPalette.accent
                      : colors.textHint,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  value != null
                      ? DateFormat('dd/MM/yyyy').format(value)
                      : hint,
                  style: TextStyle(
                    fontSize: 16,
                    color: value != null ? colors.text : colors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (value != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              DateFormat('EEEE d \'de\' MMMM', 'es').format(value),
              style: TextStyle(fontSize: 12, color: colors.textSub),
            ),
          ),
      ],
    );
  }

  Widget _buildPickupDateSelector(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(
            label: 'Fecha de Retiro',
            value: _selectedDate,
            onTap: _selectPickupDate,
            hint: 'Seleccionar fecha',
            colors: colors,
          ),
          const SizedBox(height: 16),
          _buildDateSelector(
            label: 'Fecha de Devolución',
            value: _returnDate,
            onTap: _selectReturnDate,
            hint: _selectedDate == null
                ? 'Primero selecciona fecha de retiro'
                : 'Seleccionar fecha',
            colors: colors,
          ),
          const SizedBox(height: 16),
          Text(
            'Propósito (opcional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _purposeController,
            style: TextStyle(color: colors.text, fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Ej: Proyecto de construcción, mantenimiento...',
              hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
              filled: true,
              fillColor: colors.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppPalette.accent, width: 2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _proceedToCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_cartService.itemCount}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
