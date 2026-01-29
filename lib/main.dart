import 'package:flutter/material.dart';

void main() {
  runApp(const PackAStockApp());
}

// 1. La Configuración Global de la App
class PackAStockApp extends StatelessWidget {
  const PackAStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Pack-a-Stock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PantallaLogin(),
    );
  }
}

// 2. Pantalla de Inicio de Sesión
class PantallaLogin extends StatelessWidget {
  const PantallaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( // Centra todo el contenido en la pantalla
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Margen alrededor
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente
            children: [
              const Text(
                'Pack-a-Stock',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40), // Espacio vacío
              // Campo de Usuario
              const TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              // Campo de Contraseña
              const TextField(
                obscureText: true, // Oculta el texto
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              // Botón para entrar
              SizedBox(
                width: double.infinity, // El botón ocupa todo el ancho
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
                    );
                  },
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

// 3. Pantalla Principal
class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Espacio alrededor de todo
        child: Column(
          children: [
            // --- RECUADRO GRANDE SUPERIOR ---
            Expanded(
              flex: 2, // Ocupa el doble de espacio que la fila de abajo
              child: Container(
                width: double.infinity, // Ocupa todo el ancho posible
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(15), // Bordes redondeados
                ),
                child: const Center(
                  child: Text('Recuadro Principal', style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
              ),
            ),
            
            const SizedBox(height: 16), // Espacio entre arriba y abajo

            // --- FILA INFERIOR CON 2 RECUADROS ---
            Expanded(
              flex: 1, // Ocupa menos espacio vertical
              child: Row(
                children: [
                  // Recuadro Izquierdo
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(child: Text('Sección A')),
                    ),
                  ),
                  
                  const SizedBox(width: 16), // Espacio en medio de los dos
                  
                  // Recuadro Derecho
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(child: Text('Sección B')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}