class User {
  final int id;
  final String email;
  final String fullName;
  final String userType; // 'inventarista' o 'employee'
  final String? token; // El token de sesión que te dará Django

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    this.token,
  });

  // Factory: Convierte el JSON sucio que llega de internet en un Objeto Dart limpio
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '', // Nota: En Django suele ser snake_case
      userType: json['user_type'] ?? 'employee',
      token: json['token'], // A veces viene en el login
    );
  }
}