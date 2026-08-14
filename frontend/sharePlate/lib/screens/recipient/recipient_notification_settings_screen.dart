import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/shared/profile/settings_switch_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';

/// Notification Settings screen for the recipient (NGO) role.
/// TODO: load the initial toggle values from the signed-in NGO's saved
/// preferences and persist changes through the settings-update API.
class RecipientNotificationSettingsScreen extends StatefulWidget {
  const RecipientNotificationSettingsScreen({super.key});

  @override
  State<RecipientNotificationSettingsScreen> createState() =>
      _RecipientNotificationSettingsScreenState();
}

class _RecipientNotificationSettingsScreenState
    extends State<RecipientNotificationSettingsScreen> {
  bool _newListingsNearby = true;
  bool _claimConfirmations = true;
  bool _pickupReminders = true;
  bool _pickupUpdates = true;
  bool _weeklySummary = false;
  bool _pushEnabled = true;
  bool _emailEnabled = true;

  @override
  Widget build(BuildContext context) {
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
              onChanged: (value) => setState(() => _pushEnabled = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Email notifications',
              subtitle: 'Get a copy of important updates in your inbox.',
              value: _emailEnabled,
              onChanged: (value) => setState(() => _emailEnabled = value),
            ),
            const SizedBox(height: 20),
            const SettingsSectionLabel(label: 'WHAT YOU HEAR ABOUT'),
            SettingsSwitchTile(
              title: 'New listings nearby',
              subtitle: 'When a donor posts a listing close to your organization.',
              value: _newListingsNearby,
              onChanged: (value) => setState(() => _newListingsNearby = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Claim confirmations',
              subtitle: 'When a claim you made is accepted by the donor.',
              value: _claimConfirmations,
              onChanged: (value) => setState(() => _claimConfirmations = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Pickup window reminders',
              subtitle: 'A reminder shortly before a pickup window closes.',
              value: _pickupReminders,
              onChanged: (value) => setState(() => _pickupReminders = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Pickup updates',
              subtitle: 'When one of your pickups is marked completed.',
              value: _pickupUpdates,
              onChanged: (value) => setState(() => _pickupUpdates = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Weekly impact summary',
              subtitle: 'A weekly recap of what your organization received.',
              value: _weeklySummary,
              onChanged: (value) => setState(() => _weeklySummary = value),
            ),
          ],
        ),
      ),
    );
  }
}