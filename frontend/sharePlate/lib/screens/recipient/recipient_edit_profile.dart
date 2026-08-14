import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/picked_location.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../../widgets/shared/profile/edit_avatar_picker.dart';
import '../../widgets/shared/profile/location_picker_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';
import '../shared/map_address_picker_screen.dart';

/// Edit Profile screen for the donor role.
/// TODO: pre-fill the controllers from the signed-in BusinessRegistrationModel
/// / UserModel and submit changes through the profile update API once available.
class DonorEditProfileScreen extends StatefulWidget {
  const DonorEditProfileScreen({super.key});

  @override
  State<DonorEditProfileScreen> createState() => _DonorEditProfileScreenState();
}

class _DonorEditProfileScreenState extends State<DonorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController(text: 'Chitwan Black Forest');
  final _contactNameController = TextEditingController(text: 'Sujan Gurung');
  final _phoneController = TextEditingController(text: '9800000000');
  final _emailController = TextEditingController(text: 'contact@chitwanblackforest.com');
  final _addressController = TextEditingController(text: 'Bharatpur-10, Chitwan');

  PickedLocation? _selectedLocation;
  bool _isSaving = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final selectedLocation = _selectedLocation;
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapAddressPickerScreen(
          initialLocation: selectedLocation == null
              ? null
              : LatLng(selectedLocation.latitude, selectedLocation.longitude),
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedLocation = result;
      _addressController.text = result.address;
    });
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    // Replace this with the profile update API call when available.
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated.')));
    Navigator.of(context).maybePop();
  }

  void _onAvatarTap() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Photo upload coming soon.')));
  }

  String? _required(String? value, String label) {
    return value == null || value.trim().isEmpty ? 'Enter $label' : null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter an email address';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Enter a valid email address';
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 ? null : 'Enter a valid contact number';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const SimpleAppBar(title: 'Edit profile'),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            children: [
              EditAvatarPicker(initials: 'CB', onTap: _onAvatarTap),
              const SizedBox(height: 28),
              CustomTextField(
                label: 'Business name',
                hintText: 'Himalayan Bites Cafe',
                controller: _businessNameController,
                validator: (value) => _required(value, 'business name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact person name',
                hintText: 'Full name',
                controller: _contactNameController,
                validator: (value) => _required(value, 'contact name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact number',
                hintText: '98XXXXXXXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email address',
                hintText: 'contact@business.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Business address',
                hintText: 'Street, ward number, district',
                controller: _addressController,
                validator: (value) => _required(value, 'business address'),
              ),
              const SizedBox(height: 12),
              LocationPickerTile(
                location: _selectedLocation,
                onTap: _openMapPicker,
                selectedLabel: 'Business location pinned',
                unselectedLabel: 'Pin business location on map',
                unselectedSubtitle: 'Choose the exact location where food can be collected.',
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Save changes',
                isLoading: _isSaving,
                onPressed: _saveChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}