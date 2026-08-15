import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../errors/app_exceptions.dart';
import '../errors/error_sanitizer.dart';

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders({String? token, Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<dynamic> get(
    String url, {
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .get(uri, headers: _buildHeaders(token: token, extraHeaders: headers))
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out. Please check your internet connection.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorSanitizer.sanitize(e));
    }
  }

  Future<dynamic> post(
    String url, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: encodedBody,
          )
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out. Please check your internet connection.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorSanitizer.sanitize(e));
    }
  }

  Future<dynamic> put(
    String url, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: encodedBody,
          )
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out. Please check your internet connection.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorSanitizer.sanitize(e));
    }
  }

  Future<dynamic> patch(
    String url, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final encodedBody = body != null ? jsonEncode(body) : null;
      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(token: token, extraHeaders: headers),
            body: encodedBody,
          )
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out. Please check your internet connection.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorSanitizer.sanitize(e));
    }
  }

  Future<dynamic> delete(
    String url, {
    String? token,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .delete(uri, headers: _buildHeaders(token: token, extraHeaders: headers))
          .timeout(ApiConstants.connectTimeout);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out. Please check your internet connection.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorSanitizer.sanitize(e));
    }
  }

  Future<dynamic> postMultipart(
    String url, {
    required Map<String, String> fields,
    Map<String, String>? filePaths,
    String? token,
    String method = 'POST',
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest(method, uri);

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      request.fields.addAll(fields);

      if (filePaths != null) {
        for (final entry in filePaths.entries) {
          final filePath = entry.value;
          if (filePath.isNotEmpty) {
            final file = File(filePath);
            if (await file.exists()) {
              request.files.add(
                await http.MultipartFile.fromPath(entry.key, filePath),
              );
            }
          }
        }
      }

      final streamedResponse = await request.send().timeout(ApiConstants.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw NetworkException();
    } on TimeoutException catch (_) {
      throw NetworkException('Request timed out. Please check your internet connection.');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorSanitizer.sanitize(e));
    }
  }

  Future<dynamic> patchMultipart(
    String url, {
    required Map<String, String> fields,
    Map<String, String>? filePaths,
    String? token,
  }) {
    return postMultipart(url, fields: fields, filePaths: filePaths, token: token, method: 'PATCH');
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body;

    dynamic decodedData;
    if (bodyString.isNotEmpty) {
      try {
        decodedData = jsonDecode(bodyString);
      } catch (_) {
        decodedData = {'message': bodyString};
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decodedData ?? {};
    }

    final rawErrorMessage = _extractRawErrorMessage(decodedData, statusCode);
    final sanitizedMessage = ErrorSanitizer.sanitizeRawMessage(rawErrorMessage);

    if (statusCode == 401) {
      throw UnauthorizedException(sanitizedMessage, statusCode);
    } else if (statusCode == 403) {
      throw ForbiddenException(sanitizedMessage, statusCode);
    } else if (statusCode == 404) {
      throw NotFoundException(sanitizedMessage, statusCode);
    } else if (statusCode == 400) {
      final sanitizedFieldErrors = decodedData is Map<String, dynamic>
          ? ErrorSanitizer.sanitizeFieldErrors(decodedData)
          : <String, List<String>>{};
      throw ValidationException(sanitizedMessage, fieldErrors: sanitizedFieldErrors, statusCode: statusCode);
    } else if (statusCode >= 500) {
      throw ServerException(sanitizedMessage, statusCode);
    } else {
      throw AppException(sanitizedMessage, statusCode: statusCode, details: decodedData is Map<String, dynamic> ? decodedData : null);
    }
  }

  String _extractRawErrorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('error') && decoded['error'] != null) {
        return decoded['error'].toString();
      }
      if (decoded.containsKey('detail') && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
      if (decoded.containsKey('message') && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded.containsKey('non_field_errors') && decoded['non_field_errors'] is List) {
        final list = decoded['non_field_errors'] as List;
        if (list.isNotEmpty) return list.first.toString();
      }
      for (final entry in decoded.entries) {
        if (entry.value is List && (entry.value as List).isNotEmpty) {
          return '${entry.key}: ${(entry.value as List).first}';
        } else if (entry.value is String) {
          return '${entry.key}: ${entry.value}';
        }
      }
    }
    return 'Request failed with status $statusCode';
  }
}
