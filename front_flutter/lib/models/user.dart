class StoreUser {
  const StoreUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory StoreUser.fromJson(Map<String, dynamic> json) => StoreUser(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String?,
  );

  final int id;
  final String name;
  final String email;
  final String? role;

  bool get isAdmin => role == 'admin';
}

class AuthResult {
  const AuthResult({required this.user, required this.mergeMessages});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final merge = json['cart_merge'] as Map<String, dynamic>? ?? {};
    final messages = <String>[];
    for (final item in merge['adjusted_items'] as List? ?? []) {
      messages.add(
        '${item['title']}: quantidade ajustada de ${item['requested_quantity']} para ${item['kept_quantity']}, conforme o estoque.',
      );
    }
    for (final item in merge['removed_items'] as List? ?? []) {
      messages.add(
        '${item['title']}: não foi adicionado porque está indisponível.',
      );
    }
    return AuthResult(
      user: StoreUser.fromJson(json['data'] as Map<String, dynamic>),
      mergeMessages: messages,
    );
  }

  final StoreUser user;
  final List<String> mergeMessages;
}
