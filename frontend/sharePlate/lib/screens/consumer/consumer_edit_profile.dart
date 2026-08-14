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

/// Edit Profile screen for the consumer (customer) role.
/// TODO: pre-fill the controllers from the signed-in UserModel and submit
/// changes through the profile update API once available.
class ConsumerEditProfileScreen extends StatefulWidget {
  const ConsumerEditProfileScreen({super.key});

  @override
  State<ConsumerEditProfileScreen> createState() =>
      _ConsumerEditProfileScreenState();
}

class _ConsumerEditProfileScreenState extends State<ConsumerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Rojina Shrestha');
  final _phoneController = TextEditingController(text: '9840000000');
  final _emailController = TextEditingController(text: 'rojina.shrestha@email.com');
  final _addressController = TextEditingController(text: 'Bharatpur-6, Chitwan');

  PickedLocation? _selectedLocation;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
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
    return digits.length >= 7 ? null : 'Enter a valid phone number';
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
              EditAvatarPicker(initials: 'RS', onTap: _onAvatarTap),
              const SizedBox(height: 28),
              CustomTextField(
                label: 'Full name',
                hintText: 'Your full name',
                controller: _nameController,
                validator: (value) => _required(value, 'your name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone number',
                hintText: '98XXXXXXXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email address',
                hintText: 'you@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Home address',
                hintText: 'Street, ward number, district',
                controller: _addressController,
                validator: (value) => _required(value, 'your address'),
              ),
              const SizedBox(height: 12),
              LocationPickerTile(
                location: _selectedLocation,
                onTap: _openMapPicker,
                selectedLabel: 'Home location pinned',
                unselectedLabel: 'Pin home location on map',
                unselectedSubtitle: 'Choose the location you usually pick up orders from.',
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