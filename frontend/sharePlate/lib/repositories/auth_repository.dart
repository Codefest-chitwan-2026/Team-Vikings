import '../models/business_registration_model.dart';
import '../models/ngo_model.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../services/storage_service.dart';

abstract class IAuthRepository {
  Future<UserModel> login({
    required String phoneNum,
    required String password,
    bool rememberMe = false,
  });

  Future<void> logout();

  Future<UserModel> registerCustomer({
    required String phoneNum,
    required String email,
    required String password,
    String? fullName,
    String? address,
    bool autoLogin = true,
  });

  Future<UserModel> registerBusiness({
    required BusinessRegistrationModel model,
    bool autoLogin = true,
  });

  Future<UserModel> registerNgo({
    required NgoRegistrationModel model,
    bool autoLogin = true,
  });

  UserModel? getCurrentUser();
  bool get isAuthenticated;
  String? getAccessToken();
  bool getRememberMe();
  String? getSavedPhone();
}

class AuthRepository implements IAuthRepository {
  final AuthApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    required AuthApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  @override
  bool get isAuthenticated => _storageService.hasValidToken;

  @override
  UserModel? getCurrentUser() => _storageService.getUser();

  @override
  String? getAccessToken() => _storageService.getAccessToken();

  @override
  bool getRememberMe() => _storageService.getRememberMe();

  @override
  String? getSavedPhone() => _storageService.getSavedPhone();

  @override
  Future<UserModel> login({
    required String phoneNum,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _apiService.login(
      phoneNum: phoneNum,
      password: password,
    );

    final user = UserModel.fromJson(response);
    final accessToken = response['access']?.toString() ?? '';
    final refreshToken = response['refresh']?.toString() ?? '';

    if (accessToken.isNotEmpty) {
      await _storageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await _storageService.saveUser(user);
    }

    await _storageService.saveRememberMe(rememberMe, phone: phoneNum);

    return user;
  }

  @override
  Future<void> logout() async {
    final accessToken = _storageService.getAccessToken();
    final refreshToken = _storageService.getRefreshToken();

    if (refreshToken != null && accessToken != null) {
      try {
        await _apiService.logout(
          refreshToken: refreshToken,
          accessToken: accessToken,
        );
      } catch (_) {
        // Backend blacklist failure should not prevent local logout
      }
    }

    await _storageService.clearAuth();
  }

  @override
  Future<UserModel> registerCustomer({
    required String phoneNum,
    required String email,
    required String password,
    String? fullName,
    String? address,
    bool autoLogin = true,
  }) async {
    final response = await _apiService.registerCustomer(
      phoneNum: phoneNum,
      email: email,
      password: password,
      fullName: fullName,
      address: address,
    );

    if (autoLogin) {
      try {
        return await login(phoneNum: phoneNum, password: password);
      } catch (_) {
        // Fall back to returned registration model if autoLogin fails
      }
    }

    final user = UserModel.fromJson(response);
    return user;
  }

  @override
  Future<UserModel> registerBusiness({
    required BusinessRegistrationModel model,
    bool autoLogin = true,
  }) async {
    final response = await _apiService.registerBusiness(model: model);

    if (autoLogin) {
      try {
        return await login(
          phoneNum: model.phoneNumber,
          password: model.password,
        );
      } catch (_) {
        // Fall back to returned model if autoLogin fails
      }
    }

    final user = UserModel.fromJson(response);
    return user;
  }

  @override
  Future<UserModel> registerNgo({
    required NgoRegistrationModel model,
    bool autoLogin = true,
  }) async {
    final response = await _apiService.registerNgo(model: model);

    if (autoLogin) {
      try {
        return await login(
          phoneNum: model.phoneNumber,
          password: model.password,
        );
      } catch (_) {
        // Fall back to returned model if autoLogin fails
      }
    }

    final user = UserModel.fromJson(response);
    return user;
  }
}
