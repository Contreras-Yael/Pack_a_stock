import 'package:flutter/material.dart';
import '../models/order_model.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? orderId;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.orderId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? orderId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
    );
  }
}

enum NotificationType {
  expirationWarning, // Préstamo próximo a vencer
  expired, // Préstamo vencido
  approved, // Pedido aprobado
  ready, // Pedido listo para recoger
  reminder, // Recordatorio general
  info, // Información general
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  
  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  
  int get unreadCount => unreadNotifications.length;

  // Simular notificaciones mock
  void initializeMockNotifications() {
    _notifications.clear();
    
    // Notificaciones de ejemplo
    _notifications.addAll([
      NotificationItem(
        id: '1',
        title: '⚠️ Préstamo próximo a vencer',
        message: 'Tu préstamo de "Laptop Dell XPS 15" vence en 2 días',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.expirationWarning,
        orderId: 'ORD-2024-001',
      ),
      NotificationItem(
        id: '2',
        title: '✅ Pedido aprobado',
        message: 'Tu pedido #ORD-2024-005 ha sido aprobado',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: NotificationType.approved,
        orderId: 'ORD-2024-005',
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: '📦 Pedido listo para recoger',
        message: 'Tu pedido de materiales está listo. Recógelo hoy.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.ready,
        orderId: 'ORD-2024-004',
      ),
      NotificationItem(
        id: '4',
        title: '⚠️ Préstamo próximo a vencer',
        message: 'Tu préstamo de "Proyector Epson" vence en 1 día',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.expirationWarning,
        orderId: 'ORD-2024-002',
      ),
    ]);
    
    notifyListeners();
  }

  // Verificar préstamos y generar notificaciones
  void checkLoansAndNotify(List<Order> orders, int daysBeforeExpiration) {
    final now = DateTime.now();
    
    for (final order in orders) {
      // Solo verificar préstamos activos
      if (order.status != 'activo') continue;
      if (order.pickupDate == null) continue;
      
      final daysUntilExpiration = order.pickupDate!.difference(now).inDays;
      
      // Generar notificación si está próximo a vencer
      if (daysUntilExpiration <= daysBeforeExpiration && daysUntilExpiration > 0) {
        // Verificar si ya existe una notificación para este pedido
        final existingNotification = _notifications.any(
          (n) => n.orderId == order.id?.toString() && n.type == NotificationType.expirationWarning,
        );
        
        if (!existingNotification) {
          addNotification(
            title: '⚠️ Préstamo próximo a vencer',
            message: 'Tu préstamo vence en $daysUntilExpiration día${daysUntilExpiration == 1 ? '' : 's'}',
            type: NotificationType.expirationWarning,
            orderId: order.id?.toString(),
          );
        }
      }
      
      // Notificación de vencimiento
      if (daysUntilExpiration < 0) {
        final existingNotification = _notifications.any(
          (n) => n.orderId == order.id?.toString() && n.type == NotificationType.expired,
        );
        
        if (!existingNotification) {
          addNotification(
            title: '🚨 Préstamo vencido',
            message: 'Tu préstamo ha vencido. Por favor devuelve los materiales.',
            type: NotificationType.expired,
            orderId: order.id?.toString(),
          );
        }
      }
    }
  }

  // Agregar nueva notificación
  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? orderId,
  }) {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      orderId: orderId,
    );
    
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // Marcar notificación como leída
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Marcar todas como leídas
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  // Eliminar notificación
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  // Limpiar todas las notificaciones
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  // Obtener color según tipo de notificación
  Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.expirationWarning:
        return const Color(0xFFF59E0B); // Amarillo
      case NotificationType.expired:
        return const Color(0xFFEF4444); // Rojo
      case NotificationType.approved:
        return const Color(0xFF10B981); // Verde
      case NotificationType.ready:
        return const Color(0xFF3B82F6); // Azul
      case NotificationType.reminder:
        return const Color(0xFF7C3AED); // Púrpura
      case NotificationType.info:
        return const Color(0xFF6B7280); // Gris
    }
  }

  // Obtener icono según tipo de notificación
  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.expirationWarning:
        return Icons.warning_amber;
      case NotificationType.expired:
        return Icons.error_outline;
      case NotificationType.approved:
        return Icons.check_circle_outline;
      case NotificationType.ready:
        return Icons.inventory_2_outlined;
      case NotificationType.reminder:
        return Icons.notifications_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }
}
