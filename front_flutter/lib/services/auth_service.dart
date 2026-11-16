import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  const AuthService(this.api);

  final ApiClient api;

  Future<StoreUser?> currentUser() async {
    try {
      final response = await api.get('/api/user');
      return StoreUser.fromJson(response['data'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async => AuthResult.fromJson(
    await api.post('/api/auth/login', {'email': email, 'password': password}),
  );

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async => AuthResult.fromJson(
    await api.post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    }),
  );

  Future<void> signOut() async {
    await api.post('/api/auth/logout', {});
  }
}
