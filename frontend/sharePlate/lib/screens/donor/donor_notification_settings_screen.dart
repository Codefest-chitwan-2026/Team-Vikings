import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/shared/profile/settings_switch_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';


/// Notification Settings screen for the donor role.
/// TODO: load the initial toggle values from the signed-in donor's saved
/// preferences and persist changes through the settings-update API.
class DonorNotificationSettingsScreen extends StatefulWidget {
  const DonorNotificationSettingsScreen({super.key});

  @override
  State<DonorNotificationSettingsScreen> createState() =>
      _DonorNotificationSettingsScreenState();
}

class _DonorNotificationSettingsScreenState
    extends State<DonorNotificationSettingsScreen> {
  bool _claimConfirmations = true;
  bool _listingExpiry = true;
  bool _nearbyDeals = false;
  bool _pickupUpdates = true;
  bool _weeklySummary = true;
  bool _pushEnabled = true;
  bool _emailEnabled = false;

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
              title: 'Claim confirmations',
              subtitle: 'When an NGO or customer claims one of your listings.',
              value: _claimConfirmations,
              onChanged: (value) => setState(() => _claimConfirmations = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Listing expiry alerts',
              subtitle: 'When one of your active listings is about to close.',
              value: _listingExpiry,
              onChanged: (value) => setState(() => _listingExpiry = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Nearby deals',
              subtitle: 'Flash-sale listings posted near your business.',
              value: _nearbyDeals,
              onChanged: (value) => setState(() => _nearbyDeals = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Pickup updates',
              subtitle: 'When a donation is picked up or marked completed.',
              value: _pickupUpdates,
              onChanged: (value) => setState(() => _pickupUpdates = value),
            ),
            const Divider(height: 1, color: AppColors.border),
            SettingsSwitchTile(
              title: 'Weekly impact summary',
              subtitle: 'A weekly recap of the food you helped save.',
              value: _weeklySummary,
              onChanged: (value) => setState(() => _weeklySummary = value),
            ),
          ],
        ),
      ),
    );
  }
}