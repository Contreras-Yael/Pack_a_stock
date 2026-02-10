import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _loanReminders = true;
  bool _expirationAlerts = true;
  int _reminderDays = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Configuración'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notificaciones
              const Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),

              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Habilitar Notificaciones',
                subtitle: 'Recibir alertas del sistema',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              _buildSwitchTile(
                icon: Icons.email_outlined,
                title: 'Notificaciones por Email',
                subtitle: 'Recibir alertas por correo electrónico',
                value: _emailNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 10),

              _buildSwitchTile(
                icon: Icons.phone_android_outlined,
                title: 'Notificaciones Push',
                subtitle: 'Recibir alertas en el dispositivo',
                value: _pushNotifications,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      }
                    : null,
              ),

              const SizedBox(height: 30),

              // Alertas de Préstamos
              const Text(
                'Alertas de Préstamos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),

              _buildSwitchTile(
                icon: Icons.schedule_outlined,
                title: 'Recordatorios de Préstamos',
                subtitle: 'Alertas sobre préstamos activos',
                value: _loanReminders,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _loanReminders = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 10),

              _buildSwitchTile(
                icon: Icons.warning_amber_outlined,
                title: 'Alertas de Vencimiento',
                subtitle: 'Avisar cuando un préstamo está por vencer',
                value: _expirationAlerts,
                onChanged: _notificationsEnabled
                    ? (value) {
                        setState(() {
                          _expirationAlerts = value;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 10),

              // Selector de días de anticipación
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Días de Anticipación',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Recibir alerta antes del vencimiento',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_reminderDays días antes',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _reminderDays > 1
                                  ? () {
                                      setState(() {
                                        _reminderDays--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: const Color(0xFF7C3AED),
                            ),
                            IconButton(
                              onPressed: _reminderDays < 7
                                  ? () {
                                      setState(() {
                                        _reminderDays++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Seguridad
              const Text(
                'Seguridad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),

              _buildActionTile(
                icon: Icons.lock_outline,
                title: 'Cambiar Contraseña',
                subtitle: 'Actualizar tu contraseña de acceso',
                onTap: () {
                  _showChangePasswordDialog(context);
                },
              ),
              const SizedBox(height: 10),

              _buildActionTile(
                icon: Icons.security_outlined,
                title: 'Autenticación de Dos Factores',
                subtitle: 'Configurar verificación en dos pasos',
                onTap: () {
                  // TODO: Implementar cuando esté el backend
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función disponible próximamente'),
                      backgroundColor: Color(0xFF7C3AED),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Ayuda y Soporte
              const Text(
                'Ayuda y Soporte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),

              _buildActionTile(
                icon: Icons.help_outline,
                title: 'Centro de Ayuda',
                subtitle: 'Preguntas frecuentes y tutoriales',
                onTap: () {
                  // TODO: Implementar
                },
              ),
              const SizedBox(height: 10),

              _buildActionTile(
                icon: Icons.bug_report_outlined,
                title: 'Reportar Problema',
                subtitle: 'Enviar un reporte de error',
                onTap: () {
                  // TODO: Implementar
                },
              ),
              const SizedBox(height: 10),

              _buildActionTile(
                icon: Icons.info_outline,
                title: 'Acerca de',
                subtitle: 'Información de la aplicación',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final isDisabled = onChanged == null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(isDisabled ? 0.1 : 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Color(0xFF7C3AED).withOpacity(isDisabled ? 0.4 : 1.0),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDisabled ? Colors.white38 : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDisabled ? Colors.white24 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Cambiar Contraseña',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Contraseña Actual',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nueva Contraseña',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF7C3AED)),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar cambio de contraseña con backend
              if (newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña actualizada correctamente'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las contraseñas no coinciden'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF7C3AED)),
            SizedBox(width: 10),
            Text(
              'Acerca de Pack-a-Stock',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pack-a-Stock',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Versión 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 15),
            Text(
              'Sistema de gestión de préstamos de materiales y equipos.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 15),
            Text(
              '© 2026 Pack-a-Stock',
              style: TextStyle(color: Colors.white54, fontSize: 12),
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
