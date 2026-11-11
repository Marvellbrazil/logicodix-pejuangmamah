import '../domain/user_account.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

abstract interface class AuthRepository {
  Future<UserAccount?> restore();

  Future<UserAccount?> signIn();

  Future<void> signOut();
}
