import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _message = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _message = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final result = await _authService.registerEmployee(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      companyCode: _codeController.text.trim().toUpperCase(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() => _message = result['message'] ?? 'Error al registrarse');
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool? showToggle,
    VoidCallback? onToggle,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
        suffixIcon: showToggle == true
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey[400],
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF4444)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Regístrate con el código de tu empresa',
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 32),

                // Full name
                _buildField(
                  controller: _nameController,
                  label: 'Nombre completo',
                  icon: Icons.person_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),

                // Email
                _buildField(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                _buildField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outlined,
                  obscure: _obscurePassword,
                  showToggle: true,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password
                _buildField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar contraseña',
                  icon: Icons.lock_outlined,
                  obscure: _obscureConfirm,
                  showToggle: true,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Confirma tu contraseña' : null,
                ),
                const SizedBox(height: 16),

                // Company code
                _buildField(
                  controller: _codeController,
                  label: 'Código de empresa',
                  icon: Icons.business_outlined,
                  hint: 'Ej: A1B2C3D4',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el código de tu empresa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF7C3AED), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El código lo proporciona el administrador de tu empresa',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Error message
                if (_message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFEF4444).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _message,
                            style: const TextStyle(
                                color: Color(0xFFEF4444), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF7C3AED)))
                      : ElevatedButton(
                          onPressed: _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Crear Cuenta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta?',
                        style: TextStyle(color: Colors.grey[400])),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
