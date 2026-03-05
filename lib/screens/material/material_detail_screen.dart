import 'package:flutter/material.dart';
import '../../models/material_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';
import '../../config/app_colors.dart';

class MaterialDetailScreen extends StatefulWidget {
  final MaterialItem material;

  const MaterialDetailScreen({super.key, required this.material});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  int _quantity = 1;
  final CartService _cartService = CartService();

  void _addToCart() {
    if (_quantity > widget.material.availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cantidad no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartItem = CartItem(
      materialId: widget.material.id,
      name: widget.material.name,
      description: widget.material.description,
      sku: widget.material.sku,
      qrCode: widget.material.qrCode,
      quantity: _quantity,
      availableQuantity: widget.material.availableQuantity,
    );

    _cartService.addToCart(cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_quantity ${widget.material.name} agregado al carrito'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'VER CARRITO',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        title: Text('Detalle del Material', style: TextStyle(color: colors.text)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con imagen/icono
                  Container(
                    width: double.infinity,
                    color: colors.card,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppPalette.accent.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: widget.material.imageUrl != null &&
                                widget.material.imageUrl!.isNotEmpty
                            ? Image.network(
                                widget.material.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _buildImagePlaceholder(),
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator(
                                              color: AppPalette.accent,
                                              strokeWidth: 2,
                                            ),
                                          ),
                              )
                            : _buildImagePlaceholder(),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        Text(
                          widget.material.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // SKU
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SKU: ${widget.material.sku}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSub,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Estado y disponibilidad
                        Row(
                          children: [
                            _buildInfoCard(
                              icon: Icons.check_circle_outline,
                              label: 'Estado',
                              value: widget.material.status == 'available'
                                  ? 'Disponible'
                                  : 'No disponible',
                              color: widget.material.status == 'available'
                                  ? AppPalette.success
                                  : AppPalette.error,
                              colors: colors,
                            ),
                            const SizedBox(width: 15),
                            _buildInfoCard(
                              icon: Icons.inventory,
                              label: 'Disponibles',
                              value: '${widget.material.availableQuantity}',
                              color: AppPalette.info,
                              colors: colors,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Ubicación
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: AppPalette.accent, size: 22),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ubicación',
                                    style: TextStyle(fontSize: 12, color: colors.textSub),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.material.locationName ?? 'Sin ubicación asignada',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: widget.material.locationName != null
                                          ? colors.text
                                          : colors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Descripción
                        Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.material.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textSub,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Selector de cantidad
                        Text(
                          'Cantidad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Selecciona la cantidad',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textSub,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: AppPalette.accent,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.bg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colors.text,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _quantity <
                                            widget.material.availableQuantity
                                        ? () => setState(() => _quantity++)
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: AppPalette.accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón agregar al carrito
          Container(
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
                  onPressed: widget.material.status == 'available'
                      ? _addToCart
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Agregar al Carrito',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.accent,
            AppPalette.accentLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required AppColors colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSub,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
