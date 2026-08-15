import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool hasError;
  final AutovalidateMode? autovalidateMode;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.errorText,
    this.hasError = false,
    this.autovalidateMode,
    this.onChanged,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final hasCustomError =
        (widget.errorText != null && widget.errorText!.isNotEmpty) ||
            widget.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
          onChanged: widget.onChanged,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            errorText: hasCustomError ? widget.errorText : null,
            errorMaxLines: 2,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: widget.prefixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasCustomError ? AppColors.error : AppColors.border,
                width: hasCustomError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasCustomError ? AppColors.error : AppColors.primary,
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.error, width: 2.0),
            ),
            suffixIcon: widget.suffixIcon ??
                (widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: hasCustomError ? AppColors.error : AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null),
          ),
        ),
      ],
    );
  }
}