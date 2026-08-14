import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shareplate/screens/shared/role_selection_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared/custom_text_field.dart';
import '../../widgets/login_screen/primary_button.dart';
import '../consumer/consumer_home_screen.dart';
import '../donor/donor_home_screen.dart';
import '../recipient/recipient_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole? role;

  const LoginScreen({
    super.key,
    this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  String? _phoneError;
  String? _passwordError;
  String? _formGeneralError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Pre-fill remembered phone if enabled
      if (authProvider.currentUser != null && authProvider.currentUser!.phone.isNotEmpty) {
        _phoneController.text = authProvider.currentUser!.phone;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _phoneError = null;
      _passwordError = null;
      _formGeneralError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneNum = _phoneController.text.trim();
    final password = _passwordController.text;

    final success = await authProvider.login(
      phoneNum: phoneNum,
      password: password,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.currentUser;
      final userRole = user?.role ?? widget.role ?? UserRole.consumer;

      Widget targetScreen;
      switch (userRole) {
        case UserRole.donor:
          targetScreen = const DonorHomeScreen();
          break;
        case UserRole.ngo:
          targetScreen = const RecipientHomeScreen();
          break;
        case UserRole.consumer:
          targetScreen = const ConsumerHomeScreen();
          break;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } else {
      final error = authProvider.errorMessage ?? 'Invalid phone number or password.';
      setState(() {
        if (error.toLowerCase().contains('phone') || error.toLowerCase().contains('user') || error.toLowerCase().contains('account')) {
          _phoneError = error;
        } else if (error.toLowerCase().contains('password')) {
          _passwordError = error;
        } else {
          _phoneError = 'Please check your phone number';
          _passwordError = 'Invalid credentials or wrong password';
          _formGeneralError = error;
        }
      });
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    );
  }

  void _onForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset feature is under development. Please contact support.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // Title
                const Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log in to rescue surplus meals or manage donations.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                if (_formGeneralError != null) ...[
                  const SizedBox(height: 20),
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
                            _formGeneralError!,
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

                const SizedBox(height: 32),

                // Phone Field
                CustomTextField(
                  label: 'Phone number',
                  hintText: 'Enter your phone number (e.g. 98XXXXXXXX)',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  errorText: _phoneError,
                  onChanged: (_) {
                    if (_phoneError != null || _formGeneralError != null) {
                      setState(() {
                        _phoneError = null;
                        _formGeneralError = null;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().replaceAll(RegExp(r'\D'), '').length < 7) {
                      return 'Please enter a valid phone number (min 7 digits)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password Field
                CustomTextField(
                  label: 'Password',
                  hintText: 'Enter your password',
                  controller: _passwordController,
                  isPassword: true,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null || _formGeneralError != null) {
                      setState(() {
                        _passwordError = null;
                        _formGeneralError = null;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _onForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Login Action Button
                PrimaryButton(
                  text: 'Login',
                  isLoading: authProvider.isLoading,
                  onPressed: _onLogin,
                ),

                const SizedBox(height: 20),

                // Sign-up Redirect Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToSignUp,
                      child: const Text(
                        'Sign-up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
