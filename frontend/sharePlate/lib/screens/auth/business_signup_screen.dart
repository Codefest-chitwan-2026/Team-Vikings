import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/business_registration_model.dart';
import '../../models/picked_location.dart';
import '../../widgets/business_signup/business_document_section.dart';
import '../../widgets/business_signup/business_location_picker_tile.dart';
import '../../widgets/business_signup/business_verification_notice.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../shared/map_address_picker_screen.dart';

class BusinessSignUpScreen extends StatefulWidget {
  const BusinessSignUpScreen({super.key});

  @override
  State<BusinessSignUpScreen> createState() => _BusinessSignUpScreenState();
}

class _BusinessSignUpScreenState extends State<BusinessSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessModel = BusinessRegistrationModel();
  final _businessNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  PickedLocation? _selectedLocation;
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _registrationNumberController.dispose();
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
      _businessModel
        ..latitude = result.latitude
        ..longitude = result.longitude;
      _addressController.text = result.address;
    });
  }

  Future<void> _submitForReview() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      _showMessage('Please pin your business location on the map.');
      return;
    }
    if (_businessModel.verificationDocumentPath == null) {
      _showMessage('Please add a verification document for your business.');
      return;
    }

    setState(() => _isLoading = true);
    _saveFormData();

    // Replace this with the business registration API call when available.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isLoading = false);
    _showMessage('Business registration submitted for review.');
  }

  void _saveFormData() {
    _businessModel
      ..businessName = _businessNameController.text.trim()
      ..contactName = _contactNameController.text.trim()
      ..phoneNumber = _phoneController.text.trim()
      ..email = _emailController.text.trim()
      ..password = _passwordController.text
      ..addressText = _addressController.text.trim()
      ..registrationOrPanNumber = _registrationNumberController.text.trim();
  }

  Future<void> _pickVerificationDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (!mounted || result == null) return;

    final fileName = result.files.single.name;
    if (fileName.isEmpty) {
      _showMessage('The selected file does not have a valid name.');
      return;
    }

    setState(() => _businessModel.verificationDocumentPath = fileName);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          'Business verification',
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
                'Tell us about your business',
                style: TextStyle(
                  color: AppColors.charcoal,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We review this information before you can post surplus food.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Business name',
                hintText: 'Himalayan Bites Cafe',
                controller: _businessNameController,
                validator: (value) => _required(value, 'business name'),
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
                label: 'Password',
                hintText: 'At least 8 characters',
                controller: _passwordController,
                isPassword: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Business address',
                hintText: 'Street, ward number, district',
                controller: _addressController,
                validator: (value) => _required(value, 'business address'),
              ),
              const SizedBox(height: 12),
              BusinessLocationPickerTile(
                location: _selectedLocation,
                onTap: _openMapPicker,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Business registration / PAN number',
                hintText: 'e.g. 601234567',
                controller: _registrationNumberController,
                validator: (value) =>
                    _required(value, 'business registration or PAN number'),
              ),
              const SizedBox(height: 24),
              BusinessDocumentSection(
                verificationDocumentPath: _businessModel.verificationDocumentPath,
                onVerificationDocumentTap: _pickVerificationDocument,
              ),
              const SizedBox(height: 4),
              const BusinessVerificationNotice(),
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
}
