/// Where the app finds the Metro Scales API.
///
/// Set through `--dart-define-from-file=config.json` (see config.example.json).
/// Android emulator: API_HOST=10.0.2.2. iOS simulator or web: localhost.
/// A phone on the same WiFi: your computer's LAN IP.
class ApiConstants {
  static const String _scheme =
      String.fromEnvironment('API_SCHEME', defaultValue: 'http');
  static const String _host =
      String.fromEnvironment('API_HOST', defaultValue: '10.0.2.2');
  static const String _port =
      String.fromEnvironment('API_PORT', defaultValue: '3000');
  static const String _portSuffix =
      (_scheme == 'https' && _port == '443') || (_scheme == 'http' && _port == '80')
          ? ''
          : ':$_port';
  static const String baseUrl = '$_scheme://$_host$_portSuffix/api';

  static const Duration timeout = Duration(seconds: 20);
}
