// v0.3-network_exceptions · 2025-10-25T05:21 IST
// network_exceptions.dart
//
// Small typed exceptions for network flows; used by cdn_uploader and repo.

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network error']);
  @override
  String toString() => 'NetworkException: $message';
}

class UploadCancelledException extends NetworkException {
  UploadCancelledException() : super('Upload cancelled by user');
}

class SigningFailedException extends NetworkException {
  SigningFailedException([String msg = 'Signing failed']) : super(msg);
}

class UploadFailedException extends NetworkException {
  UploadFailedException([String msg = 'Upload failed']) : super(msg);
}

class AuthException extends NetworkException {
  AuthException([String msg = 'Authentication failed']) : super(msg);
}
