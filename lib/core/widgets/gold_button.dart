import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class GoldButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutline;

  const GoldButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isOutline = false,
  }) : super(key: key);

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    setState(() => _scale = 0.96);
  }
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 32),
          decoration: BoxDecoration(
            gradient: widget.isOutline ? null : AppTheme.amberGradient,
            color: widget.isOutline ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(16),
            border: widget.isOutline
                ? Border.all(color: AppTheme.accentAmber.withOpacity(0.5), width: 1.5)
                : null,
            boxShadow: widget.isOutline
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.accentAmber.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18,
                    color: widget.isOutline ? AppTheme.accentAmber : AppTheme.primaryBlack),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: widget.isOutline ? AppTheme.accentAmber : AppTheme.primaryBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
