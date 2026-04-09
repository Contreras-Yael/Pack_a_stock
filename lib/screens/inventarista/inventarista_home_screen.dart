import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import 'inventarista_scan_screen.dart';
import 'inventarista_catalog_screen.dart';
import 'add_material_screen.dart';
import 'pending_requests_screen.dart';

class InventaristaHomeScreen extends StatefulWidget {
  const InventaristaHomeScreen({super.key});

  @override
  State<InventaristaHomeScreen> createState() => _InventaristaHomeScreenState();
}

class _InventaristaHomeScreenState extends State<InventaristaHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    InventaristaScanScreen(),
    InventaristaCatalogScreen(),
    AddMaterialScreen(),
    PendingRequestsScreen(),
  ];

  void _logout() async {
    await AuthService().logout();
    NotificationService().stopPolling();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PantallaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.accent, AppPalette.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Inventarista',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: colors.textSub),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border(top: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Escanear',
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Catálogo',
                  selected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.add_box_rounded,
                  label: 'Agregar',
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.pending_actions_rounded,
                  label: 'Solicitudes',
                  selected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppPalette.accent : context.colors.textHint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
