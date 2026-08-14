import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/business_registration_model.dart';
import '../../models/picked_location.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/business_signup/business_document_section.dart';
import '../../widgets/business_signup/business_location_picker_tile.dart';
import '../../widgets/business_signup/business_verification_notice.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../donor/donor_home_screen.dart';
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
  String? _documentDisplayName;

  String? _businessNameError;
  String? _contactNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _addressError;
  String? _panError;
  String? _locationError;
  String? _documentError;
  String? _generalError;

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
      _locationError = null;
      _businessModel
        ..latitude = result.latitude
        ..longitude = result.longitude;
      _addressController.text = result.address;
    });
  }

  Future<void> _submitForReview() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _businessNameError = null;
      _contactNameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _addressError = null;
      _panError = null;
      _locationError = null;
      _documentError = null;
      _generalError = null;
    });

    final isValid = _formKey.currentState!.validate();
    bool hasMissingCustom = false;

    if (_selectedLocation == null) {
      setState(() => _locationError = 'Please pin your business location on the map.');
      hasMissingCustom = true;
    }
    if (_businessModel.verificationDocumentPath == null) {
      setState(() => _documentError = 'Please add a verification document for your business.');
      hasMissingCustom = true;
    }

    if (!isValid || hasMissingCustom) return;

    _saveFormData();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.registerBusiness(
      model: _businessModel,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DonorHomeScreen()),
        (route) => false,
      );
    } else {
      final error = authProvider.errorMessage ?? 'Registration failed. Please check your details.';
      setState(() {
        final errLower = error.toLowerCase();
        if (errLower.contains('phone')) {
          _phoneError = error;
        } else if (errLower.contains('email')) {
          _emailError = error;
        } else if (errLower.contains('password')) {
          _passwordError = error;
        } else if (errLower.contains('pan') || errLower.contains('registration')) {
          _panError = error;
        } else if (errLower.contains('name')) {
          _businessNameError = error;
        } else {
          _generalError = error;
        }
      });
    }
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

    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.name.isEmpty) {
      setState(() => _documentError = 'The selected file does not have a valid name.');
      return;
    }

    setState(() {
      _businessModel.verificationDocumentPath = file.path;
      _documentDisplayName = file.name;
      _documentError = null;
    });
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
    final authProvider = context.watch<AuthProvider>();

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
              if (_generalError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              CustomTextField(
                label: 'Business name',
                hintText: 'Himalayan Bites Cafe',
                controller: _businessNameController,
                errorText: _businessNameError,
                onChanged: (_) {
                  if (_businessNameError != null) setState(() => _businessNameError = null);
                },
                validator: (value) => _required(value, 'business name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact person name',
                hintText: 'Full name',
                controller: _contactNameController,
                errorText: _contactNameError,
                onChanged: (_) {
                  if (_contactNameError != null) setState(() => _contactNameError = null);
                },
                validator: (value) => _required(value, 'contact person name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact number',
                hintText: '98XXXXXXXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                errorText: _phoneError,
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email address',
                hintText: 'contact@business.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                hintText: 'At least 8 characters',
                controller: _passwordController,
                isPassword: true,
                errorText: _passwordError,
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Business address',
                hintText: 'Street, ward number, district',
                controller: _addressController,
                errorText: _addressError,
                onChanged: (_) {
                  if (_addressError != null) setState(() => _addressError = null);
                },
                validator: (value) => _required(value, 'business address'),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: _locationError != null ? Border.all(color: AppColors.error, width: 1.5) : null,
                    ),
                    child: BusinessLocationPickerTile(
                      location: _selectedLocation,
                      onTap: _openMapPicker,
                    ),
                  ),
                  if (_locationError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _locationError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Business registration / PAN number',
                hintText: 'e.g. 601234567',
                controller: _registrationNumberController,
                errorText: _panError,
                onChanged: (_) {
                  if (_panError != null) setState(() => _panError = null);
                },
                validator: (value) =>
                    _required(value, 'business registration or PAN number'),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: _documentError != null ? Border.all(color: AppColors.error, width: 1.5) : null,
                    ),
                    child: BusinessDocumentSection(
                      verificationDocumentPath: _documentDisplayName ?? _businessModel.verificationDocumentPath,
                      onVerificationDocumentTap: _pickVerificationDocument,
                    ),
                  ),
                  if (_documentError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _documentError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              const BusinessVerificationNotice(),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Submit for review',
                isLoading: authProvider.isLoading,
                onPressed: _submitForReview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
