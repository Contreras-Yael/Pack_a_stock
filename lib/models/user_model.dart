class User {
  final int id;
  final String email;
  final String fullName;
  final String userType; // 'inventarista' o 'employee'
  final String? token;
  final bool isBlocked;
  final String? blockedReason;
  final DateTime? blockedUntil;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    this.token,
    this.isBlocked = false,
    this.blockedReason,
    this.blockedUntil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      userType: json['user_type'] ?? 'employee',
      token: json['token'],
      isBlocked: json['is_blocked'] as bool? ?? false,
      blockedReason: json['blocked_reason'] as String?,
      blockedUntil: json['blocked_until'] != null
          ? DateTime.tryParse(json['blocked_until'])
          : null,
    );
  }
}
