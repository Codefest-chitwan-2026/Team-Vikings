import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/ngo_model.dart';
import '../../models/picked_location.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../../widgets/shared/document_upload_tile.dart';
import '../shared/map_address_picker_screen.dart';

class NgoSignUpScreen extends StatefulWidget {
  const NgoSignUpScreen({super.key});

  @override
  State<NgoSignUpScreen> createState() => _NgoSignUpScreenState();
}

class _NgoSignUpScreenState extends State<NgoSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ngoModel = NgoRegistrationModel();
  final _nameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();

  PickedLocation? _selectedLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final currentLocation = _selectedLocation;
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => MapAddressPickerScreen(
          initialLocation: currentLocation == null
              ? null
              : LatLng(currentLocation.latitude, currentLocation.longitude),
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _selectedLocation = result;
      _ngoModel
        ..latitude = result.latitude
        ..longitude = result.longitude;
      _addressController.text = result.address;
    });
  }

  Future<void> _submitForReview() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      _showMessage('Please pin your organization location on the map.');
      return;
    }

    if (_ngoModel.documentName == null) {
      _showMessage('Please add the registration certificate or PAN document.');
      return;
    }

    setState(() => _isLoading = true);
    _saveFormData();

    // Replace this with the registration API call when the backend is connected.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isLoading = false);
    _showMessage('Registration submitted for manual review.');
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;

    setState(() {
      _ngoModel
        ..documentPath = file.path
        ..documentName = file.name;
    });
  }

  void _saveFormData() {
    _ngoModel
      ..organizationName = _nameController.text.trim()
      ..contactName = _contactNameController.text.trim()
      ..phoneNumber = _phoneController.text.trim()
      ..email = _emailController.text.trim()
      ..password = _passwordController.text
      ..addressText = _addressController.text.trim()
      ..panNumber = _panController.text.trim();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String field) {
    return value == null || value.trim().isEmpty ? 'Enter $field' : null;
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

  String? _validatePassword(String? value) {
    return (value?.length ?? 0) >= 8
        ? null
        : 'Password must be at least 8 characters';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.charcoal,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Organization verification',
          style: TextStyle(
            color: AppColors.charcoal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            children: [
              const Text(
                'Tell us about your organization',
                style: TextStyle(
                  color: AppColors.charcoal,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We review this information before your organization can receive donations.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Organization name',
                hintText: 'Aasha Foundation Nepal',
                controller: _nameController,
                validator: (value) => _required(value, 'organization name'),
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
                hintText: 'contact@organization.org',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                hintText: 'At least 8 characters',
                controller: _passwordController,
                isPassword: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Address',
                hintText: 'Street, ward number, district',
                controller: _addressController,
                validator: (value) => _required(value, 'address'),

              ),
              const SizedBox(height: 12),
              _LocationPickerTile(
                location: _selectedLocation,
                onTap: _openMapPicker,
              ),
              const SizedBox(height: 20),
              const Text(
                'Organization type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<NgoOrganizationType>(
                initialValue: _ngoModel.organizationType,
                isExpanded: true,
                decoration: _dropdownDecoration(),
                items: NgoOrganizationType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (type) {
                  if (type != null) setState(() => _ngoModel.organizationType = type);
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Registration / PAN number',
                hintText: 'e.g. 601234567',
                controller: _panController,
                validator: (value) => _required(value, 'PAN or registration number'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add the required documents for manual verification.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              DocumentUploadTile(
                title: 'Verification certificate',
                subtitle: 'SWC or official registration certificate',
                fileName: _ngoModel.documentName,
                isUploaded: _ngoModel.documentName != null,
                onTap: _pickDocument,
              ),

              const SizedBox(height: 4),
              const _VerificationNotice(),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Submit for review',
                isLoading: _isLoading,
                onPressed: _submitForReview,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.8),
      ),
    );
  }

}

class _LocationPickerTile extends StatelessWidget {
  const _LocationPickerTile({required this.location, required this.onTap});

  final PickedLocation? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = location != null;
    return Semantics(
      button: true,
      label: 'Pin location on map',
      child: Material(
        color: AppColors.primaryEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryEmerald.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.primaryEmerald),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSelected ? 'Location pinned' : 'Pin location on map',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryEmerald,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSelected
                            ? location?.address ?? ''
                            : 'Choose the exact location of your organization.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primaryEmerald),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  const _VerificationNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: const Text(
        'A registration certificate or tax clearance or PAN document is required. Reviews are completed manually; approved organizations can then claim donations.',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Color(0xFF8D6E63),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
