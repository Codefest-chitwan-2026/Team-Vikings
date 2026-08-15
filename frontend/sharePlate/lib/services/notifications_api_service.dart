import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class NotificationsApiService {
  final ApiClient _apiClient;

  NotificationsApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /api/notifications/
  Future<List<dynamic>> getNotifications({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.notifications,
      token: token,
    );
    return response is List ? response : [];
  }

  /// PATCH /api/notifications/{id}/read/
  Future<Map<String, dynamic>> markAsRead({
    required String token,
    required dynamic id,
  }) async {
    final response = await _apiClient.patch(
      ApiConstants.notificationRead(id),
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/notifications/read-all/
  Future<Map<String, dynamic>> markAllAsRead({required String token}) async {
    final response = await _apiClient.post(
      ApiConstants.notificationReadAll,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// GET /api/notification-settings/
  Future<Map<String, dynamic>> getPreferences({required String token}) async {
    final response = await _apiClient.get(
      ApiConstants.notificationSettings,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  /// POST /api/notification-settings/
  Future<Map<String, dynamic>> updatePreferences({
    required String token,
    required Map<String, dynamic> preferences,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.notificationSettings,
      body: preferences,
      token: token,
    );
    return response is Map<String, dynamic> ? response : {};
  }
}
