import 'package:flutter/material.dart';
import 'screens/login.dart'; // Importa la pantalla de login

void main() {
  runApp(const PackAStockApp());
}

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