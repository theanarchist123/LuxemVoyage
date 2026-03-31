import 'package:flutter/material.dart';
import '../../../../core/theme/vibe_theme_extension.dart';

/// A smart icon wrapper that overrides standard Material Icons with 
/// Vibe-specific variants when a festival is active.
class VibeIcon extends StatelessWidget {
  final IconData defaultIcon;
  final double? size;
  final Color? color;

  const VibeIcon(
    this.defaultIcon, {
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final vibe = Theme.of(context).extension<VibeThemeExtension>();

    // If no vibe is active, or standard icon pack, return normal icon.
    if (vibe == null || !vibe.isVibeActive || vibe.iconPackOverride == 'default') {
      return Icon(defaultIcon, size: size, color: color);
    }

    // ── FESTIVAL ICON OVERRIDES ──
    // Example: Overriding specific icons based on the festival.
    // In a real app, this would return an `SvgPicture.asset()` from the active pack.

    if (vibe.iconPackOverride == 'holi_pack') {
      if (defaultIcon == Icons.favorite || defaultIcon == Icons.favorite_border) {
        return Text('🎨', style: TextStyle(fontSize: size ?? 24)); // Holi Water Balloon / Colors
      }
      if (defaultIcon == Icons.home) {
        return Text('🎪', style: TextStyle(fontSize: size ?? 24)); // Tent / Celebration Home
      }
    }

    if (vibe.iconPackOverride == 'halloween_pack') {
      if (defaultIcon == Icons.favorite || defaultIcon == Icons.favorite_border) {
        return Text('🎃', style: TextStyle(fontSize: size ?? 24)); // Pumpkin Heart
      }
    }

    // Fallback if the specific icon isn't covered by the pack
    return Icon(defaultIcon, size: size, color: color);
  }
}
