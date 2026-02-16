import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/scanner/qr_scanner_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../services/notification_service.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, this.currentRoute = ''});

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
                  child: const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Carlos Méndez',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'carlos.mendez@empresa.com',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
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
              if (currentRoute != 'loans') {
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
            icon: Icons.history,
            title: 'Historial',
            route: 'history',
            color: const Color(0xFFF59E0B),
            onTap: () {
              if (currentRoute != 'history') {
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
            icon: Icons.person_outline,
            title: 'Perfil',
            route: 'profile',
            color: const Color(0xFFEC4899),
            onTap: () {
              if (currentRoute != 'profile') {
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
            icon: Icons.shopping_cart_outlined,
            title: 'Carrito',
            route: 'cart',
            color: const Color(0xFF10B981),
            onTap: () {
              if (currentRoute != 'cart') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          const Divider(color: Color(0xFF2A2A3E)),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Color(0xFFF59E0B)),
                if (NotificationService().unreadCount > 0)
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
                        '${NotificationService().unreadCount}',
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
            selected: currentRoute == 'notifications',
            selectedTileColor: const Color(0xFFF59E0B).withOpacity(0.1),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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
              if (currentRoute != 'settings') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = currentRoute == route;

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
