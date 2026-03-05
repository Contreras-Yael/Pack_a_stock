import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../config/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  late final TextEditingController _nameController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre no puede estar vacío');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await _authService.updateProfile(fullName: name);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado exitosamente'),
          backgroundColor: AppPalette.success,
        ),
      );
      Navigator.pop(context, true); // true = data changed
    } else {
      setState(() =>
          _error = result['message'] ?? 'Error al actualizar el perfil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.text,
        title: const Text('Editar Perfil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar preview
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppPalette.accent, width: 3),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppPalette.accent.withOpacity(0.2),
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppPalette.accent,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Name field
            Text(
              'Nombre Completo',
              style: TextStyle(
                color: colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: colors.text),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tu nombre completo',
                hintStyle: TextStyle(color: colors.textHint),
                prefixIcon:
                    const Icon(Icons.person_outline, color: AppPalette.accent),
                filled: true,
                fillColor: colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppPalette.accent, width: 2),
                ),
                errorText: _error,
                errorStyle: const TextStyle(color: AppPalette.error),
              ),
            ),
            const SizedBox(height: 20),

            // Read-only email
            Text(
              'Correo Electrónico',
              style: TextStyle(
                color: colors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: colors.textHint, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.user.email,
                      style: TextStyle(color: colors.textSub, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.lock_outline, color: colors.textHint, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'El correo no puede modificarse',
              style: TextStyle(color: colors.textHint, fontSize: 12),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
