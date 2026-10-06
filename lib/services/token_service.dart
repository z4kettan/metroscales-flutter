import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the access and refresh tokens and the chosen branch between launches.
class TokenService {
  static const _accessKey = 'ms_access_token';
  static const _refreshKey = 'ms_refresh_token';
  static const _branchKey = 'ms_branch_id';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  Future<String?> getAccessToken() async =>
      (await SharedPreferences.getInstance()).getString(_accessKey);

  Future<String?> getRefreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshKey);

  Future<String?> getBranchId() async =>
      (await SharedPreferences.getInstance()).getString(_branchKey);

  Future<void> saveBranchId(String id) async =>
      (await SharedPreferences.getInstance()).setString(_branchKey, id);

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}
