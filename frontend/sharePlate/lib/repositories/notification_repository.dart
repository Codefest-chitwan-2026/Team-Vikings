import '../models/notification_model.dart';
import '../services/notifications_api_service.dart';

abstract class INotificationRepository {
  Future<List<NotificationItem>> getNotifications({required String token});

  Future<void> markAsRead({required String token, required dynamic id});

  Future<void> markAllAsRead({required String token});

  Future<NotificationPreferencesModel> getPreferences({required String token});

  Future<NotificationPreferencesModel> updatePreferences({
    required String token,
    required NotificationPreferencesModel preferences,
  });
}

class NotificationRepository implements INotificationRepository {
  final NotificationsApiService _apiService;

  NotificationRepository({NotificationsApiService? apiService})
      : _apiService = apiService ?? NotificationsApiService();

  @override
  Future<List<NotificationItem>> getNotifications({required String token}) async {
    final list = await _apiService.getNotifications(token: token);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => NotificationItem.fromJson(e))
        .toList();
  }

  @override
  Future<void> markAsRead({required String token, required dynamic id}) async {
    await _apiService.markAsRead(token: token, id: id);
  }

  @override
  Future<void> markAllAsRead({required String token}) async {
    await _apiService.markAllAsRead(token: token);
  }

  @override
  Future<NotificationPreferencesModel> getPreferences({required String token}) async {
    final res = await _apiService.getPreferences(token: token);
    if (res.isNotEmpty) {
      return NotificationPreferencesModel.fromJson(res);
    }
    return const NotificationPreferencesModel();
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences({
    required String token,
    required NotificationPreferencesModel preferences,
  }) async {
    final res = await _apiService.updatePreferences(
      token: token,
      preferences: preferences.toJson(),
    );
    return NotificationPreferencesModel.fromJson(res);
  }
}
