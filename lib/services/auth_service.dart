import '../models/user.dart';
import 'api_client.dart';
import 'token_service.dart';

class AuthService {
  AuthService(this._api, this._tokens);
  final ApiClient _api;
  final TokenService _tokens;

  Future<AppUser> login(String email, String pin) async {
    final data = await _api.post('/auth/login', body: {'email': email.trim(), 'secret': pin}, auth: false)
        as Map<String, dynamic>;
    await _tokens.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> me() async => AppUser.fromJson(await _api.get('/auth/me') as Map<String, dynamic>);

  Future<AppUser> updateProfile({String? name, String? email}) async => AppUser.fromJson(
        await _api.patch('/auth/me', body: {'name': ?name, 'email': ?email}) as Map<String, dynamic>,
      );

  Future<void> changePin(String current, String next) =>
      _api.post('/auth/change-secret', body: {'currentSecret': current, 'newSecret': next});

  Future<void> logout() async {
    final refresh = await _tokens.getRefreshToken();
    try {
      if (refresh != null) await _api.post('/auth/logout', body: {'refreshToken': refresh});
    } catch (_) {
      // Signing out locally is what matters; the token expires on its own.
    }
    await _tokens.clear();
  }
}
