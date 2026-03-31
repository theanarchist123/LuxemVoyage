import 'package:flutter/material.dart';
import '../../features/vibe_engine/domain/vibe_model.dart';

class VibeThemeExtension extends ThemeExtension<VibeThemeExtension> {
  final bool isVibeActive;
  final String eventName;
  final ParticleEffectType particleEffect;
  final String iconPackOverride;
  final List<Color> customGradientColors;

  const VibeThemeExtension({
    required this.isVibeActive,
    required this.eventName,
    required this.particleEffect,
    required this.iconPackOverride,
    required this.customGradientColors,
  });

  /// Factory to easily convert a `VibePayload` into this Theme Extension
  factory VibeThemeExtension.fromPayload(VibePayload payload, {List<Color>? fallbackGradients}) {
    List<Color> gradient = fallbackGradients ?? [
      const Color(0xFF14B8A6), 
      const Color(0xFF8B5CF6), 
      const Color(0xFFF59E0B)
    ];

    if (payload.isVibeActive) {
      gradient = [
        payload.primaryColor ?? const Color(0xFF14B8A6),
        payload.accentColor ?? const Color(0xFF8B5CF6),
      ];
    }

    return VibeThemeExtension(
      isVibeActive: payload.isVibeActive,
      eventName: payload.eventName,
      particleEffect: payload.particleEffect,
      iconPackOverride: payload.iconPackOverride,
      customGradientColors: gradient,
    );
  }

  // The standard clear state (no vibe active)
  static VibeThemeExtension get empty => const VibeThemeExtension(
    isVibeActive: false,
    eventName: '',
    particleEffect: ParticleEffectType.none,
    iconPackOverride: 'default',
    customGradientColors: [
      Color(0xFF14B8A6), 
      Color(0xFF8B5CF6), 
      Color(0xFFF59E0B)
    ],
  );

  @override
  ThemeExtension<VibeThemeExtension> copyWith({
    bool? isVibeActive,
    String? eventName,
    ParticleEffectType? particleEffect,
    String? iconPackOverride,
    List<Color>? customGradientColors,
  }) {
    return VibeThemeExtension(
      isVibeActive: isVibeActive ?? this.isVibeActive,
      eventName: eventName ?? this.eventName,
      particleEffect: particleEffect ?? this.particleEffect,
      iconPackOverride: iconPackOverride ?? this.iconPackOverride,
      customGradientColors: customGradientColors ?? this.customGradientColors,
    );
  }

  @override
  ThemeExtension<VibeThemeExtension> lerp(covariant ThemeExtension<VibeThemeExtension>? other, double t) {
    if (other is! VibeThemeExtension) return this;

    // We can lerp complex values to animate between themes smoothly.
    List<Color> lerpedGradients = [];
    int maxLen = customGradientColors.length > other.customGradientColors.length 
        ? customGradientColors.length 
        : other.customGradientColors.length;

    for (int i = 0; i < maxLen; i++) {
      Color c1 = i < customGradientColors.length ? customGradientColors[i] : customGradientColors.last;
      Color c2 = i < other.customGradientColors.length ? other.customGradientColors[i] : other.customGradientColors.last;
      lerpedGradients.add(Color.lerp(c1, c2, t) ?? c1);
    }

    return VibeThemeExtension(
      // Booleans and enums switch exactly at 0.5 (halfway point of animation)
      isVibeActive: t < 0.5 ? isVibeActive : other.isVibeActive,
      eventName: t < 0.5 ? eventName : other.eventName,
      particleEffect: t < 0.5 ? particleEffect : other.particleEffect,
      iconPackOverride: t < 0.5 ? iconPackOverride : other.iconPackOverride,
      customGradientColors: lerpedGradients,
    );
  }
}
