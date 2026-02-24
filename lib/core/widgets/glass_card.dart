import 'package:blur/blur.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Blur(
        blur: 10,
        blurColor: AppTheme.primaryBlack,
        colorOpacity: 0.2,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(padding: padding, child: child),
      ),
    );
  }
}
