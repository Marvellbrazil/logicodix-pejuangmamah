import 'package:google_sign_in/google_sign_in.dart';

import '../application/api_failure.dart';

class GoogleTokenProvider {
  GoogleTokenProvider({required this.serverClientId});

  final String serverClientId;
  final GoogleSignIn _google = GoogleSignIn.instance;
  Future<void>? _initializing;

  bool get configured => serverClientId.isNotEmpty;

  Future<void> _initialize() =>
      _initializing ??= _google.initialize(
        serverClientId: configured ? serverClientId : null,
      );

  Future<String?> restoreIdToken() async {
    if (!configured) return null;
    try {
      await _initialize();
      final account = await _google.attemptLightweightAuthentication();
      if (account == null) return null;
      final auth = account.authentication;
      return auth.idToken;
    } catch (_) {
      return null;
    }
  }

  Future<String?> requestIdToken() async {
    if (!configured) {
      throw const ApiFailure(
        'Login Google belum diatur di aplikasi ini. Pakai email dan kata sandi dulu.',
        code: 'google_not_configured',
      );
    }
    try {
      await _initialize();
      if (!_google.supportsAuthenticate()) {
        throw const ApiFailure(
          'Login Google tidak didukung di perangkat ini.',
          code: 'google_unsupported',
        );
      }
      final account = await _google.authenticate();
      final auth = account.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        throw const ApiFailure(
          'Google tidak mengirim token identitas. Coba lagi.',
          code: 'google_no_token',
        );
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const ApiFailure(
          'Login Google dibatalkan.',
          code: 'google_canceled',
        );
      }
      throw ApiFailure(
        'Login Google gagal (${error.code.name}).',
        code: 'google_failed',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _initialize();
      await _google.signOut();
    } catch (_) {
      return;
    }
  }
}
