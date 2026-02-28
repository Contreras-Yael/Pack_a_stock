import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/loans/loans_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/scanner/qr_scanner_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/stats/stats_screen.dart';
import '../screens/extensions/extensions_screen.dart';
import '../services/auth_Service.dart';
import '../services/notification_service.dart';
import '../services/cart_service.dart';
import '../screens/auth/login_screen.dart';
import '../models/user_model.dart';

class AppDrawer extends StatefulWidget {
  final String currentRoute;

  const AppDrawer({super.key, this.currentRoute = ''});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getProfile();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: _user != null && _user!.fullName.isNotEmpty
                        ? Text(
                            _user!.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 35,
                            color: Color(0xFF7C3AED),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _user?.fullName ?? 'Cargando...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'Inicio',
            route: 'home',
            color: const Color(0xFF7C3AED),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          const Divider(color: Color(0xFF2A2A3E)),
          _buildDrawerItem(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Mis Préstamos',
            route: 'loans',
            color: const Color(0xFF3B82F6),
            onTap: () {
              if (widget.currentRoute != 'loans') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoansScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history,
            title: 'Mis Solicitudes',
            route: 'history',
            color: const Color(0xFFF59E0B),
            onTap: () {
              if (widget.currentRoute != 'history') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.event_repeat_rounded,
            title: 'Mis Extensiones',
            route: 'extensions',
            color: const Color(0xFF06B6D4),
            onTap: () {
              if (widget.currentRoute != 'extensions') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExtensionsScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart_rounded,
            title: 'Mi Resumen',
            route: 'stats',
            color: const Color(0xFFA855F7),
            onTap: () {
              if (widget.currentRoute != 'stats') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StatsScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: 'Perfil',
            route: 'profile',
            color: const Color(0xFFEC4899),
            onTap: () {
              if (widget.currentRoute != 'profile') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Divider(color: Color(0xFF2A2A3E)),
          _buildDrawerItem(
            context,
            icon: Icons.qr_code_scanner,
            title: 'Escanear QR',
            route: 'scanner',
            color: const Color(0xFF7C3AED),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.category_outlined,
            title: 'Catálogo',
            route: 'catalog',
            color: const Color(0xFF10B981),
            onTap: () {
              if (widget.currentRoute != 'catalog') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CatalogScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          ListenableBuilder(
            listenable: CartService(),
            builder: (context, _) {
              final cartCount = CartService().itemCount;
              final isSelected = widget.currentRoute == 'cart';
              return ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        color: const Color(0xFF10B981)),
                    if (cartCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  'Carrito',
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedTileColor:
                    const Color(0xFF10B981).withOpacity(0.1),
                onTap: () {
                  if (widget.currentRoute != 'cart') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartScreen()),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
          const Divider(color: Color(0xFF2A2A3E)),
          ListenableBuilder(
            listenable: NotificationService(),
            builder: (context, _) {
              final count = NotificationService().unreadCount;
              return ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: Color(0xFFF59E0B)),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text(
                  'Notificaciones',
                  style: TextStyle(color: Colors.white),
                ),
                selected: widget.currentRoute == 'notifications',
                selectedTileColor:
                    const Color(0xFFF59E0B).withOpacity(0.1),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NotificationsScreen()),
                  );
                },
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Configuración',
            route: 'settings',
            color: Colors.grey,
            onTap: () {
              if (widget.currentRoute != 'settings') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Divider(color: Color(0xFF2A2A3E)),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
            ),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      NotificationService().stopPolling();
      await _authService.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PantallaLogin()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.currentRoute == route;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? color : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: color.withOpacity(0.1),
      onTap: onTap,
    );
  }
}
