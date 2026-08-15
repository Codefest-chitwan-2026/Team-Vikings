import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../consumer/consumer_home_screen.dart';
import '../shared/login_screen.dart';

class ConsumerSignUpScreen extends StatefulWidget {
  const ConsumerSignUpScreen({super.key});

  @override
  State<ConsumerSignUpScreen> createState() => _ConsumerSignUpScreenState();
}

class _ConsumerSignUpScreenState extends State<ConsumerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.registerCustomer(
      phoneNum: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      address: _addressController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ConsumerHomeScreen()),
            (route) => false,
          );
        }
      });
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
        } else if (errLower.contains('name')) {
          _nameError = error;
        } else {
          _generalError = error;
        }
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your full name';
    if (value.trim().length < 2) return 'Invalid name (too short)';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your phone number';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return 'Invalid phone number (min 7 digits)';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter an email address';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Invalid email address (e.g. you@example.com)';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 8) return 'Invalid password (must be at least 8 characters)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((a) => a.isLoading);

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
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
        ),
        title: const Text(
          'Create consumer account',
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
              const SizedBox(height: 12),
              const Text(
                'Join SharePlate',
                style: TextStyle(
                  color: AppColors.charcoal,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create an account to find quality meals nearby.',
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
              const SizedBox(height: 28),
              CustomTextField(
                label: 'Full name',
                hintText: 'e.g. Rojina Shrestha',
                controller: _fullNameController,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null || _generalError != null) {
                    setState(() {
                      _nameError = null;
                      _generalError = null;
                    });
                  }
                },
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone number',
                hintText: '98XXXXXXXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                errorText: _phoneError,
                onChanged: (_) {
                  if (_phoneError != null || _generalError != null) {
                    setState(() {
                      _phoneError = null;
                      _generalError = null;
                    });
                  }
                },
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email address',
                hintText: 'you@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null || _generalError != null) {
                    setState(() {
                      _emailError = null;
                      _generalError = null;
                    });
                  }
                },
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Address',
                hintText: 'City, area (e.g. Kathmandu)',
                controller: _addressController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                hintText: 'At least 8 characters',
                controller: _passwordController,
                isPassword: true,
                errorText: _passwordError,
                onChanged: (_) {
                  if (_passwordError != null || _generalError != null) {
                    setState(() {
                      _passwordError = null;
                      _generalError = null;
                    });
                  }
                },
                validator: _validatePassword,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Create account',
                isLoading: isLoading,
                onPressed: _createAccount,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryEmerald,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
