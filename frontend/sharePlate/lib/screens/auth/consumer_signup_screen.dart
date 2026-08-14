import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../../widgets/shared/custom_text_field.dart';

class ConsumerSignUpScreen extends StatefulWidget {
  const ConsumerSignUpScreen({super.key});

  @override
  State<ConsumerSignUpScreen> createState() => _ConsumerSignUpScreenState();
}

class _ConsumerSignUpScreenState extends State<ConsumerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    // Replace this with the consumer signup API call when available.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consumer account created successfully.')),
    );
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 ? null : 'Enter a valid phone number';
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter an email address';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Enter a valid email address';
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
              const SizedBox(height: 32),
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
                hintText: 'you@example.com',
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
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Create account',
                isLoading: _isLoading,
                onPressed: _createAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
