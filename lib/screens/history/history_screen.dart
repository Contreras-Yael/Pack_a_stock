import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../widgets/app_drawer.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // TODO: Estos datos serán reemplazados por datos del backend
  final List<Order> _mockOrders = [
    Order(
      id: 1,
      qrToken: 'ORD-1707516000000-12345',
      pickupDate: DateTime.now().add(const Duration(days: 2)),
      status: 'pending',
      items: [
        OrderItem(
          id: 1,
          materialId: 1,
          materialName: 'Cable HDMI 2m',
          quantity: 2,
        ),
        OrderItem(
          id: 2,
          materialId: 2,
          materialName: 'Mouse Inalámbrico',
          quantity: 1,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Order(
      id: 2,
      qrToken: 'ORD-1707429600000-67890',
      pickupDate: DateTime.now(),
      status: 'active',
      items: [
        OrderItem(
          id: 3,
          materialId: 3,
          materialName: 'Laptop Dell XPS',
          quantity: 1,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Order(
      id: 3,
      qrToken: 'ORD-1707256800000-11111',
      pickupDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'completed',
      items: [
        OrderItem(
          id: 4,
          materialId: 4,
          materialName: 'Proyector',
          quantity: 1,
        ),
        OrderItem(
          id: 5,
          materialId: 5,
          materialName: 'Cable VGA',
          quantity: 2,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Order> _getFilteredOrders(String status) {
    switch (status) {
      case 'active':
        return _mockOrders.where((o) => o.status == 'active').toList();
      case 'pending':
        return _mockOrders.where((o) => o.status == 'pending').toList();
      case 'completed':
        return _mockOrders.where((o) => o.status == 'completed').toList();
      default:
        return _mockOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'history'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Historial de Pedidos'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C3AED),
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Pendientes'),
            Tab(text: 'Pasados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('active'),
          _buildOrderList('pending'),
          _buildOrderList('completed'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final orders = _getFilteredOrders(status);

    if (orders.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'active':
        message = 'No tienes pedidos activos';
        icon = Icons.inventory_outlined;
        break;
      case 'pending':
        message = 'No tienes pedidos pendientes';
        icon = Icons.pending_outlined;
        break;
      case 'completed':
        message = 'No tienes pedidos completados';
        icon = Icons.check_circle_outline;
        break;
      default:
        message = 'No hay pedidos';
        icon = Icons.shopping_cart_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusInfo = _getStatusInfo(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusInfo['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header del pedido
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusInfo['color'].withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusInfo['icon'],
                    color: statusInfo['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${order.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusInfo['color'],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detalles del pedido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Fecha de retiro
                if (order.pickupDate != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Retiro: ${DateFormat('dd/MM/yyyy').format(order.pickupDate!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),

                // Lista de artículos
                ...order.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == order.items.length - 1;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.materialName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          'x${item.quantity}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // Acciones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showOrderDetails(order);
                        },
                        icon: const Icon(Icons.remove_red_eye, size: 18),
                        label: const Text('Ver Detalles'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(
                            color: Color(0xFF7C3AED),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (order.status == 'active' || order.status == 'pending')
                      ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showQRCode(order);
                            },
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: const Text('Ver QR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'active':
        return {
          'label': 'Activo',
          'color': const Color(0xFF10B981),
          'icon': Icons.check_circle,
        };
      case 'pending':
        return {
          'label': 'Pendiente',
          'color': const Color(0xFFF59E0B),
          'icon': Icons.pending,
        };
      case 'completed':
        return {
          'label': 'Completado',
          'color': const Color(0xFF3B82F6),
          'icon': Icons.done_all,
        };
      case 'cancelled':
        return {
          'label': 'Cancelado',
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel,
        };
      default:
        return {
          'label': 'Desconocido',
          'color': Colors.grey,
          'icon': Icons.help_outline,
        };
    }
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Token QR', order.qrToken ?? 'N/A'),
              _buildDetailRow(
                'Fecha Creación',
                DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
              ),
              if (order.pickupDate != null)
                _buildDetailRow(
                  'Fecha Retiro',
                  DateFormat('dd/MM/yyyy').format(order.pickupDate!),
                ),
              _buildDetailRow(
                'Estado',
                _getStatusInfo(order.status)['label'],
              ),
              _buildDetailRow(
                'Total Artículos',
                order.items.fold(0, (sum, item) => sum + item.quantity).toString(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode(Order order) {
    // Navegar a pantalla de confirmación para ver el QR
    // Por ahora, mostrar en un diálogo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Código QR del Pedido',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 150,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              order.qrToken ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
