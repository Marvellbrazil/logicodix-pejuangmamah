import 'package:google_sign_in/google_sign_in.dart';

import '../application/auth_repository.dart';
import '../domain/user_account.dart';

class GoogleAuthRepository implements AuthRepository {
  GoogleAuthRepository({required this.serverClientId});

  final String serverClientId;
  Future<void>? _ready;

  Future<void> _init() async {
    try {
      await (_ready ??= GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      ));
    } catch (_) {
      _ready = null;
      rethrow;
    }
  }

  UserAccount _toUser(GoogleSignInAccount account) {
    return UserAccount(
      id: account.id,
      email: account.email,
      name: account.displayName ?? account.email,
      photoUrl: account.photoUrl,
    );
  }

  @override
  Future<UserAccount?> restore() async {
    try {
      await _init();
      final account = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      return account == null ? null : _toUser(account);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserAccount?> signIn() async {
    try {
      await _init();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const AuthFailure('Platform tidak mendukung login Google.');
      }
      return _toUser(await GoogleSignIn.instance.authenticate());
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure(e.code.name);
    } catch (e) {
      throw AuthFailure('$e');
    }
  }

  @override
  Future<void> signOut() async {
    await _init();
    await GoogleSignIn.instance.signOut();
  }
}
