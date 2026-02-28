import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/order_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/app_drawer.dart';
import '../cart/cart_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();

  List<Order> _allOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final orders = await _orderService.getMyRequests();
    if (!mounted) return;
    setState(() {
      _allOrders = orders;
      _loading = false;
    });
  }

  List<Order> get _approvedOrders => _allOrders
      .where((o) => o.status == 'approved' || o.status == 'active')
      .toList();

  List<Order> get _pendingOrders =>
      _allOrders.where((o) => o.status == 'pending').toList();

  List<Order> get _historyOrders => _allOrders
      .where((o) =>
          o.status == 'completed' ||
          o.status == 'returned' ||
          o.status == 'rejected' ||
          o.status == 'cancelled')
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'history'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Mis Solicitudes'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C3AED),
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: _tabLabel(
                  'Aprobadas', _approvedOrders.length, const Color(0xFF10B981)),
            ),
            Tab(
              child: _tabLabel(
                  'Pendientes', _pendingOrders.length, const Color(0xFFF59E0B)),
            ),
            const Tab(text: 'Historial'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_approvedOrders, 'approved'),
                _buildOrderList(_pendingOrders, 'pending'),
                _buildOrderList(_historyOrders, 'completed'),
              ],
            ),
    );
  }

  Widget _tabLabel(String text, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderList(List<Order> orders, String type) {
    if (orders.isEmpty) {
      final (icon, message) = switch (type) {
        'approved' => (
            Icons.check_circle_outline,
            'No tienes solicitudes aprobadas'
          ),
        'pending' => (Icons.pending_outlined, 'No tienes solicitudes pendientes'),
        _ => (Icons.history, 'Tu historial está vacío'),
      };
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: orders.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showOrderDetails(orders[index]),
          child: _buildOrderCard(orders[index]),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusInfo = _getStatusInfo(order.status);
    final color = statusInfo['color'] as Color;
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusInfo['icon'] as IconData,
                      color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solicitud #${order.id}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        fmt.format(order.createdAt),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusInfo['label'] as String,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.materialName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '×${item.quantity}',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Admin notes if any
          if (order.reviewNotes != null && order.reviewNotes!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (order.status == 'rejected'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF3B82F6))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      order.status == 'rejected'
                          ? Icons.cancel_outlined
                          : Icons.info_outline,
                      size: 14,
                      color: order.status == 'rejected'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.reviewNotes!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Bottom: pickup date + tap hint + repeat button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                if (order.pickupDate != null) ...[
                  const Icon(Icons.event, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    fmt.format(order.pickupDate!),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
                const Spacer(),
                if (order.items.isNotEmpty &&
                    (order.status == 'completed' ||
                        order.status == 'returned' ||
                        order.status == 'rejected' ||
                        order.status == 'cancelled')) ...[
                  GestureDetector(
                    onTap: () => _repeatOrder(order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay_rounded,
                              size: 12, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text('Repetir',
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  'Ver detalles',
                  style: TextStyle(
                    color: const Color(0xFF7C3AED),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: Color(0xFF7C3AED)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _repeatOrder(Order order) {
    final cart = CartService();
    int added = 0;
    for (final item in order.items) {
      if (item.materialId == 0) continue;
      cart.addToCart(CartItem(
        materialId: item.materialId,
        name: item.materialName,
        description: '',
        sku: '',
        qrCode: '',
        quantity: item.quantity,
        availableQuantity: item.quantity,
      ));
      added++;
    }
    if (added == 0) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$added material${added == 1 ? '' : 'es'} añadido${added == 1 ? '' : 's'} al carrito'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Ver carrito',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    final statusInfo = _getStatusInfo(order.status);
    final color = statusInfo['color'] as Color;
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final fmtFull = DateFormat('dd MMM yyyy, HH:mm', 'es');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (ctx, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(statusInfo['icon'] as IconData,
                            color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solicitud #${order.id}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusInfo['label'] as String,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info rows
                  _detailRow(Icons.access_time, 'Creado',
                      fmtFull.format(order.createdAt)),
                  if (order.pickupDate != null)
                    _detailRow(Icons.event, 'Fecha de retiro',
                        fmt.format(order.pickupDate!)),
                  if (order.purpose != null && order.purpose!.isNotEmpty)
                    _detailRow(Icons.notes, 'Propósito', order.purpose!),

                  const Divider(color: Colors.white12, height: 24),

                  // Items
                  const Text(
                    'Materiales solicitados',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F1E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 16, color: Color(0xFF7C3AED)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.materialName,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '×${item.quantity}',
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                  // Admin notes
                  if (order.reviewNotes != null &&
                      order.reviewNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notas del administrador',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (order.status == 'rejected'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF3B82F6))
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (order.status == 'rejected'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF3B82F6))
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        order.reviewNotes!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],

                  // QR Code for approved requests
                  if ((order.status == 'approved' || order.status == 'active') &&
                      order.qrToken != null &&
                      order.qrToken!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Código QR para recoger',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: QrImageView(
                          data: order.qrToken!,
                          version: QrVersions.auto,
                          size: 180,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Muestra este código al recoger tus materiales',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'approved':
        return {
          'label': 'Aprobada',
          'color': const Color(0xFF10B981),
          'icon': Icons.check_circle_outline,
        };
      case 'active':
        return {
          'label': 'Activa',
          'color': const Color(0xFF3B82F6),
          'icon': Icons.play_circle_outline,
        };
      case 'pending':
        return {
          'label': 'Pendiente',
          'color': const Color(0xFFF59E0B),
          'icon': Icons.access_time,
        };
      case 'completed':
      case 'returned':
        return {
          'label': 'Completada',
          'color': const Color(0xFF6B7280),
          'icon': Icons.inventory_2_outlined,
        };
      case 'rejected':
        return {
          'label': 'Rechazada',
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel_outlined,
        };
      case 'cancelled':
        return {
          'label': 'Cancelada',
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel_outlined,
        };
      default:
        return {
          'label': status,
          'color': Colors.grey,
          'icon': Icons.help_outline,
        };
    }
  }
}
