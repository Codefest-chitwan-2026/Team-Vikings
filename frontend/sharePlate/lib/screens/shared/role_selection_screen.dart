import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../widgets/role_selection/info_banner.dart';
import '../../widgets/role_selection/role_card.dart';
import '../auth/business_signup_screen.dart';
import '../auth/consumer_signup_screen.dart';
import '../auth/ngo_signup_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.donor;

  String get _buttonText {
    switch (_selectedRole) {
      case UserRole.donor:
        return 'Continue as Donor';
      case UserRole.ngo:
        return 'Continue as Verified NGO';
      case UserRole.consumer:
        return 'Continue as Consumer';
    }
  }

  void _onContinue() {
    switch (_selectedRole) {
      case UserRole.ngo:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NgoSignUpScreen()),
        );
        break;
      case UserRole.donor:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BusinessSignUpScreen()),
        );
        break;
      case UserRole.consumer:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConsumerSignUpScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Pick a role — you can add another later from your profile.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Modular Role Cards
              Expanded(
                child: ListView(
                  children: [
                    RoleCard(
                      role: UserRole.donor,
                      title: 'Donor — Food business',
                      subtitle:
                          'Hotels, restaurants, cafés, bakeries & party palaces posting surplus food.',
                      icon: Icons.home_work_outlined,
                      isSelected: _selectedRole == UserRole.donor,
                      onTap: () => setState(() => _selectedRole = UserRole.donor),
                    ),
                    const SizedBox(height: 16),
                    RoleCard(
                      role: UserRole.ngo,
                      title: 'Verified NGO / Shelter',
                      subtitle:
                          'Orphanages, elderly homes and community kitchens with priority claim access.',
                      icon: Icons.location_on_outlined,
                      isSelected: _selectedRole == UserRole.ngo,
                      onTap: () => setState(() => _selectedRole = UserRole.ngo),
                    ),
                    const SizedBox(height: 16),
                    RoleCard(
                      role: UserRole.consumer,
                      title: 'Consumer',
                      subtitle:
                          'Grab quality meals nearby at flash-sale prices before they expire.',
                      icon: Icons.shopping_bag_outlined,
                      isSelected: _selectedRole == UserRole.consumer,
                      onTap: () => setState(() => _selectedRole = UserRole.consumer),
                    ),
                    const SizedBox(height: 24),

                    // Modular Info Banner Widget
                    const InfoBanner(
                      message:
                          'NGO accounts need document verification. Approval usually takes under 24 hours.',
                    ),
                  ],
                ),
              ),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
