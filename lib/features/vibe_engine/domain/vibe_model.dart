import 'dart:ui';

/// Defines the types of particle effects that can be active in the background.
enum ParticleEffectType {
  none,
  snow,
  confetti,
  flowerPetals,
  colorDust,
  stars;

  static ParticleEffectType fromString(String effect) {
    switch (effect) {
      case 'snow': return ParticleEffectType.snow;
      case 'confetti': return ParticleEffectType.confetti;
      case 'flower_petals': return ParticleEffectType.flowerPetals;
      case 'color_dust': return ParticleEffectType.colorDust;
      case 'stars': return ParticleEffectType.stars;
      default: return ParticleEffectType.none;
    }
  }
}

/// Represents the active 'Vibe' (theme/festival/occasion) pushed from the Vibe Engine API or local config.
class VibePayload {
  final bool isVibeActive;
  final String eventName;
  final String greetingText;
  
  // Custom colors for this vibe
  final Color? primaryColor;
  final Color? accentColor;
  final Color? backgroundColor;

  final ParticleEffectType particleEffect;
  final String iconPackOverride;

  const VibePayload({
    this.isVibeActive = false,
    this.eventName = '',
    this.greetingText = '',
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
    this.particleEffect = ParticleEffectType.none,
    this.iconPackOverride = 'default',
  });

  /// Factory to parse from API JSON
  factory VibePayload.fromJson(Map<String, dynamic> json) {
    return VibePayload(
      isVibeActive: json['vibe_active'] ?? false,
      eventName: json['event_name'] ?? '',
      greetingText: json['greeting_text'] ?? '',
      primaryColor: _hexToColor(json['colors']?['primary']),
      accentColor: _hexToColor(json['colors']?['accent']),
      backgroundColor: _hexToColor(json['colors']?['bg']),
      particleEffect: ParticleEffectType.fromString(json['particle_effect'] ?? 'none'),
      iconPackOverride: json['icon_pack_override'] ?? 'default',
    );
  }

  static Color? _hexToColor(String? hexString) {
    if (hexString == null) return null;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// The standard, default empty vibe
  static const standard = VibePayload();

  // Test Vibes
  static VibePayload get testHoli => const VibePayload(
    isVibeActive: true,
    eventName: 'Holi Festival of Colors',
    greetingText: 'Happy Holi! 🎨',
    primaryColor: Color(0xFFFF1493), // Deep Pink
    accentColor: Color(0xFF00FFFF),  // Cyan
    backgroundColor: Color(0xFFFAFAFA),
    particleEffect: ParticleEffectType.colorDust,
    iconPackOverride: 'holi_pack',
  );

  static VibePayload get testHalloween => const VibePayload(
    isVibeActive: true,
    eventName: 'Halloween Spooktacular',
    greetingText: 'Trick or Treat! 🎃',
    primaryColor: Color(0xFFFF7518), // Pumpkin Orange
    accentColor: Color(0xFF8B008B),  // Dark Magenta
    backgroundColor: Color(0xFF0D0D0D), // Very Dark Grey
    particleEffect: ParticleEffectType.stars,
    iconPackOverride: 'halloween_pack',
  );
}
