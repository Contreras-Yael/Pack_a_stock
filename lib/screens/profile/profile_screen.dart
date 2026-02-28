import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../../models/user_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();

  User? _user;
  Map<String, int> _summary = {
    'active_loans': 0,
    'pending_requests': 0,
    'completed_loans': 0,
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final user = await _authService.getProfile();
    final summary = await _orderService.getMySummary();
    if (!mounted) return;
    setState(() {
      _user = user;
      _summary = summary;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'profile'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Mi Perfil'),
        elevation: 0,
        actions: [
          if (_user != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar perfil',
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: _user!),
                  ),
                );
                if (changed == true) _loadData();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header with avatar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              _user != null && _user!.fullName.isNotEmpty
                                  ? _user!.fullName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _user?.fullName ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _user?.email ?? '',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _user?.userType == 'employee' ? 'Empleado' : 'Inventarista',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal info
                        const Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        _buildInfoCard(
                          icon: Icons.badge_outlined,
                          title: 'ID de Usuario',
                          value: 'EMP-${_user?.id ?? '---'}',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.email_outlined,
                          title: 'Correo',
                          value: _user?.email ?? '---',
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.work_outline,
                          title: 'Tipo de cuenta',
                          value: _user?.userType == 'employee'
                              ? 'Empleado'
                              : 'Inventarista',
                        ),

                        const SizedBox(height: 30),

                        // Statistics
                        const Text(
                          'Mis Estadísticas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.inventory_2_outlined,
                                label: 'Activos',
                                value: '${_summary['active_loans']}',
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.pending_outlined,
                                label: 'Pendientes',
                                value: '${_summary['pending_requests']}',
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.check_circle_outline,
                                label: 'Completados',
                                value: '${_summary['completed_loans']}',
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.shopping_bag_outlined,
                                label: 'Total',
                                value:
                                    '${(_summary['active_loans'] ?? 0) + (_summary['pending_requests'] ?? 0) + (_summary['completed_loans'] ?? 0)}',
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _showLogoutDialog(context),
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Cerrar Sesión',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Cerrar Sesión',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              NotificationService().stopPolling();
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const PantallaLogin()),
                (route) => false,
              );
            },
            child: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
