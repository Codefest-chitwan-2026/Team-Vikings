import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/business_registration_model.dart';
import '../models/ngo_model.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Logs in with phone number and password.
  /// Backend endpoint: POST /api/auth/login/
  Future<Map<String, dynamic>> login({
    required String phoneNum,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.login,
      body: {
        'phone_num': phoneNum,
        'password': password,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Logs out by blacklisting the refresh token.
  /// Backend endpoint: POST /api/auth/logout/
  Future<Map<String, dynamic>> logout({
    required String refreshToken,
    required String accessToken,
  }) async {
    final response = await _client.post(
      ApiConstants.logout,
      token: accessToken,
      body: {
        'refresh': refreshToken,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Registers a Customer profile.
  /// Backend endpoint: POST /api/auth/register/customer/
  Future<Map<String, dynamic>> registerCustomer({
    required String phoneNum,
    required String email,
    required String password,
    String? fullName,
    String? address,
  }) async {
    final response = await _client.post(
      ApiConstants.registerCustomer,
      body: {
        'phone_num': phoneNum,
        'email': email,
        'password': password,
        'full_name': fullName ?? '',
        'address': address ?? '',
      },
    );
    return response as Map<String, dynamic>;
  }

  /// Registers a Business profile with optional document attachment.
  /// Backend endpoint: POST /api/auth/register/business/
  Future<Map<String, dynamic>> registerBusiness({
    required BusinessRegistrationModel model,
  }) async {
    final fields = model.toFormFields();
    final filePaths = <String, String>{};

    if (model.verificationDocumentPath != null &&
        model.verificationDocumentPath!.isNotEmpty) {
      filePaths['registration_document'] = model.verificationDocumentPath!;
    }

    final response = await _client.postMultipart(
      ApiConstants.registerBusiness,
      fields: fields,
      filePaths: filePaths.isNotEmpty ? filePaths : null,
    );
    return response as Map<String, dynamic>;
  }

  /// Registers an NGO profile with optional document attachment.
  /// Backend endpoint: POST /api/auth/register/ngo/
  Future<Map<String, dynamic>> registerNgo({
    required NgoRegistrationModel model,
  }) async {
    final fields = model.toFormFields();
    final filePaths = <String, String>{};

    if (model.documentPath != null && model.documentPath!.isNotEmpty) {
      filePaths['registration_document'] = model.documentPath!;
    }

    final response = await _client.postMultipart(
      ApiConstants.registerNgo,
      fields: fields,
      filePaths: filePaths.isNotEmpty ? filePaths : null,
    );
    return response as Map<String, dynamic>;
  }
}
