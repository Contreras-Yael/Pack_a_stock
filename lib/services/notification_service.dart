import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'storage_service.dart';
import 'auth_Service.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'isRead': isRead,
        'orderId': orderId,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      isRead: json['isRead'] as bool? ?? false,
      orderId: json['orderId'] as String?,
    );
  }
}

enum NotificationType {
  expirationWarning,
  expired,
  approved,
  rejected,
  ready,
  reminder,
  info,
  blocked,
  unblocked,
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _notifications = [];
  Timer? _pollingTimer;
  final StorageService _storage = StorageService();

  static const String _persistKey = 'persisted_notifications';
  static const int _maxPersisted = 50;
  static const Duration _notificationTtl = Duration(days: 7);

  // ─── Getters ──────────────────────────────────────────────────────────────
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;

  // ─── Persistence ──────────────────────────────────────────────────────────
  Future<void> _loadPersistedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_persistKey);
      if (raw == null) return;
      final List<dynamic> list = jsonDecode(raw);
      final cutoff = DateTime.now().subtract(_notificationTtl);
      final loaded = <NotificationItem>[];
      for (final item in list) {
        final n = NotificationItem.fromJson(item as Map<String, dynamic>);
        if (n.timestamp.isAfter(cutoff)) {
          loaded.add(n);
        }
      }
      if (loaded.isNotEmpty) {
        _notifications.clear();
        _notifications.addAll(loaded);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _persistNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _notifications
          .take(_maxPersisted)
          .map((n) => n.toJson())
          .toList();
      await prefs.setString(_persistKey, jsonEncode(toSave));
    } catch (_) {}
  }

  // ─── Polling ──────────────────────────────────────────────────────────────
  void startPolling({int daysBeforeExpiration = 3}) {
    _pollingTimer?.cancel();
    // Load persisted notifications first, then start polling
    _loadPersistedNotifications().then((_) {
      _poll(daysBeforeExpiration);
    });
    _pollingTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _poll(daysBeforeExpiration),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Hace una petición GET con auto-refresh del token si expira (401).
  Future<http.Response?> _authGet(String url, Map<String, String> headers) async {
    try {
      var response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 401) {
        final refreshed = await AuthService().refreshToken();
        if (refreshed) {
          final newToken = await _storage.getToken();
          final newHeaders = {
            ...ApiConfig.headers,
            if (newToken != null) 'Authorization': 'Bearer $newToken',
          };
          response = await http.get(Uri.parse(url), headers: newHeaders);
        }
      }
      return response;
    } catch (_) {
      return null;
    }
  }

  Future<void> _poll(int daysBeforeExpiration) async {
    final token = await _storage.getToken();
    if (token == null) return;

    final headers = {...ApiConfig.headers, 'Authorization': 'Bearer $token'};
    final prefs = await SharedPreferences.getInstance();

    // Set global de claves ya notificadas (requests + extensions comparten este set)
    final Set<String> notifiedSet = Set<String>.from(
      (jsonDecode(prefs.getString('notified_requests') ?? '[]') as List)
          .cast<String>(),
    );

    // ── 1. Loan requests: aprobación / rechazo ────────────────────────────────
    final reqRes = await _authGet(
      '${ApiConfig.baseUrl}/loans/loan-requests/my_requests/',
      headers,
    );
    if (reqRes != null && reqRes.statusCode == 200) {
      try {
        final decoded = jsonDecode(reqRes.body);
        final List<dynamic> requests =
            decoded is List ? decoded : decoded['results'] ?? [];

        for (final req in requests) {
          final id = req['id'].toString();
          final status = req['status'] as String? ?? '';

          if (status == 'approved') {
            final key = 'req_approved_$id';
            if (!notifiedSet.contains(key)) {
              notifiedSet.add(key);
              _addNotification(
                title: '¡Solicitud aprobada!',
                message:
                    'Tu solicitud #$id fue aprobada. Ya puedes recoger los materiales.',
                type: NotificationType.approved,
                orderId: id,
              );
            }
          } else if (status == 'rejected') {
            final key = 'req_rejected_$id';
            if (!notifiedSet.contains(key)) {
              notifiedSet.add(key);
              final notes = req['review_notes'] ?? req['admin_notes'] ?? '';
              _addNotification(
                title: 'Solicitud rechazada',
                message:
                    'Tu solicitud #$id fue rechazada.${notes.toString().isNotEmpty ? ' Motivo: $notes' : ''}',
                type: NotificationType.rejected,
                orderId: id,
              );
            }
          }
        }
      } catch (_) {}
    }

    // ── 2. Loans: nuevos préstamos + overdue + vencimiento próximo ────────────
    final loanRes = await _authGet(
      '${ApiConfig.baseUrl}/loans/loans/my_loans/',
      headers,
    );
    if (loanRes != null && loanRes.statusCode == 200) {
      try {
        final decoded = jsonDecode(loanRes.body);
        final List<dynamic> loans =
            decoded is List ? decoded : decoded['results'] ?? [];

        final Map<String, String> lastLoanStatus =
            Map<String, String>.from(jsonDecode(
          prefs.getString('last_loan_statuses') ?? '{}',
        ));
        final Map<String, String> newLoanStatus = {};
        final now = DateTime.now();

        // Ids de préstamos que ya conocemos (para detectar nuevos)
        final Set<String> knownLoanIds = Set<String>.from(
          (jsonDecode(prefs.getString('known_loan_ids') ?? '[]') as List)
              .cast<String>(),
        );
        final bool isFirstPoll = knownLoanIds.isEmpty;

        for (final loan in loans) {
          final id = loan['id'].toString();
          final status = loan['status'] as String? ?? '';
          newLoanStatus[id] = status;

          final materialName = (loan['material_detail'] is Map
                  ? loan['material_detail']['name']
                  : null) ??
              'Material';

          // Préstamo nuevo (no estaba en el set anterior)
          if (!knownLoanIds.contains(id)) {
            knownLoanIds.add(id);
            // Solo notificar si no es el primer arranque (evitar flood inicial)
            // y si el préstamo está activo (no consumibles ya devueltos)
            if (!isFirstPoll && status == 'active') {
              final newKey = 'loan_new_$id';
              if (!notifiedSet.contains(newKey)) {
                notifiedSet.add(newKey);
                _addNotification(
                  title: 'Nuevo préstamo registrado',
                  message:
                      'Se registró un préstamo de "$materialName" a tu nombre.',
                  type: NotificationType.info,
                  orderId: id,
                );
              }
            }
          }

          final prev = lastLoanStatus[id];

          // Préstamo que pasó a overdue
          if (prev == 'active' && status == 'overdue') {
            _addNotification(
              title: '¡Préstamo vencido!',
              message:
                  'Tu préstamo de "$materialName" ha vencido. Por favor devuelve los materiales.',
              type: NotificationType.expired,
              orderId: id,
            );
          }

          // Alerta de vencimiento próximo (una vez por día por tramo)
          if (status == 'active') {
            final returnDateStr = loan['expected_return_date'] as String?;
            if (returnDateStr != null) {
              final returnDate = DateTime.tryParse(returnDateStr);
              if (returnDate != null) {
                final daysLeft = returnDate.difference(now).inDays;
                if (daysLeft >= 0 && daysLeft <= daysBeforeExpiration) {
                  final alertKey = 'expiry_alerted_${id}_$daysLeft';
                  if (!prefs.containsKey(alertKey)) {
                    await prefs.setBool(alertKey, true);
                    final dayStr = daysLeft == 0
                        ? 'hoy'
                        : 'en $daysLeft día${daysLeft == 1 ? '' : 's'}';
                    _addNotification(
                      title: 'Préstamo por vencer',
                      message:
                          'Tu préstamo de "$materialName" vence $dayStr.',
                      type: NotificationType.expirationWarning,
                      orderId: id,
                    );
                  }
                }
              }
            }
          }
        }

        await prefs.setString(
            'last_loan_statuses', jsonEncode(newLoanStatus));
        await prefs.setString(
            'known_loan_ids', jsonEncode(knownLoanIds.toList()));
      } catch (_) {}
    }

    // ── 3. Extensiones: aprobadas / rechazadas ────────────────────────────────
    final extRes = await _authGet(
      '${ApiConfig.baseUrl}/loans/loan-extensions/my_extensions/',
      headers,
    );
    if (extRes != null && extRes.statusCode == 200) {
      try {
        final decoded = jsonDecode(extRes.body);
        final List<dynamic> extensions =
            decoded is List ? decoded : decoded['results'] ?? [];

        for (final ext in extensions) {
          final id = ext['id'].toString();
          final status = ext['status'] as String? ?? '';
          final materialName = ext['material_name'] as String? ?? 'Material';
          final loanId = ext['loan'].toString();

          if (status == 'approved') {
            final key = 'ext_approved_$id';
            if (!notifiedSet.contains(key)) {
              notifiedSet.add(key);
              final newDate = ext['new_return_date'] as String? ?? '';
              _addNotification(
                title: '¡Extensión aprobada!',
                message:
                    'Tu extensión para "$materialName" fue aprobada. Nueva fecha de devolución: $newDate.',
                type: NotificationType.approved,
                orderId: loanId,
              );
            }
          } else if (status == 'rejected') {
            final key = 'ext_rejected_$id';
            if (!notifiedSet.contains(key)) {
              notifiedSet.add(key);
              final notes = ext['review_notes'] ?? '';
              _addNotification(
                title: 'Extensión rechazada',
                message:
                    'Tu extensión para "$materialName" fue rechazada.${notes.toString().isNotEmpty ? ' Motivo: $notes' : ''}',
                type: NotificationType.rejected,
                orderId: loanId,
              );
            }
          }
        }
      } catch (_) {}
    }

    // ── 4. Perfil: penalización / despenalización ─────────────────────────────
    final profileRes = await _authGet(
      '${ApiConfig.baseUrl}/auth/me/',
      headers,
    );
    if (profileRes != null && profileRes.statusCode == 200) {
      try {
        final decoded = jsonDecode(profileRes.body);
        final userJson = decoded is Map && decoded.containsKey('data')
            ? decoded['data']
            : decoded;

        final bool isBlocked = userJson['is_blocked'] as bool? ?? false;
        final String? blockedReason = userJson['blocked_reason'] as String?;
        final String? blockedUntil = userJson['blocked_until'] as String?;

        final bool wasBlocked =
            prefs.getBool('was_blocked') ?? false;

        if (isBlocked && !wasBlocked) {
          // Recién penalizado
          String durationText = '';
          if (blockedUntil != null) {
            final until = DateTime.tryParse(blockedUntil);
            if (until != null) {
              final days = until.difference(DateTime.now()).inDays;
              if (days > 0) {
                durationText =
                    ' por $days día${days != 1 ? 's' : ''}';
              }
            }
          }
          _addNotification(
            title: 'Cuenta penalizada',
            message:
                'Tu cuenta fue penalizada$durationText.${blockedReason != null && blockedReason.isNotEmpty ? ' Motivo: $blockedReason' : ''}',
            type: NotificationType.blocked,
          );
        } else if (!isBlocked && wasBlocked) {
          // Penalización levantada
          _addNotification(
            title: 'Penalización levantada',
            message:
                'Tu cuenta ha sido despenalizada. Ya puedes realizar solicitudes nuevamente.',
            type: NotificationType.unblocked,
          );
        }

        await prefs.setBool('was_blocked', isBlocked);
      } catch (_) {}
    }

    // Guardar el set combinado de notificaciones
    await prefs.setString(
        'notified_requests', jsonEncode(notifiedSet.toList()));
  }

  // ─── Notification management ───────────────────────────────────────────────
  void _addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? orderId,
  }) {
    _notifications.insert(
      0,
      NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
        orderId: orderId,
      ),
    );
    notifyListeners();
    _persistNotifications();
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? orderId,
  }) =>
      _addNotification(
          title: title, message: message, type: type, orderId: orderId);

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      _persistNotifications();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
    _persistNotifications();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
    _persistNotifications();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
    _persistNotifications();
  }

  // ─── Colors & Icons ────────────────────────────────────────────────────────
  Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.expirationWarning:
        return const Color(0xFFF59E0B);
      case NotificationType.expired:
        return const Color(0xFFEF4444);
      case NotificationType.approved:
        return const Color(0xFF10B981);
      case NotificationType.rejected:
        return const Color(0xFFEF4444);
      case NotificationType.ready:
        return const Color(0xFF3B82F6);
      case NotificationType.reminder:
        return const Color(0xFF7C3AED);
      case NotificationType.info:
        return const Color(0xFF6B7280);
      case NotificationType.blocked:
        return const Color(0xFFEA580C);
      case NotificationType.unblocked:
        return const Color(0xFF10B981);
    }
  }

  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.expirationWarning:
        return Icons.warning_amber;
      case NotificationType.expired:
        return Icons.error_outline;
      case NotificationType.approved:
        return Icons.check_circle_outline;
      case NotificationType.rejected:
        return Icons.cancel_outlined;
      case NotificationType.ready:
        return Icons.inventory_2_outlined;
      case NotificationType.reminder:
        return Icons.notifications_outlined;
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.blocked:
        return Icons.lock_rounded;
      case NotificationType.unblocked:
        return Icons.lock_open_rounded;
    }
  }
}
