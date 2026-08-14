import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shareplate/models/business_registration_model.dart';
import 'package:shareplate/models/ngo_model.dart';
import 'package:shareplate/models/user_model.dart';
import 'package:shareplate/providers/auth_provider.dart';
import 'package:shareplate/repositories/auth_repository.dart';
import 'package:shareplate/services/auth_api_service.dart';
import 'package:shareplate/services/storage_service.dart';

// Fake API Service for testing without real backend
class FakeAuthApiService extends AuthApiService {
  bool shouldFail = false;

  @override
  Future<Map<String, dynamic>> login({
    required String phoneNum,
    required String password,
  }) async {
    if (shouldFail) {
      throw Exception('Invalid phone number or password.');
    }
    return {
      'message': 'Login successful',
      'user': {
        'id': 1,
        'phone_num': phoneNum,
        'email': 'user@example.com',
        'role': 'CUSTOMER',
      },
      'profile': {
        'id': 1,
        'user': 1,
        'full_name': 'Test Customer',
        'address': 'Kathmandu',
      },
      'access': 'fake_access_token_123',
      'refresh': 'fake_refresh_token_456',
    };
  }

  @override
  Future<Map<String, dynamic>> logout({
    required String refreshToken,
    required String accessToken,
  }) async {
    return {'message': 'Logout successful'};
  }

  @override
  Future<Map<String, dynamic>> registerCustomer({
    required String phoneNum,
    required String email,
    required String password,
    String? fullName,
    String? address,
  }) async {
    return {
      'message': 'Customer registered successfully',
      'user': {
        'id': 2,
        'phone_num': phoneNum,
        'email': email,
        'role': 'CUSTOMER',
      },
      'profile': {
        'id': 2,
        'user': 2,
        'full_name': fullName ?? '',
        'address': address ?? '',
      },
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserModel parsing tests', () {
    test('Correctly parses Customer from DRF response', () {
      final json = {
        'message': 'Login successful',
        'user': {
          'id': 10,
          'phone_num': '9812345678',
          'email': 'customer@test.com',
          'role': 'CUSTOMER',
        },
        'profile': {
          'id': 5,
          'user': 10,
          'full_name': 'Aarav Sharma',
          'address': 'Chitwan',
        },
        'access': 'access_token_xyz',
        'refresh': 'refresh_token_xyz',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '10');
      expect(user.phone, '9812345678');
      expect(user.email, 'customer@test.com');
      expect(user.role, UserRole.consumer);
      expect(user.name, 'Aarav Sharma');
      expect(user.address, 'Chitwan');
      expect(user.token, 'access_token_xyz');
      expect(user.isConsumer, isTrue);
      expect(user.isDonor, isFalse);
    });

    test('Correctly parses Business/Donor from DRF response', () {
      final json = {
        'user': {
          'id': 12,
          'phone_num': '9841000000',
          'email': 'bakery@test.com',
          'role': 'BUSINESS',
        },
        'profile': {
          'id': 7,
          'business_name': 'Himalayan Bakery',
          'registration_number': 'PAN-9988',
        },
        'access': 'biz_token',
      };

      final user = UserModel.fromJson(json);
      expect(user.role, UserRole.donor);
      expect(user.name, 'Himalayan Bakery');
      expect(user.displayName, 'Himalayan Bakery');
      expect(user.isDonor, isTrue);
    });

    test('Correctly parses NGO from DRF response', () {
      final json = {
        'user': {
          'id': 15,
          'phone_num': '9865000000',
          'email': 'ngo@test.org',
          'role': 'NGO',
        },
        'profile': {
          'id': 9,
          'organization_name': 'Hope Shelter',
          'organization_type': 'NGO',
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.role, UserRole.ngo);
      expect(user.name, 'Hope Shelter');
      expect(user.isNgo, isTrue);
    });
  });

  group('Registration Model Form Fields', () {
    test('BusinessRegistrationModel converts fields properly for backend', () {
      final model = BusinessRegistrationModel(
        businessName: 'Cafe Everest',
        phoneNumber: '9800000000',
        email: 'cafe@everest.com',
        password: 'password123',
        addressText: 'Pokhara Lakeside',
        registrationOrPanNumber: '600123456',
        latitude: 28.2096,
        longitude: 83.9856,
      );

      final fields = model.toFormFields();
      expect(fields['business_name'], 'Cafe Everest');
      expect(fields['phone_num'], '9800000000');
      expect(fields['registration_number'], '600123456');
      expect(fields['latitude'], '28.2096');
      expect(fields['longitude'], '83.9856');
    });

    test('NgoRegistrationModel maps backend choice values properly', () {
      final model = NgoRegistrationModel(
        organizationName: 'Bal Mandir Orphanage',
        phoneNumber: '9841112233',
        email: 'balmandir@org.np',
        password: 'password123',
        addressText: 'Naxal, Kathmandu',
        panNumber: '300123456',
        organizationType: NgoOrganizationType.orphanage,
        latitude: 27.7172,
        longitude: 85.3240,
      );

      final fields = model.toFormFields();
      expect(fields['organization_name'], 'Bal Mandir Orphanage');
      expect(fields['organization_type'], 'Orphange'); // Matches Django backend choices
      expect(fields['registration_number'], '300123456');
    });
  });

  group('Auth Layer Integration with Storage and Provider', () {
    late StorageService storageService;
    late FakeAuthApiService apiService;
    late AuthRepository repository;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      apiService = FakeAuthApiService();
      repository = AuthRepository(
        apiService: apiService,
        storageService: storageService,
      );
      authProvider = AuthProvider(authRepository: repository);
    });

    test('Full login flow updates storage, repository and provider state', () async {
      expect(authProvider.isAuthenticated, isFalse);

      final success = await authProvider.login(
        phoneNum: '9800000000',
        password: 'password123',
        rememberMe: true,
      );

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.phone, '9800000000');
      expect(authProvider.currentUser?.token, 'fake_access_token_123');

      // Verify persistent storage
      expect(storageService.getAccessToken(), 'fake_access_token_123');
      expect(storageService.getRefreshToken(), 'fake_refresh_token_456');
      expect(storageService.getRememberMe(), isTrue);
      expect(storageService.getUser()?.phone, '9800000000');
    });

    test('Logout clears storage and provider state', () async {
      await authProvider.login(
        phoneNum: '9800000000',
        password: 'password123',
      );
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(storageService.getAccessToken(), isNull);
      expect(storageService.getUser(), isNull);
    });

    test('Customer registration auto-logins and persists user', () async {
      final success = await authProvider.registerCustomer(
        phoneNum: '9811223344',
        email: 'customer@test.com',
        password: 'password123',
        fullName: 'Ram Bahadur',
        address: 'Bharatpur',
      );

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.phone, '9811223344');
    });
  });
}
