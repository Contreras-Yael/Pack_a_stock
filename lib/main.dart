import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/scanner/qr_scanner_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  
  // Inicializar notificaciones mock
  NotificationService().initializeMockNotifications();
  
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
      ).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(), // Cambiado temporalmente para desarrollo
      // home: const PantallaLogin(), // Descomentar cuando el backend esté listo
      routes: {
        '/scanner': (context) => const QRScannerScreen(),
        '/cart': (context) => const CartScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}