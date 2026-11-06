/// Utilisateur de l'application (client, agent ou administrateur).
class AppUser {
  final int id;
  final String name;
  final String email;
  final String role; // 'client' | 'agent' | 'admin'
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  bool get isStaff => role != 'client';
  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id'] as int,
        name: m['name'] as String,
        email: m['email'] as String,
        role: m['role'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
