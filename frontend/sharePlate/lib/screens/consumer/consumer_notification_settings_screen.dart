import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/shared/profile/settings_switch_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';

class ConsumerNotificationSettingsScreen extends StatefulWidget {
  const ConsumerNotificationSettingsScreen({super.key});

  @override
  State<ConsumerNotificationSettingsScreen> createState() =>
      _ConsumerNotificationSettingsScreenState();
}

class _ConsumerNotificationSettingsScreenState
    extends State<ConsumerNotificationSettingsScreen> {
  bool _orderConfirmations = true;
  bool _pickupReminders = true;
  bool _nearbyDeals = true;
  bool _orderUpdates = true;
  bool _weeklySummary = false;
  bool _pushEnabled = true;
  bool _emailEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final token = auth.currentUser?.token;
      if (token != null && token.isNotEmpty) {
        context.read<NotificationProvider>().fetchPreferences(token: token);
      }
    });
  }

  void _syncSettings(NotificationProvider notifProvider, String? token) {
    if (token != null && token.isNotEmpty) {
      final updated = NotificationPreferencesModel(
        emailNotifications: _emailEnabled,
        pushNotifications: _pushEnabled,
        smsAlerts: _orderConfirmations,
        expiryReminders: _pickupReminders,
        claimAlerts: _orderUpdates,
        marketingUpdates: _nearbyDeals,
      );
      notifProvider.updatePreferences(token: token, updated: updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final token = auth.currentUser?.token;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SimpleAppBar(title: 'Notification settings'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            const SettingsSectionLabel(label: 'DELIVERY METHOD'),
            SettingsSwitchTile(
              title: 'Push notifications',
              subtitle: 'Get alerts on this device as things happen.',
              value: _pushEnabled,
              onChanged: (value) {
                setState(() => _pushEnabled = value);
                _syncSettings(notifProvider, token);
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Email notifications',
              subtitle: 'Get a copy of important updates in your inbox.',
              value: _emailEnabled,
              onChanged: (value) {
                setState(() => _emailEnabled = value);
                _syncSettings(notifProvider, token);
              },
            ),
            const SizedBox(height: 20),
            const SettingsSectionLabel(label: 'WHAT YOU HEAR ABOUT'),
            SettingsSwitchTile(
              title: 'Order confirmations',
              subtitle: 'When your order is confirmed by the seller.',
              value: _orderConfirmations,
              onChanged: (value) {
                setState(() => _orderConfirmations = value);
                _syncSettings(notifProvider, token);
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Pickup reminders',
              subtitle: 'A reminder shortly before your pickup window closes.',
              value: _pickupReminders,
              onChanged: (value) {
                setState(() => _pickupReminders = value);
                _syncSettings(notifProvider, token);
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'New deals nearby',
              subtitle: 'Flash-sale listings posted close to your location.',
              value: _nearbyDeals,
              onChanged: (value) {
                setState(() => _nearbyDeals = value);
                _syncSettings(notifProvider, token);
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Order updates',
              subtitle: 'When an order is picked up or marked completed.',
              value: _orderUpdates,
              onChanged: (value) {
                setState(() => _orderUpdates = value);
                _syncSettings(notifProvider, token);
              },
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Weekly savings summary',
              subtitle: 'A weekly recap of what you saved and rescued.',
              value: _weeklySummary,
              onChanged: (value) {
                setState(() => _weeklySummary = value);
                _syncSettings(notifProvider, token);
              },
            ),
          ],
        ),
      ),
    );
  }
}