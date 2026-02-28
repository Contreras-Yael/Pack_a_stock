import 'package:flutter/material.dart';
import '../../models/material_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/cart_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Detalle del Material'),
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
                    color: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
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
                                              color: Color(0xFF7C3AED),
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
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SKU: ${widget.material.sku}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
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
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 15),
                            _buildInfoCard(
                              icon: Icons.inventory,
                              label: 'Disponibles',
                              value: '${widget.material.availableQuantity}',
                              color: const Color(0xFF3B82F6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Descripción
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.material.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Selector de cantidad
                        const Text(
                          'Cantidad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Selecciona la cantidad',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: const Color(0xFF7C3AED),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F0F1E),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _quantity <
                                            widget.material.availableQuantity
                                        ? () => setState(() => _quantity++)
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: const Color(0xFF7C3AED),
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
              color: const Color(0xFF1A1A2E),
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
                    backgroundColor: const Color(0xFF7C3AED),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED),
            const Color(0xFFA855F7).withOpacity(0.8),
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
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
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
                color: Colors.grey[400],
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
