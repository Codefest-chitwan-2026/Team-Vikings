import 'dart:io';
import 'app_exceptions.dart';

class ErrorSanitizer {
  /// Sanitizes any raw exception, error message, status code, or backend payload
  /// into a clean, human-friendly message suitable for UI display.
  static String sanitize(
    dynamic error, {
    String? defaultMessage,
  }) {
    if (error == null) {
      return defaultMessage ?? 'An unexpected error occurred. Please try again.';
    }

    if (error is ValidationException) {
      return error.firstError;
    }

    if (error is UnauthorizedException) {
      return 'Incorrect credentials or session expired. Please sign in again.';
    }

    if (error is NetworkException) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    if (error is ServerException) {
      return 'The server encountered an issue. Please try again in a few moments.';
    }

    if (error is SocketException) {
      return 'Unable to reach the server. Please ensure you are connected to the internet.';
    }

    if (error is FormatException) {
      return 'Received invalid response format. Please try again.';
    }

    final rawString = error.toString().trim();

    return sanitizeRawMessage(rawString, defaultMessage: defaultMessage);
  }

  /// Sanitizes raw error strings (such as DRF error strings, Python traces, or HTTP bodies)
  static String sanitizeRawMessage(
    String raw, {
    String? defaultMessage,
  }) {
    final lower = raw.toLowerCase();

    // Sensitive or technical internals to block
    if (lower.contains('traceback') ||
        lower.contains('integrityerror') ||
        lower.contains('syntaxerror') ||
        lower.contains('operationalerror') ||
        lower.contains('nosuchmethoderror') ||
        lower.contains('nullcheckoperator') ||
        lower.contains('typeerror') ||
        lower.contains('sqlite3') ||
        lower.contains('django.') ||
        lower.contains('rest_framework') ||
        lower.contains('connection refused') ||
        lower.contains('errno =') ||
        lower.contains('http/1.1 500') ||
        lower.contains('internal server error')) {
      return defaultMessage ?? 'A system error occurred. Please try again later.';
    }

    // Common backend validation mappings
    if (lower.contains('phone number already exists') ||
        lower.contains('phone_num already exists') ||
        lower.contains('unique constraint failed: users_user.phone_num')) {
      return 'This phone number is already registered. Please sign in or use another number.';
    }

    if (lower.contains('email already exists') ||
        lower.contains('unique constraint failed: users_user.email')) {
      return 'This email address is already in use. Please sign in or use another email.';
    }

    if (lower.contains('phone number, email, and password are required')) {
      return 'Phone number, email, and password are required.';
    }

    if (lower.contains('invalid credentials') ||
        lower.contains('unable to log in') ||
        lower.contains('no active account found') ||
        lower.contains('invalid phone number or password') ||
        lower.contains('invalid email or password') ||
        lower.contains('invalid email or pass') ||
        lower.contains('invalid phone number') ||
        lower.contains('invalid password') ||
        lower.contains('invalid_credentials')) {
      return 'Invalid email or password';
    }

    if (lower.contains('only business users can create donations') ||
        lower.contains('only business users can publish')) {
      return 'Only verified business donor accounts can publish food listings.';
    }

    if (lower.contains('only ngo users can access priority listings') ||
        lower.contains('only ngo users can claim donations') ||
        lower.contains('only ngo users')) {
      return 'Priority listings and claims are reserved for verified NGO accounts.';
    }

    if (lower.contains('only consumers can reserve flash sales') ||
        lower.contains('only consumers')) {
      return 'Only consumer accounts can reserve flash sale deals.';
    }

    if (lower.contains('priority window has expired') ||
        lower.contains('ngo priority window has expired')) {
      return 'The NGO priority window for this donation has expired.';
    }

    if (lower.contains('no longer available') ||
        lower.contains('is no longer available')) {
      return 'This food listing is no longer available.';
    }

    if (lower.contains('already been claimed') ||
        lower.contains('has already been claimed')) {
      return 'This donation listing has already been claimed.';
    }

    if (lower.contains('already reserved') ||
        lower.contains('have already reserved')) {
      return 'You have already reserved this listing.';
    }

    if (lower.contains('only the donor can adjust price') ||
        lower.contains('only the donor can')) {
      return 'Only the original donor has permission to modify this listing.';
    }

    if (lower.contains('invalid qr code') ||
        lower.contains('invalid manual code') ||
        lower.contains('invalid code')) {
      return 'The pickup verification code is invalid or has expired.';
    }

    if (lower.contains('pickup has already been verified') ||
        lower.contains('already verified')) {
      return 'This pickup has already been verified and completed.';
    }

    if (lower.contains('not allowed to view this qr') ||
        lower.contains('this pickup is not for your listing')) {
      return 'You do not have permission to view or verify this pickup ticket.';
    }

    if (lower.contains('cannot be cancelled')) {
      return 'This listing is already in progress and cannot be cancelled.';
    }

    // Clean up Exception: prefix if present
    var clean = raw;
    if (clean.startsWith('Exception: ')) {
      clean = clean.substring(11).trim();
    }
    if (clean.startsWith('AppException: ')) {
      clean = clean.substring(14).trim();
    }

    // Check if the clean message is reasonable or still technical
    if (clean.length > 200 || clean.contains('{') || clean.contains('[')) {
      return defaultMessage ?? 'Unable to complete request. Please try again.';
    }

    return clean.isNotEmpty ? clean : (defaultMessage ?? 'An error occurred. Please try again.');
  }

  /// Sanitizes field-specific error maps from DRF (e.g. `{"phone_num": ["..."]}`)
  static Map<String, List<String>> sanitizeFieldErrors(Map<String, dynamic> rawErrors) {
    final cleanMap = <String, List<String>>{};

    rawErrors.forEach((key, val) {
      final fieldName = _humanizeFieldName(key);
      final List<String> errorMessages = [];

      if (val is List) {
        for (final item in val) {
          errorMessages.add(sanitizeRawMessage(item.toString()));
        }
      } else if (val is String) {
        errorMessages.add(sanitizeRawMessage(val));
      } else if (val is Map) {
        errorMessages.add('Please check the provided $fieldName.');
      }

      if (errorMessages.isNotEmpty) {
        cleanMap[fieldName] = errorMessages;
      }
    });

    return cleanMap;
  }

  static String _humanizeFieldName(String field) {
    switch (field.toLowerCase()) {
      case 'phone_num':
      case 'phone':
        return 'Phone Number';
      case 'email':
        return 'Email Address';
      case 'password':
        return 'Password';
      case 'full_name':
        return 'Full Name';
      case 'business_name':
        return 'Business Name';
      case 'organization_name':
        return 'Organization Name';
      case 'address':
        return 'Address';
      case 'pickup_address':
        return 'Pickup Address';
      case 'registration_number':
        return 'Registration Number';
      case 'flash_sale_price':
        return 'Flash Sale Price';
      case 'best_before':
        return 'Best Before Date/Time';
      case 'quantity':
        return 'Quantity';
      case 'quantity_unit':
        return 'Unit';
      case 'food_type':
        return 'Food Category';
      default:
        return field.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1);
        }).join(' ');
    }
  }
}
