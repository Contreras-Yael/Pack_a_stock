import 'dart:io';
import 'package:flutter/foundation.dart'; // Para kIsWeb

class ApiConfig {
  // ---------------------------------------------------------
  // CONFIGURACIÓN DE RED
  // Cambia esto a TRUE si estás probando en un celular físico con cable USB/WiFi.
  // Cambia a FALSE si usas el Emulador de Android Studio.
//  static const bool usarCelularFisico = false; 
  
  // Tu IP local (la que sacaste con ipconfig)
  static const String miIpLocal = '192.168.1.15'; 
  static const bool usarCelularFisico = true;
  // ---------------------------------------------------------

  // 1. URL BASE (La lógica inteligente)
  static String get baseUrl {
    // A) Si es WEB (Chrome)
    if (kIsWeb) {
      return 'http://localhost:8000/api'; 
    }
    
    // B) Si es ANDROID (Emulador o Físico)
    if (Platform.isAndroid) {
      if (usarCelularFisico) {
        return 'http://$miIpLocal:8000/api'; // IP Real
      } else {
        return 'http://10.0.2.2:8000/api';    // IP Mágica del Emulador
      }
    }
    
    // C) Si es iOS u otro
    return 'http://$miIpLocal:8000/api'; 
  }

  // 2. HEADERS (Esto es lo que te faltaba y causaba el error)
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}