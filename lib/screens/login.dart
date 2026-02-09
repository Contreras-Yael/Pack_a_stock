import 'package:flutter/material.dart';
import 'package:pack_a_stock/services/api_service.dart'; 
import 'homescreen.dart'; // Asegúrate que este archivo exista y tenga la clase HomeScreen

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final ApiService _apiService = ApiService(); // Se mantiene aunque no lo usemos por ahora
  
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    // 1. Validar campos vacíos
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      setState(() {
        _message = 'Por favor ingrese usuario y contraseña';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    // Simular un pequeño tiempo de espera (opcional, para ver el loading)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // 2. VALIDACIÓN HARCODEADA (SOLO PARA PRUEBAS)
    // Aquí ignoramos la API y validamos texto directo
    if (_userController.text == 'admin' && _passController.text == 'pass') {
      
      // ÉXITO: Navegación
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      
    } else {
      
      // ERROR: Credenciales incorrectas
      setState(() {
        _message = 'Credenciales incorrectas (Prueba: admin / pass)';
      });
      
    }

    /* --- CÓDIGO ORIGINAL DE API COMENTADO ---
    try {
      final user = await _apiService.login(
        _userController.text,
        _passController.text,
      );
      // ... resto de la lógica de API
    } catch (e) { ... }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pack-a-Stock',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
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
              if (_message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        child: const Text('INGRESAR'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}