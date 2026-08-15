import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../core/errors/app_exceptions.dart';
import '../models/business_registration_model.dart';
import '../models/ngo_model.dart';
import '../models/user_model.dart';
import '../models/verification_document_model.dart';
import '../repositories/auth_repository.dart';
import '../services/profile_api_service.dart';

enum AuthStatus { initial, unauthenticated, authenticating, authenticated, failure }

class AuthProvider extends ChangeNotifier {
  final IAuthRepository _authRepository;
  final ProfileApiService _profileApiService;

  AuthProvider({
    required IAuthRepository authRepository,
    ProfileApiService? profileApiService,
  })  : _authRepository = authRepository,
        _profileApiService = profileApiService ?? ProfileApiService();

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.idle) {
      binding.addPostFrameCallback((_) {
        if (!_isDisposed && hasListeners) {
          super.notifyListeners();
        }
      });
    } else {
      super.notifyListeners();
    }
  }

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.donor;

  final List<VerificationDocumentModel> _businessDocuments =
      VerificationDocumentModel.defaultBusinessDocuments();
  final List<VerificationDocumentModel> _ngoDocuments =
      VerificationDocumentModel.defaultNgoDocuments();

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  UserRole get selectedRole => _selectedRole;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;

  List<VerificationDocumentModel> get businessDocuments => _businessDocuments;
  List<VerificationDocumentModel> get ngoDocuments => _ngoDocuments;

  List<VerificationDocumentModel> getDocumentsForRole(UserRole role) {
    if (role == UserRole.ngo) {
      return _ngoDocuments;
    }
    return _businessDocuments;
  }

  void setSelectedRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Initializes auth state on app launch (Splash screen)
  Future<void> initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_authRepository.isAuthenticated) {
        _currentUser = _authRepository.getCurrentUser();
        if (_currentUser != null) {
          _status = AuthStatus.authenticated;
          // Sync profile from backend
          await syncProfileFromBackend();
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Syncs latest profile data from GET /api/profiles/me/
  Future<void> syncProfileFromBackend() async {
    final token = _currentUser?.token;
    if (token == null || token.isEmpty) return;

    try {
      final profileData = await _profileApiService.getMyProfile(token: token);
      if (profileData.isNotEmpty && _currentUser != null) {
        final String name = profileData['full_name'] ??
            profileData['business_name'] ??
            profileData['organization_name'] ??
            _currentUser!.name;
        final String? orgName = profileData['organization_name'] ??
            profileData['business_name'] ??
            _currentUser!.organizationName;
        final String? address = profileData['address'] ?? _currentUser!.address;
        final String phone = profileData['phone_num'] ?? _currentUser!.phone;
        final String email = profileData['email'] ?? _currentUser!.email;

        _currentUser = _currentUser!.copyWith(
          name: name,
          organizationName: orgName,
          address: address,
          phone: phone,
          email: email,
          profileData: profileData,
        );
        notifyListeners();
      }
    } catch (_) {
      // Keep local state if server is offline
    }
  }

  /// Logs in using phone number and password
  Future<bool> login({
    required String phoneNum,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(
        phoneNum: phoneNum,
        password: password,
        rememberMe: rememberMe,
      );
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ValidationException catch (e) {
      _errorMessage = e.firstError;
      _status = AuthStatus.failure;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.failure;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _status = AuthStatus.failure;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Registers a Customer
  Future<bool> registerCustomer({
    required String phoneNum,
    required String email,
    required String password,
    String? fullName,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      _currentUser = await _authRepository.registerCustomer(
        phoneNum: phoneNum,
        email: email,
        password: password,
        fullName: fullName,
        address: address,
      );
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ValidationException catch (e) {
      _errorMessage = e.firstError;
      _status = AuthStatus.failure;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.failure;
    } catch (e) {
      _errorMessage = 'Failed to register customer account. Please try again.';
      _status = AuthStatus.failure;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Registers a Business / Donor
  Future<bool> registerBusiness({
    required BusinessRegistrationModel model,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      _currentUser = await _authRepository.registerBusiness(model: model);

      if (model.verificationDocumentPath != null && model.verificationDocumentPath!.isNotEmpty) {
        final newDoc = VerificationDocumentModel(
          id: 'biz-reg-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Business Registration Document',
          fileName: model.verificationDocumentPath!.split(RegExp(r'[\\/]')).last,
          type: model.verificationDocumentPath!.toLowerCase().endsWith('.pdf')
              ? VerificationDocumentType.pdf
              : VerificationDocumentType.image,
          status: VerificationDocumentStatus.pending,
          submittedOn: DateTime.now(),
          issuedIdNumber: model.registrationOrPanNumber,
          localFilePath: model.verificationDocumentPath,
          issuerAuthority: 'Submitted during Registration',
        );
        _businessDocuments.insert(0, newDoc);
      }

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ValidationException catch (e) {
      _errorMessage = e.firstError;
      _status = AuthStatus.failure;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.failure;
    } catch (e) {
      _errorMessage = 'Failed to register business account. Please try again.';
      _status = AuthStatus.failure;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Registers an NGO / Recipient
  Future<bool> registerNgo({
    required NgoRegistrationModel model,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      _currentUser = await _authRepository.registerNgo(model: model);

      if (model.documentPath != null && model.documentPath!.isNotEmpty) {
        final newDoc = VerificationDocumentModel(
          id: 'ngo-reg-${DateTime.now().millisecondsSinceEpoch}',
          title: 'NGO Verification Certificate',
          fileName: model.documentName ?? model.documentPath!.split(RegExp(r'[\\/]')).last,
          type: (model.documentName ?? model.documentPath!).toLowerCase().endsWith('.pdf')
              ? VerificationDocumentType.pdf
              : VerificationDocumentType.image,
          status: VerificationDocumentStatus.pending,
          submittedOn: DateTime.now(),
          issuedIdNumber: model.panNumber,
          localFilePath: model.documentPath,
          issuerAuthority: 'Submitted during Registration',
        );
        _ngoDocuments.insert(0, newDoc);
      }

      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ValidationException catch (e) {
      _errorMessage = e.firstError;
      _status = AuthStatus.failure;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.failure;
    } catch (e) {
      _errorMessage = 'Failed to register NGO account. Please try again.';
      _status = AuthStatus.failure;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Updates the current user profile in state and syncs with backend
  Future<void> updateUserProfile({
    String? name,
    String? organizationName,
    String? email,
    String? phone,
    String? address,
    Map<String, dynamic>? additionalProfileData,
    String? documentFilePath,
  }) async {
    if (_currentUser != null) {
      final mergedData = Map<String, dynamic>.from(_currentUser!.profileData ?? {});
      if (additionalProfileData != null) {
        mergedData.addAll(additionalProfileData);
      }

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        organizationName: organizationName ?? _currentUser!.organizationName,
        email: email ?? _currentUser!.email,
        phone: phone ?? _currentUser!.phone,
        address: address ?? _currentUser!.address,
        profileData: mergedData,
      );
      notifyListeners();

      // Sync with backend PATCH /api/profiles/me/
      final token = _currentUser?.token;
      if (token != null && token.isNotEmpty) {
        try {
          final fields = <String, String>{};
          if (name != null) {
            if (_currentUser!.isConsumer) fields['full_name'] = name;
          }
          if (organizationName != null) {
            if (_currentUser!.isDonor) fields['business_name'] = organizationName;
            if (_currentUser!.isNgo) fields['organization_name'] = organizationName;
          }
          if (address != null) fields['address'] = address;
          if (phone != null) fields['phone_num'] = phone;
          if (email != null) fields['email'] = email;

          if (fields.isNotEmpty || documentFilePath != null) {
            await _profileApiService.updateMyProfile(
              token: token,
              fields: fields,
              registrationDocumentPath: documentFilePath,
            );
          }
        } catch (_) {
          // Keep local state update
        }
      }
    }
  }

  /// Updates a verification document in state and syncs with backend
  void updateVerificationDocument(
    VerificationDocumentModel updatedDoc, {
    UserRole? role,
  }) {
    final targetRole = role ?? _currentUser?.role ?? _selectedRole;
    if (targetRole == UserRole.ngo) {
      final index = _ngoDocuments.indexWhere((d) => d.id == updatedDoc.id);
      if (index != -1) {
        _ngoDocuments[index] = updatedDoc;
      } else {
        _ngoDocuments.insert(0, updatedDoc);
      }
    } else {
      final index = _businessDocuments.indexWhere((d) => d.id == updatedDoc.id);
      if (index != -1) {
        _businessDocuments[index] = updatedDoc;
      } else {
        _businessDocuments.insert(0, updatedDoc);
      }
    }
    notifyListeners();

    // If local file was uploaded, sync to backend profile
    if (updatedDoc.localFilePath != null && _currentUser?.token != null) {
      _profileApiService.updateMyProfile(
        token: _currentUser!.token!,
        fields: {},
        registrationDocumentPath: updatedDoc.localFilePath,
      ).catchError((_) => <String, dynamic>{});
    }
  }

  /// Adds a new verification document
  void addVerificationDocument(
    VerificationDocumentModel newDoc, {
    UserRole? role,
  }) {
    final targetRole = role ?? _currentUser?.role ?? _selectedRole;
    if (targetRole == UserRole.ngo) {
      _ngoDocuments.insert(0, newDoc);
    } else {
      _businessDocuments.insert(0, newDoc);
    }
    notifyListeners();

    if (newDoc.localFilePath != null && _currentUser?.token != null) {
      _profileApiService.updateMyProfile(
        token: _currentUser!.token!,
        fields: {},
        registrationDocumentPath: newDoc.localFilePath,
      ).catchError((_) => <String, dynamic>{});
    }
  }

  /// Logs out the user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    }
  }
}
