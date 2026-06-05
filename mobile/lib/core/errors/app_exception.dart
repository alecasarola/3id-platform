class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException($code): $message';
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

class PermissionException extends AppException {
  const PermissionException({required super.message, super.code});
}
