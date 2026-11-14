class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.code = 'error', this.status = 0});

  final String message;
  final String code;
  final int status;

  bool get isUnauthorized => status == 401;

  bool get isOffline => status == 0;

  @override
  String toString() => 'ApiFailure($status $code): $message';
}
