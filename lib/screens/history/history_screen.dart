import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/order_model.dart';
import '../../models/cart_item_model.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/app_drawer.dart';
import '../cart/cart_screen.dart';
import '../../config/app_colors.dart';

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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      drawer: const AppDrawer(currentRoute: 'history'),
      appBar: AppBar(
        backgroundColor: colors.card,
        title: Text('Mis Solicitudes', style: TextStyle(color: colors.text)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.text),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppPalette.accent,
          labelColor: AppPalette.accent,
          unselectedLabelColor: colors.textHint,
          tabs: [
            Tab(
              child: _tabLabel(
                  'Aprobadas', _approvedOrders.length, AppPalette.success),
            ),
            Tab(
              child: _tabLabel(
                  'Pendientes', _pendingOrders.length, AppPalette.warning),
            ),
            const Tab(text: 'Historial'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppPalette.accent),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_approvedOrders, 'approved', colors),
                _buildOrderList(_pendingOrders, 'pending', colors),
                _buildOrderList(_historyOrders, 'completed', colors),
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

  Widget _buildOrderList(List<Order> orders, String type, AppColors colors) {
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
            Icon(icon, size: 64, color: colors.textHint),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(fontSize: 16, color: colors.textSub)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppPalette.accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: orders.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showOrderDetails(orders[index], colors),
          child: _buildOrderCard(orders[index], colors),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, AppColors colors) {
    final statusInfo = _getStatusInfo(order.status);
    final color = statusInfo['color'] as Color;
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.card,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        fmt.format(order.createdAt),
                        style:
                            TextStyle(fontSize: 12, color: colors.textSub),
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
                          size: 14, color: AppPalette.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.materialName,
                          style: TextStyle(
                              color: colors.text, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '×${item.quantity}',
                        style: TextStyle(
                            color: colors.textSub,
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
                          ? AppPalette.error
                          : AppPalette.info)
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
                          ? AppPalette.error
                          : AppPalette.info,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.reviewNotes!,
                        style: TextStyle(color: colors.textSub, fontSize: 12),
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
                  Icon(Icons.event, size: 14, color: colors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    fmt.format(order.pickupDate!),
                    style: TextStyle(color: colors.textSub, fontSize: 12),
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
                        color: AppPalette.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppPalette.success.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.replay_rounded,
                              size: 12, color: AppPalette.success),
                          SizedBox(width: 4),
                          Text('Repetir',
                              style: TextStyle(
                                  color: AppPalette.success,
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
                    color: AppPalette.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppPalette.accent),
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
        backgroundColor: AppPalette.success,
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

  void _showOrderDetails(Order order, AppColors colors) {
    final statusInfo = _getStatusInfo(order.status);
    final color = statusInfo['color'] as Color;
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final fmtFull = DateFormat('dd MMM yyyy, HH:mm', 'es');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetColors = ctx.colors;
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
                        color: sheetColors.textHint,
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
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: sheetColors.text,
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
                        icon: Icon(Icons.close, color: sheetColors.textHint),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info rows
                  _detailRow(Icons.access_time, 'Creado',
                      fmtFull.format(order.createdAt), sheetColors),
                  if (order.pickupDate != null)
                    _detailRow(Icons.event, 'Fecha de retiro',
                        fmt.format(order.pickupDate!), sheetColors),
                  if (order.purpose != null && order.purpose!.isNotEmpty)
                    _detailRow(Icons.notes, 'Propósito', order.purpose!, sheetColors),

                  Divider(color: sheetColors.divider, height: 24),

                  // Items
                  Text(
                    'Materiales solicitados',
                    style: TextStyle(
                        color: sheetColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...order.items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sheetColors.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 16, color: AppPalette.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.materialName,
                                style: TextStyle(
                                    color: sheetColors.text, fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppPalette.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '×${item.quantity}',
                                style: const TextStyle(
                                  color: AppPalette.accent,
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
                    Text(
                      'Notas del administrador',
                      style: TextStyle(
                          color: sheetColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (order.status == 'rejected'
                                ? AppPalette.error
                                : AppPalette.info)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (order.status == 'rejected'
                                  ? AppPalette.error
                                  : AppPalette.info)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        order.reviewNotes!,
                        style: TextStyle(color: sheetColors.textSub, fontSize: 14),
                      ),
                    ),
                  ],

                  // QR Code for approved requests
                  if ((order.status == 'approved' || order.status == 'active') &&
                      order.qrToken != null &&
                      order.qrToken!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Código QR para recoger',
                      style: TextStyle(
                          color: sheetColors.text,
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
                            TextStyle(color: sheetColors.textSub, fontSize: 12),
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

  Widget _detailRow(IconData icon, String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colors.textHint),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: colors.textHint, fontSize: 11)),
              Text(value,
                  style: TextStyle(color: colors.text, fontSize: 14)),
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
          'color': AppPalette.success,
          'icon': Icons.check_circle_outline,
        };
      case 'active':
        return {
          'label': 'Activa',
          'color': AppPalette.info,
          'icon': Icons.play_circle_outline,
        };
      case 'pending':
        return {
          'label': 'Pendiente',
          'color': AppPalette.warning,
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
          'color': AppPalette.error,
          'icon': Icons.cancel_outlined,
        };
      case 'cancelled':
        return {
          'label': 'Cancelada',
          'color': AppPalette.error,
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
