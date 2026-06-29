import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: AppTheme.formInputDecoration(label: label),
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
      ),
    );
  }
}