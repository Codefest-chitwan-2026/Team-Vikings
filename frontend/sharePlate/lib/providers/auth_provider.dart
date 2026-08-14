import 'package:flutter/foundation.dart';
import '../core/errors/app_exceptions.dart';
import '../models/business_registration_model.dart';
import '../models/ngo_model.dart';
import '../models/user_model.dart';
import '../models/verification_document_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { initial, unauthenticated, authenticating, authenticated, failure }

class AuthProvider extends ChangeNotifier {
  final IAuthRepository _authRepository;

  AuthProvider({required IAuthRepository authRepository})
      : _authRepository = authRepository;

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

  /// Updates the current user profile in state
  void updateUserProfile({
    String? name,
    String? organizationName,
    String? email,
    String? phone,
    String? address,
    Map<String, dynamic>? additionalProfileData,
  }) {
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
    }
  }

  /// Updates a verification document in state
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
