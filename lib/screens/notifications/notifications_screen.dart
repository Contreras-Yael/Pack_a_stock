import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_drawer.dart';
import '../history/history_screen.dart';
import '../loans/loans_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'notifications'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Notificaciones'),
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _notificationService.markAllAsRead();
                } else if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 10),
                      Text('Marcar todas como leídas'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 10),
                      Text('Limpiar todas'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 60,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando tengas nuevas notificaciones\naparecerán aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final color = _notificationService.getNotificationColor(notification.type);
    final icon = _notificationService.getNotificationIcon(notification.type);
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificación eliminada'),
            backgroundColor: const Color(0xFF1A1A2E),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () {
                // En una implementación real, restauraríamos la notificación
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
          }
          _navigateToDetail(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? const Color(0xFF1A1A2E)
                : const Color(0xFF1A1A2E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.white.withOpacity(0.1)
                  : color.withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return 'hace $minutes min${minutes == 1 ? '' : 's'}';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return 'hace $hours hora${hours == 1 ? '' : 's'}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'hace $days día${days == 1 ? '' : 's'}';
    } else {
      return DateFormat('d MMM, HH:mm', 'es').format(timestamp);
    }
  }

  void _navigateToDetail(NotificationItem notification) {
    if (notification.orderId == null) return;

    // Loan-related types go to LoansScreen
    if (notification.type == NotificationType.expirationWarning ||
        notification.type == NotificationType.expired) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoansScreen()),
      );
    } else if (notification.type == NotificationType.approved ||
        notification.type == NotificationType.rejected) {
      // Request-related types go to HistoryScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Limpiar Notificaciones',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todas las notificaciones?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              _notificationService.clearAll();
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
