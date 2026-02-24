import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
        child: CircleNavBar(
          activeIcons: const [
            Icon(LucideIcons.home, color: AppTheme.primaryBlack),
            Icon(LucideIcons.map, color: AppTheme.primaryBlack),
            Icon(LucideIcons.bookOpen, color: AppTheme.primaryBlack),
            Icon(LucideIcons.image, color: AppTheme.primaryBlack),
            Icon(LucideIcons.user, color: AppTheme.primaryBlack),
          ],
          inactiveIcons: [
            Icon(LucideIcons.home, color: AppTheme.textSecondary.withOpacity(0.6)),
            Icon(LucideIcons.map, color: AppTheme.textSecondary.withOpacity(0.6)),
            Icon(LucideIcons.bookOpen, color: AppTheme.textSecondary.withOpacity(0.6)),
            Icon(LucideIcons.image, color: AppTheme.textSecondary.withOpacity(0.6)),
            Icon(LucideIcons.user, color: AppTheme.textSecondary.withOpacity(0.6)),
          ],
          color: AppTheme.surfaceDark,
          circleColor: AppTheme.accentAmber,
          height: 60,
          circleWidth: 60,
          activeIndex: currentIndex,
          onTap: (index) {
            HapticFeedback.lightImpact();
            onTap(index);
          },
          shadowColor: Colors.black.withOpacity(0.3),
          elevation: 8,
        ),
      ),
    );
  }
}
