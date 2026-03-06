import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_drawer.dart';
import '../../services/auth_Service.dart';
import '../../services/notification_service.dart';
import '../../services/theme_service.dart';
import '../../models/user_model.dart';
import '../../config/app_colors.dart';

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
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.text,
        title: Text('Configuración', style: TextStyle(color: colors.text)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppPalette.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cuenta ──────────────────────────────────────────────
                  _sectionTitle('Cuenta', colors),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    colors: colors,
                    icon: Icons.lock_outline,
                    iconColor: AppPalette.accent,
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualizar tu contraseña de acceso',
                    onTap: () => _showChangePasswordDialog(context, colors),
                  ),

                  const SizedBox(height: 30),

                  // ── Notificaciones ──────────────────────────────────────
                  _sectionTitle('Notificaciones', colors),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    colors: colors,
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
                    colors: colors,
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
                    colors: colors,
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
                  _buildDaysSelectorTile(colors),

                  const SizedBox(height: 30),

                  // ── Apariencia ──────────────────────────────────────────
                  _sectionTitle('Apariencia', colors),
                  const SizedBox(height: 12),
                  _buildThemeToggleTile(colors),

                  const SizedBox(height: 30),

                  // ── Aplicación ──────────────────────────────────────────
                  _sectionTitle('Aplicación', colors),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    colors: colors,
                    icon: Icons.info_outline,
                    iconColor: AppPalette.info,
                    title: 'Acerca de Pack-a-Stock',
                    subtitle: 'Versión 1.0.0',
                    onTap: () => _showAboutDialog(context, colors),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, AppColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppPalette.accent,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildUserCard(AppColors colors) {
    final initials = _user != null && _user!.fullName.isNotEmpty
        ? _user!.fullName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppPalette.accent.withOpacity(0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppPalette.accent,
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
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _user?.email ?? '—',
                  style: TextStyle(color: colors.textSub, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppPalette.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Empleado',
                    style: TextStyle(
                      color: AppPalette.success,
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
    required AppColors colors,
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
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppPalette.accent.withOpacity(isDisabled ? 0.06 : 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: AppPalette.accent.withOpacity(isDisabled ? 0.3 : 1.0),
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
                      color: isDisabled
                          ? colors.text.withOpacity(0.38)
                          : colors.text,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDisabled
                          ? colors.text.withOpacity(0.24)
                          : colors.textHint,
                    )),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppPalette.accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelectorTile(AppColors colors) {
    final enabled = _notificationsEnabled && _expirationAlerts;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppPalette.accent.withOpacity(enabled ? 0.15 : 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today_outlined,
                color: AppPalette.accent.withOpacity(enabled ? 1.0 : 0.3),
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
                      color: enabled
                          ? colors.text
                          : colors.text.withOpacity(0.38),
                    )),
                const SizedBox(height: 2),
                Text('Alerta antes del vencimiento',
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled
                          ? colors.textHint
                          : colors.text.withOpacity(0.24),
                    )),
              ],
            ),
          ),
          Row(
            children: [
              _dayBtn(
                colors: colors,
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
                    color: enabled
                        ? colors.text
                        : colors.text.withOpacity(0.38),
                  ),
                ),
              ),
              _dayBtn(
                colors: colors,
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

  Widget _dayBtn({
    required AppColors colors,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: enabled
              ? AppPalette.accent.withOpacity(0.15)
              : colors.border.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled
                ? AppPalette.accent
                : colors.text.withOpacity(0.24)),
      ),
    );
  }

  Widget _buildThemeToggleTile(AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: ListenableBuilder(
        listenable: themeNotifier,
        builder: (context, _) {
          final dark = themeNotifier.isDark;
          return InkWell(
            onTap: () => themeNotifier.toggle(),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppPalette.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: AppPalette.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dark ? 'Modo oscuro' : 'Modo claro',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dark
                              ? 'Toca para cambiar a modo claro'
                              : 'Toca para cambiar a modo oscuro',
                          style: TextStyle(fontSize: 12, color: colors.textHint),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !dark,
                    onChanged: (_) => themeNotifier.toggle(),
                    activeColor: AppPalette.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionTile({
    required AppColors colors,
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
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
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
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: colors.textHint)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context, AppColors colors) {
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
          backgroundColor: colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: AppPalette.accent, size: 20),
              const SizedBox(width: 8),
              Text('Cambiar contraseña',
                  style: TextStyle(color: colors.text, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dialogError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppPalette.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppPalette.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppPalette.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(dialogError!,
                            style: const TextStyle(
                                color: AppPalette.error, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _pwField(colors, currentCtrl, 'Contraseña actual', showCurrent,
                  () => setDialog(() => showCurrent = !showCurrent)),
              const SizedBox(height: 10),
              _pwField(colors, newCtrl, 'Nueva contraseña', showNew,
                  () => setDialog(() => showNew = !showNew)),
              const SizedBox(height: 10),
              _pwField(colors, confirmCtrl, 'Confirmar contraseña', showConfirm,
                  () => setDialog(() => showConfirm = !showConfirm)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancelar', style: TextStyle(color: colors.textHint)),
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
                              backgroundColor: AppPalette.success,
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
                backgroundColor: AppPalette.accent,
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

  Widget _pwField(AppColors colors, TextEditingController ctrl, String label,
      bool visible, VoidCallback toggleVisible) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      style: TextStyle(color: colors.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textHint, fontSize: 13),
        filled: true,
        fillColor: colors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.accent),
        ),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
              size: 18, color: colors.textHint),
          onPressed: toggleVisible,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppPalette.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Pack-a-Stock',
                style: TextStyle(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _aboutRow(colors, Icons.tag, 'Versión', '1.0.0'),
            const SizedBox(height: 10),
            _aboutRow(colors, Icons.phone_android, 'Plataforma', 'Android / iOS'),
            const SizedBox(height: 10),
            _aboutRow(colors, Icons.business_outlined, 'Desarrollado por',
                'Pack-a-Stock Team'),
            const SizedBox(height: 16),
            Text(
              'Sistema de gestión de préstamos de materiales y equipos.',
              style: TextStyle(color: colors.textSub, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('© 2026 Pack-a-Stock',
                style: TextStyle(color: colors.textHint, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar',
                style: TextStyle(color: AppPalette.accent)),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(AppColors colors, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textHint),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(color: colors.textHint, fontSize: 13)),
        Text(value,
            style: TextStyle(color: colors.text, fontSize: 13)),
      ],
    );
  }
}
