import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/picked_location.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../../widgets/shared/profile/edit_avatar_picker.dart';
import '../../widgets/shared/profile/location_picker_tile.dart';
import '../../widgets/shared/profile/simple_app_bar.dart';
import '../shared/map_address_picker_screen.dart';

/// Edit Profile screen for the consumer (customer) role.
class ConsumerEditProfileScreen extends StatefulWidget {
  const ConsumerEditProfileScreen({super.key});

  @override
  State<ConsumerEditProfileScreen> createState() =>
      _ConsumerEditProfileScreenState();
}

class _ConsumerEditProfileScreenState extends State<ConsumerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  PickedLocation? _selectedLocation;
  String? _avatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    final name = user?.name.isNotEmpty == true
        ? user!.name
        : (user?.displayName.isNotEmpty == true ? user!.displayName : 'Rojina Shrestha');
    final phone = user?.phone.isNotEmpty == true ? user!.phone : '9840000000';
    final email = user?.email.isNotEmpty == true ? user!.email : 'rojina.shrestha@email.com';
    final address = user?.address ?? 'Bharatpur-6, Chitwan';
    _avatarPath = user?.profileData?['avatar_path'] as String?;

    _nameController = TextEditingController(text: name);
    _phoneController = TextEditingController(text: phone);
    _emailController = TextEditingController(text: email);
    _addressController = TextEditingController(text: address);
  }

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

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.single.path;
        if (path != null && path.isNotEmpty) {
          setState(() => _avatarPath = path);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.updateUserProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      additionalProfileData: {
        if (_avatarPath != null) 'avatar_path': _avatarPath,
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).maybePop();
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
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final initials = user?.initials ?? 'RS';

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
              EditAvatarPicker(
                initials: initials,
                imagePath: _avatarPath,
                onTap: _pickAvatar,
              ),
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