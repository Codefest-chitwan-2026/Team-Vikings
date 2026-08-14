class AppException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Network connection failed. Please check your internet.']);
}

class ServerException extends AppException {
  ServerException([super.message = 'Server error occurred. Please try again later.', int? statusCode])
      : super(statusCode: statusCode);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Session expired or unauthorized. Please log in again.', int? statusCode = 401])
      : super(statusCode: statusCode);
}

class ValidationException extends AppException {
  final Map<String, List<String>> fieldErrors;

  ValidationException(super.message, {this.fieldErrors = const {}, super.statusCode = 400});

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
