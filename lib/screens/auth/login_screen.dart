import 'package:flutter/material.dart';
import 'package:pack_a_stock/services/auth_service.dart';
import '../home/home_screen.dart'; // Asegúrate que la ruta sea correcta

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  // Controladores
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  // Servicio de Autenticación
  final AuthService _authService = AuthService();
  
  // Estado de la UI
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE LOGIN ORGANIZADA ---
  void _handleLogin() async {
    // 1. Limpiar mensajes previos
    setState(() {
      _message = '';
    });

    // 2. Validar campos vacíos
    if (_userController.text.trim().isEmpty || _passController.text.trim().isEmpty) {
      setState(() {
        _message = 'Por favor ingrese usuario y contraseña';
      });
      return;
    }

    // 3. Activar carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 4. Llamada al Servicio Real
      final user = await _authService.login(
        _userController.text.trim(),
        _passController.text.trim(),
      );

      // Verificar si el widget sigue montado antes de usar context o setState
      if (!mounted) return;

      // 5. Desactivar carga
      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        // --- ÉXITO ---
        // El token ya se guardó automáticamente en AuthService.
        // Navegamos al Home y eliminamos el historial para que no pueda volver atrás.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // --- ERROR DE CREDENCIALES ---
        setState(() {
          _message = 'Usuario o contraseña incorrectos.';
        });
      }

    } catch (e) {
      // --- ERROR DE CONEXIÓN O EXCEPCIÓN ---
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _message = 'Error de conexión. Verifique su internet.';
      });
      print('Detalle del error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white, // Opcional: Define un color de fondo limpio
      body: Center(
        child: SingleChildScrollView( // Evita error de pixel overflow si sale el teclado
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título o Logo
              const Text(
                'Pack-a-Stock',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // Un toque de color
                ),
              ),
              const SizedBox(height: 40),
              
              // Campo de Usuario
              TextField(
                controller: _userController,
                keyboardType: TextInputType.emailAddress, // Teclado optimizado para email
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Usuario / Email',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              
              // Campo de Contraseña
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 20),

              // Mensaje de Error
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Botón de Ingreso
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _handleLogin,
                        child: const Text('INGRESAR', style: TextStyle(fontSize: 16)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}