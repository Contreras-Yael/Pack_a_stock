import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_drawer.dart';
import '../../services/auth_Service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  User? _user;
  bool _notificationsEnabled = true;
  bool _loanReminders = true;
  bool _expirationAlerts = true;
  int _reminderDays = 3;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _authService.getProfile(),
      SharedPreferences.getInstance(),
    ]);

    if (!mounted) return;
    final prefs = results[1] as SharedPreferences;
    setState(() {
      _user = results[0] as User?;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _loanReminders = prefs.getBool('loanReminders') ?? true;
      _expirationAlerts = prefs.getBool('expirationAlerts') ?? true;
      _reminderDays = prefs.getInt('daysBeforeExpiration') ?? 3;
      _loading = false;
    });
  }

  Future<void> _savePref<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (_notificationsEnabled && _expirationAlerts) {
      NotificationService().startPolling(daysBeforeExpiration: _reminderDays);
    } else if (!_notificationsEnabled) {
      NotificationService().stopPolling();
    }
  }

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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cuenta ──────────────────────────────────────────────
                  _sectionTitle('Cuenta'),
                  const SizedBox(height: 12),
                  _buildUserCard(),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualizar tu contraseña de acceso',
                    onTap: () => _showChangePasswordDialog(context),
                  ),

                  const SizedBox(height: 30),

                  // ── Notificaciones ──────────────────────────────────────
                  _sectionTitle('Notificaciones'),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Habilitar notificaciones',
                    subtitle: 'Recibir alertas del sistema',
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                      _savePref('notificationsEnabled', val);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchTile(
                    icon: Icons.schedule_outlined,
                    title: 'Recordatorios de préstamos',
                    subtitle: 'Alertas sobre préstamos activos',
                    value: _loanReminders,
                    onChanged: _notificationsEnabled
                        ? (val) {
                            setState(() => _loanReminders = val);
                            _savePref('loanReminders', val);
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _buildSwitchTile(
                    icon: Icons.warning_amber_outlined,
                    title: 'Alertas de vencimiento',
                    subtitle: 'Aviso cuando un préstamo está por vencer',
                    value: _expirationAlerts,
                    onChanged: _notificationsEnabled
                        ? (val) {
                            setState(() => _expirationAlerts = val);
                            _savePref('expirationAlerts', val);
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _buildDaysSelectorTile(),

                  const SizedBox(height: 30),

                  // ── Aplicación ──────────────────────────────────────────
                  _sectionTitle('Aplicación'),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Acerca de Pack-a-Stock',
                    subtitle: 'Versión 1.0.0',
                    onTap: () => _showAboutDialog(context),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7C3AED),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildUserCard() {
    final initials = _user != null && _user!.fullName.isNotEmpty
        ? _user!.fullName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user?.fullName ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _user?.email ?? '—',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Empleado',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(isDisabled ? 0.06 : 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: const Color(0xFF7C3AED).withOpacity(isDisabled ? 0.3 : 1.0),
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Colors.white38 : Colors.white,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDisabled ? Colors.white24 : Colors.grey[500],
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7C3AED),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelectorTile() {
    final enabled = _notificationsEnabled && _expirationAlerts;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(enabled ? 0.15 : 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today_outlined,
                color: const Color(0xFF7C3AED).withOpacity(enabled ? 1.0 : 0.3),
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Días de anticipación',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : Colors.white38,
                    )),
                const SizedBox(height: 2),
                Text('Alerta antes del vencimiento',
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled ? Colors.grey[500] : Colors.white24,
                    )),
              ],
            ),
          ),
          Row(
            children: [
              _dayBtn(
                icon: Icons.remove,
                enabled: enabled && _reminderDays > 1,
                onTap: () {
                  setState(() => _reminderDays--);
                  _savePref('daysBeforeExpiration', _reminderDays);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$_reminderDays',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: enabled ? Colors.white : Colors.white38,
                  ),
                ),
              ),
              _dayBtn(
                icon: Icons.add,
                enabled: enabled && _reminderDays < 7,
                onTap: () {
                  setState(() => _reminderDays++);
                  _savePref('daysBeforeExpiration', _reminderDays);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayBtn({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF7C3AED).withOpacity(0.15)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? const Color(0xFF7C3AED) : Colors.white24),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool saving = false;
    String? dialogError;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 8),
              Text('Cambiar contraseña',
                  style: TextStyle(color: Colors.white, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dialogError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(dialogError!,
                            style: const TextStyle(
                                color: Color(0xFFEF4444), fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _pwField(currentCtrl, 'Contraseña actual', showCurrent,
                  () => setDialog(() => showCurrent = !showCurrent)),
              const SizedBox(height: 10),
              _pwField(newCtrl, 'Nueva contraseña', showNew,
                  () => setDialog(() => showNew = !showNew)),
              const SizedBox(height: 10),
              _pwField(confirmCtrl, 'Confirmar contraseña', showConfirm,
                  () => setDialog(() => showConfirm = !showConfirm)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey[500])),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (currentCtrl.text.isEmpty ||
                          newCtrl.text.isEmpty ||
                          confirmCtrl.text.isEmpty) {
                        setDialog(() => dialogError = 'Completa todos los campos');
                        return;
                      }
                      if (newCtrl.text != confirmCtrl.text) {
                        setDialog(() => dialogError = 'Las contraseñas no coinciden');
                        return;
                      }
                      if (newCtrl.text.length < 8) {
                        setDialog(() => dialogError =
                            'La nueva contraseña debe tener al menos 8 caracteres');
                        return;
                      }
                      setDialog(() {
                        saving = true;
                        dialogError = null;
                      });
                      final result = await _authService.changePassword(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      if (!dialogCtx.mounted) return;
                      if (result['success'] == true) {
                        Navigator.pop(dialogCtx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contraseña actualizada correctamente'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } else {
                        setDialog(() {
                          saving = false;
                          dialogError =
                              result['message'] ?? 'Error al cambiar contraseña';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String label, bool visible,
      VoidCallback toggleVisible) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F0F1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
        ),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              size: 18, color: Colors.grey[500]),
          onPressed: toggleVisible,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF7C3AED), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Pack-a-Stock',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _aboutRow(Icons.tag, 'Versión', '1.0.0'),
            const SizedBox(height: 10),
            _aboutRow(Icons.phone_android, 'Plataforma', 'Android / iOS'),
            const SizedBox(height: 10),
            _aboutRow(Icons.business_outlined, 'Desarrollado por',
                'Pack-a-Stock Team'),
            const SizedBox(height: 16),
            Text(
              'Sistema de gestión de préstamos de materiales y equipos.',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('© 2026 Pack-a-Stock',
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}
