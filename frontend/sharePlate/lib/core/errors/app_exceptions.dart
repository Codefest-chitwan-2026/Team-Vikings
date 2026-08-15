import 'error_sanitizer.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  AppException(String message, {this.statusCode, this.details})
      : message = ErrorSanitizer.sanitizeRawMessage(message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Unable to connect to the server. Please check your internet connection.'])
      : super(ErrorSanitizer.sanitizeRawMessage(message));
}

class ServerException extends AppException {
  ServerException([String message = 'The server encountered an issue. Please try again shortly.', int? statusCode])
      : super(ErrorSanitizer.sanitizeRawMessage(message), statusCode: statusCode);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Session expired or invalid credentials. Please sign in again.', int? statusCode = 401])
      : super(ErrorSanitizer.sanitizeRawMessage(message), statusCode: statusCode);
}

class ForbiddenException extends AppException {
  ForbiddenException([String message = 'You do not have permission to perform this action.', int? statusCode = 403])
      : super(ErrorSanitizer.sanitizeRawMessage(message), statusCode: statusCode);
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'The requested item or listing was not found.', int? statusCode = 404])
      : super(ErrorSanitizer.sanitizeRawMessage(message), statusCode: statusCode);
}

class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  ValidationException(String message, {this.fieldErrors = const {}, int? statusCode = 400})
      : super(ErrorSanitizer.sanitizeRawMessage(message), statusCode: statusCode);

  String get firstError {
    if (fieldErrors.isNotEmpty) {
      final firstKey = fieldErrors.keys.first;
      final errors = fieldErrors[firstKey];
      if (errors != null && errors.isNotEmpty) {
        return '$firstKey: ${errors.first}';
      }
    }
    return message;
  }
}
