import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final DateTime pickupDate;
  final DateTime returnDate;
  final String? purpose;

  const OrderConfirmationScreen({
    super.key,
    required this.cartItems,
    required this.pickupDate,
    required this.returnDate,
    this.purpose,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();

  Order? _submittedOrder;
  bool _isSubmitting = false;
  bool _submitted = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _submitOrder();
  }

  Future<void> _submitOrder() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    final result = await _orderService.submitRequest(
      items: widget.cartItems,
      pickupDate: widget.pickupDate,
      returnDate: widget.returnDate,
      purpose: widget.purpose,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      _cartService.clearCart();
      setState(() {
        _submittedOrder = result['order'] as Order?;
        _isSubmitting = false;
        _submitted = true;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Error al enviar solicitud';
        _isSubmitting = false;
      });
    }
  }

  void _retry() {
    _submitOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Confirmación de Pedido'),
        elevation: 0,
        automaticallyImplyLeading: _submitted || _errorMessage.isNotEmpty,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  SizedBox(height: 20),
                  Text(
                    'Enviando solicitud...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildSuccessView(),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline,
                color: Color(0xFFEF4444), size: 56),
          ),
          const SizedBox(height: 24),
          const Text(
            'Error al enviar',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Intentar de nuevo',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Volver al inicio',
                  style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final qrData = _submittedOrder?.qrToken;
    final hasQr = qrData != null && qrData.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Solicitud Enviada',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solicitud #${_submittedOrder?.id ?? '---'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'monospace',
                  ),
                ),
                if (hasQr) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 160,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    qrData,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Order info
          const Text(
            'Detalles del Pedido',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 15),

          _buildInfoCard(
            icon: Icons.tag,
            title: 'Número de Solicitud',
            value: '#${_submittedOrder?.id ?? '---'}',
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'Fecha de Retiro',
            value: DateFormat('dd/MM/yyyy').format(widget.pickupDate),
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.event_available,
            title: 'Fecha de Devolución',
            value: DateFormat('dd/MM/yyyy').format(widget.returnDate),
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),

          // Items
          const Text(
            'Artículos Solicitados',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 15),

          ...widget.cartItems.map((item) => _buildItemCard(item)),

          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                    SizedBox(width: 10),
                    Text('Instrucciones',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF59E0B))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '• Guarda este código QR\n'
                  '• Tu solicitud está pendiente de aprobación\n'
                  '• Presenta el QR en el almacén en la fecha seleccionada\n'
                  '• Recibirás una notificación cuando sea aprobada',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[300], height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Back to home button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Volver al Inicio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text('SKU: ${item.sku}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('x${item.quantity}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
