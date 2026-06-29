import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String label; // Label tombol
  final VoidCallback onPressed; // Aksi ketika tombol ditekan
  final Color backgroundColor; // Warna latar tombol
  final Color textColor; // Warna teks tombol

  const CustomButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppTheme.gold,
    this.textColor = AppTheme.background,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        gradient: LinearGradient(
          colors: [backgroundColor, backgroundColor.withOpacity(0.85)],
        ),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 32.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}