import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/scanner/qr_scanner_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/loans/loans_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/catalog/catalog_screen.dart';
import 'screens/stats/stats_screen.dart';
import 'screens/extensions/extensions_screen.dart';
import 'services/favorites_service.dart';
import 'services/theme_service.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await FavoritesService().load();
  await themeNotifier.load();

  runApp(const PackAStockApp());
}

class PackAStockApp extends StatelessWidget {
  const PackAStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pack-a-Stock',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: const SplashScreen(),
          routes: {
            '/scanner': (context) => const QRScannerScreen(),
            '/cart': (context) => const CartScreen(),
            '/history': (context) => const HistoryScreen(),
            '/loans': (context) => const LoansScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/catalog': (context) => const CatalogScreen(),
            '/stats': (context) => const StatsScreen(),
            '/extensions': (context) => const ExtensionsScreen(),
          },
        );
      },
    );
  }
}
