/// Lets the API layer end the session (for example when a refresh token has
/// expired) without depending on the UI. The auth provider registers the
/// handler at start-up.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  Future<void> Function()? _onAuthFailure;
  bool _handling = false;

  void register(Future<void> Function() handler) => _onAuthFailure = handler;

  Future<void> onAuthFailure() async {
    if (_handling || _onAuthFailure == null) return;
    _handling = true;
    try {
      await _onAuthFailure!();
    } finally {
      _handling = false;
    }
  }
}
