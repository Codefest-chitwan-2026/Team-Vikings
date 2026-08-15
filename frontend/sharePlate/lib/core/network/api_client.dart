import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../errors/app_exceptions.dart';
import '../errors/error_sanitizer.dart';
import '../../services/storage_service.dart';

class ApiClient {
  final http.Client _client;
  final StorageService? _storageService;

  /// Called after a silent token refresh succeeds, so callers (e.g. AuthProvider)
  /// can keep their in-memory copy of the access token in sync.
  void Function(String newAccessToken, String newRefreshToken)? onTokensRefreshed;

  /// Called when the refresh token itself is invalid/expired, meaning the user
  /// needs to log in again. Callers should use this to force a logout.
  void Function()? onSessionExpired;

  // Coalesces concurrent refresh attempts into a single in-flight request.
  Future<String?>? _refreshInFlight;

  ApiClient({http.Client? client, StorageService? storageService})
      : _client = client ?? http.Client(),
        _storageService = storageService;

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

  /// Runs [send] with the given token. If it fails with a 401, attempts a
  /// silent token refresh and retries exactly once with the new token.
  Future<dynamic> _sendWithRefresh({
    required String? token,
    required Future<dynamic> Function(String? token) send,
  }) async {
    try {
      return await send(token);
    } on UnauthorizedException {
      if (token == null || token.isEmpty || _storageService == null) {
        rethrow;
      }
      final newToken = await _refreshAccessToken();
      if (newToken == null) {
        onSessionExpired?.call();
        rethrow;
      }
      try {
        return await send(newToken);
      } on UnauthorizedException {
        // Even the refreshed token was rejected — the session is truly done.
        onSessionExpired?.call();
        rethrow;
      }
    }
  }

  Future<String?> _refreshAccessToken() {
    // If a refresh is already underway (e.g. several requests hit 401 at
    // once), share the same attempt instead of firing multiple refreshes.
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _doRefresh();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
    return future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = _storageService?.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final uri = Uri.parse(ApiConstants.refresh);
      final response = await _client
          .post(
        uri,
        headers: _buildHeaders(),
        body: jsonEncode({'refresh': refreshToken}),
      )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.body.isEmpty) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final newAccess = decoded['access']?.toString();
      if (newAccess == null || newAccess.isEmpty) return null;

      // Some backends rotate the refresh token on every use; keep the old
      // one if a new one isn't returned.
      final newRefresh = decoded['refresh']?.toString() ?? refreshToken;

      await _storageService!.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      onTokensRefreshed?.call(newAccess, newRefresh);
      return newAccess;
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> get(
      String url, {
        String? token,
        Map<String, String>? headers,
      }) {
    return _sendWithRefresh(
      token: token,
      send: (t) => _rawGet(url, token: t, headers: headers),
    );
  }

  Future<dynamic> _rawGet(String url, {String? token, Map<String, String>? headers}) async {
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
      }) {
    return _sendWithRefresh(
      token: token,
      send: (t) => _rawPost(url, body: body, token: t, headers: headers),
    );
  }

  Future<dynamic> _rawPost(
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
      }) {
    return _sendWithRefresh(
      token: token,
      send: (t) => _rawPut(url, body: body, token: t, headers: headers),
    );
  }

  Future<dynamic> _rawPut(
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
      }) {
    return _sendWithRefresh(
      token: token,
      send: (t) => _rawPatch(url, body: body, token: t, headers: headers),
    );
  }

  Future<dynamic> _rawPatch(
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
      }) {
    return _sendWithRefresh(
      token: token,
      send: (t) => _rawDelete(url, token: t, headers: headers),
    );
  }

  Future<dynamic> _rawDelete(String url, {String? token, Map<String, String>? headers}) async {
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
      }) {
    return _sendWithRefresh(
      token: token,
      send: (t) => _rawPostMultipart(url, fields: fields, filePaths: filePaths, token: t, method: method),
    );
  }

  Future<dynamic> _rawPostMultipart(
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