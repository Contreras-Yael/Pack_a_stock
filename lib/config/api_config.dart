class ApiConfig {
  // Servidor de producción en Ionos
  static const String _prodUrl = 'https://packstock.198.71.54.179.nip.io/api';

  // Para desarrollo local (descomentar si necesitas probar local)
  // static const String _localUrl = 'http://192.168.1.15:8000/api';

  static String get baseUrl => _prodUrl;

  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}
