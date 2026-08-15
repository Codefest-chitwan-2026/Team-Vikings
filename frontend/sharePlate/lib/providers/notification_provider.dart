import 'package:flutter/material.dart';
import '../core/errors/error_sanitizer.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final INotificationRepository _notificationRepository;

  NotificationProvider({INotificationRepository? notificationRepository})
      : _notificationRepository = notificationRepository ?? NotificationRepository();

  List<NotificationItem> _notifications = [];
  NotificationPreferencesModel _preferences = const NotificationPreferencesModel();
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  NotificationPreferencesModel get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchNotifications({required String? token}) async {
    if (token == null || token.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _notificationRepository.getNotifications(token: token);
      _notifications = list;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultMessage: 'Unable to load notifications.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead({required String? token, required dynamic id}) async {
    if (token == null || token.isEmpty) return;

    try {
      await _notificationRepository.markAsRead(token: token, id: id);
      final idx = _notifications.indexWhere((n) => n.id == id.toString());
      if (idx != -1) {
        final old = _notifications[idx];
        _notifications[idx] = NotificationItem(
          id: old.id,
          title: old.title,
          message: old.message,
          timeAgo: old.timeAgo,
          type: old.type,
          isRead: true,
          targetId: old.targetId,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead({required String? token}) async {
    if (token == null || token.isEmpty) return;

    try {
      await _notificationRepository.markAllAsRead(token: token);
      _notifications = _notifications
          .map((n) => NotificationItem(
                id: n.id,
                title: n.title,
                message: n.message,
                timeAgo: n.timeAgo,
                type: n.type,
                isRead: true,
                targetId: n.targetId,
              ))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchPreferences({required String? token}) async {
    if (token == null || token.isEmpty) return;

    try {
      _preferences = await _notificationRepository.getPreferences(token: token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updatePreferences({
    required String? token,
    required NotificationPreferencesModel updated,
  }) async {
    if (token == null || token.isEmpty) return;

    _preferences = updated;
    notifyListeners();

    try {
      await _notificationRepository.updatePreferences(
        token: token,
        preferences: updated,
      );
    } catch (_) {}
  }
}
