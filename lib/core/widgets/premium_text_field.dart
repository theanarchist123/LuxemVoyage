import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumTextField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;

  const PremiumTextField({
    Key? key,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.accentAmber.withOpacity(0.6)),
      ),
    );
  }
}
